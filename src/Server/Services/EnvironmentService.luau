--!strict

-- Ambiente del mundo (D-044): el servidor avanza la hora del día
-- (Lighting.ClockTime, que replica a todos) y prepara el agua y las nubes.
-- La iluminación por hora y las luces de la ciudad las pone cada cliente
-- (EnvironmentController), así no hay tráfico de red por ellas.
--
-- Agua: el generador del mapa deja piezas provisionales con la etiqueta
-- Water (se ven en Studio); al arrancar se cambian por agua de Terrain.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DayCycle = require(ReplicatedStorage.Shared.Modules.DayCycle)
local EnvironmentConfig = require(ReplicatedStorage.Shared.Config.EnvironmentConfig)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local log = Logger.new("EnvironmentService")

local function setupTerrain(): ()
	local terrain = Workspace.Terrain
	terrain.WaterColor = EnvironmentConfig.WaterColor
	terrain.WaterTransparency = EnvironmentConfig.WaterTransparency
	terrain.WaterReflectance = EnvironmentConfig.WaterReflectance
	terrain.WaterWaveSize = EnvironmentConfig.WaterWaveSize
	terrain.WaterWaveSpeed = EnvironmentConfig.WaterWaveSpeed

	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = EnvironmentConfig.CloudCover
	clouds.Density = EnvironmentConfig.CloudDensity
	clouds.Parent = terrain
end

local function convertWater(): ()
	local terrain = Workspace.Terrain
	local count = 0
	for _, instance in CollectionService:GetTagged(WorldTags.Water) do
		if instance:IsA("BasePart") then
			terrain:FillBlock(instance.CFrame, instance.Size, Enum.Material.Water)
			instance:Destroy()
			count += 1
		end
	end
	if count > 0 then
		log:Debug("%d piezas de agua convertidas en agua de Terrain", count)
	end
end

local EnvironmentService = {
	Name = "EnvironmentService",
}

function EnvironmentService:Start(): ()
	if Workspace:FindFirstChild("Baseplate") ~= nil then
		log:Warn("Workspace tiene un Baseplate antiguo que tapa el mapa: bórralo en Studio")
	end
	setupTerrain()
	convertWater()

	Lighting.ClockTime = EnvironmentConfig.StartHour
	task.spawn(function()
		while true do
			local elapsed = task.wait(EnvironmentConfig.ServerTickSeconds)
			Lighting.ClockTime = DayCycle.Advance(Lighting.ClockTime, elapsed, EnvironmentConfig)
		end
	end)
end

return EnvironmentService
