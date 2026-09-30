--!strict

-- Regeneración pasiva de recursos y recuperación de postura (§17
-- ResourceService). Cada recurso usa su RegenPerSecond y su
-- RegenDelaySeconds (tras gastarlo, espera antes de regenerarse). Los
-- recursos con AmbientScaling se regeneran según la densidad de la zona en
-- la que está el personaje (D-041); la zona se replica para la UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local AmbientZones = require(script.Parent.Parent.Content.AmbientZones)
local AmbientDensity = require(script.Parent.Parent.Modules.AmbientDensity)

type CombatEntity = CombatRegistry.CombatEntity

-- Densidad donde está el personaje. Actualiza la zona replicada (el nombre
-- visible, o "" fuera de toda zona) solo si ha cambiado.
local function updateAmbient(entity: CombatEntity): number
	local density, zone = AmbientDensity.At(entity.RootPart.Position, AmbientZones.Zones, AmbientZones.DefaultDensity)
	local zoneName = if zone ~= nil then zone.DisplayName else ""
	if entity.Model:GetAttribute(ReplicatedAttributes.AMBIENT_ZONE) ~= zoneName then
		-- La densidad primero: quien escucha el cambio de zona ya la encuentra.
		entity.Model:SetAttribute(ReplicatedAttributes.AMBIENT_DENSITY, density)
		entity.Model:SetAttribute(ReplicatedAttributes.AMBIENT_ZONE, zoneName)
	end
	return density
end

local function regenerate(entity: CombatEntity, deltaSeconds: number, now: number): ()
	local character = entity.Character
	local density = if entity.Player ~= nil then updateAmbient(entity) else AmbientZones.DefaultDensity
	for _, resourceId in character:GetResourceIds() do
		local definition = Resources[resourceId]
		if definition ~= nil and definition.RegenPerSecond > 0 then
			local lastSpent = entity.LastSpent[resourceId]
			local delay = definition.RegenDelaySeconds or 0
			if lastSpent == nil or now - lastSpent >= delay then
				local scale = if definition.AmbientScaling then density else 1
				character:RestoreResource(resourceId, definition.RegenPerSecond * scale * deltaSeconds)
			end
		end
	end

	local state = character:GetState()
	if state ~= "Blocking" and state ~= "Parrying" and state ~= "Stunned" then
		character:RecoverPosture(CombatConfig.PostureDecayPerSecond * deltaSeconds)
	end
end

local ResourceService = {
	Name = "ResourceService",
}

function ResourceService:Start(): ()
	task.spawn(function()
		while true do
			local deltaSeconds = task.wait(CombatConfig.RegenTickSeconds)
			local now = os.clock()
			for _, entity in CombatRegistry.GetAll() do
				if entity.Character:IsAlive() then
					regenerate(entity, deltaSeconds, now)
				end
			end
		end
	end)
end

-- Anota un gasto para el retardo de regeneración (lo llama CombatService al
-- ver bajar un recurso).
function ResourceService:NoteSpent(entity: CombatEntity, resourceId: string): ()
	entity.LastSpent[resourceId] = os.clock()
end

return ResourceService
