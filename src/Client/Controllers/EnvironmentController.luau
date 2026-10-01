--!strict

-- Ambiente en el cliente (D-044). Con la hora que replica el servidor
-- (Lighting.ClockTime):
--   · interpola la iluminación entre los preajustes de EnvironmentConfig;
--   · de noche enciende la ciudad: ventanas con Lit, farolas, letreros y luces;
--   · anima semáforos, relojes, la luz que parpadea en las ruinas y las
--     balizas rojas de las azoteas.
-- Todo son cambios locales sobre piezas etiquetadas por el generador del mapa
-- (WorldTags). Con StreamingEnabled las piezas llegan y se van: las nuevas se
-- ponen al día al llegar.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DayCycle = require(ReplicatedStorage.Shared.Modules.DayCycle)
local EnvironmentConfig = require(ReplicatedStorage.Shared.Config.EnvironmentConfig)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)

local LIGHTING_STEP_SECONDS = 0.2
local ANIMATION_STEP_SECONDS = 0.1
-- Ciclo de los semáforos: verde, ámbar y rojo (el otro eje, desfasado).
local SIGNAL_GREEN_SECONDS = 9
local SIGNAL_YELLOW_SECONDS = 2
local SIGNAL_CYCLE_SECONDS = 2 * (SIGNAL_GREEN_SECONDS + SIGNAL_YELLOW_SECONDS)

local SIGNAL_COLORS: { [string]: Color3 } = {
	Green = Color3.fromRGB(80, 255, 170),
	Yellow = Color3.fromRGB(255, 190, 60),
	Red = Color3.fromRGB(255, 60, 50),
}
local SIGNAL_OFF = Color3.fromRGB(40, 40, 40)
local WINDOW_NIGHT_COLORS = {
	Color3.fromRGB(255, 217, 160),
	Color3.fromRGB(255, 230, 191),
	Color3.fromRGB(234, 241, 255),
	Color3.fromRGB(255, 207, 138),
}
local WINDOW_DARK = Color3.fromRGB(26, 32, 44)

type Appearance = { Material: Enum.Material, Color: Color3 }

-- Aspecto de día de cada pieza que se cambia de noche (se guarda al verla).
local dayLook: { [BasePart]: Appearance } = setmetatable({}, { __mode = "k" }) :: any
local lightsOn: boolean? = nil

local effects: {
	Atmosphere: Atmosphere,
	Bloom: BloomEffect,
	ColorCorrection: ColorCorrectionEffect,
}

local function ensureEffect<T>(className: string, name: string): T
	local existing = Lighting:FindFirstChild(name)
	if existing ~= nil and existing.ClassName == className then
		return existing :: any
	end
	local created = Instance.new(className :: any)
	created.Name = name
	created.Parent = Lighting
	return created :: any
end

local function applyLighting(hour: number): ()
	local preset = DayCycle.Blend(EnvironmentConfig.Presets :: any, hour)
	Lighting.Ambient = preset.Ambient
	Lighting.OutdoorAmbient = preset.OutdoorAmbient
	Lighting.Brightness = preset.Brightness
	Lighting.ExposureCompensation = preset.ExposureCompensation
	effects.Atmosphere.Color = preset.AtmosphereColor
	effects.Atmosphere.Decay = preset.AtmosphereDecay
	effects.Atmosphere.Density = preset.AtmosphereDensity
	effects.Atmosphere.Haze = preset.AtmosphereHaze
	effects.ColorCorrection.TintColor = preset.Tint
	effects.ColorCorrection.Saturation = preset.Saturation
	effects.ColorCorrection.Contrast = preset.Contrast
	effects.Bloom.Intensity = preset.BloomIntensity
end

local function remember(part: BasePart): Appearance
	local look = dayLook[part]
	if look == nil then
		look = { Material = part.Material, Color = part.Color }
		dayLook[part] = look
	end
	return look
end

-- Color de noche estable por ventana (según su posición).
local function windowColor(part: BasePart): Color3
	local p = part.Position
	local index = (math.floor(p.X * 7 + p.Z * 13 + p.Y * 3) % #WINDOW_NIGHT_COLORS) + 1
	return WINDOW_NIGHT_COLORS[index]
end

local function applyWindow(instance: Instance, on: boolean): ()
	if not instance:IsA("BasePart") then
		return
	end
	local look = remember(instance)
	if on and instance:GetAttribute(WorldTags.Attributes.Lit) == true then
		instance.Material = Enum.Material.Neon
		instance.Color = windowColor(instance)
	elseif on then
		instance.Material = look.Material
		instance.Color = WINDOW_DARK
	else
		instance.Material = look.Material
		instance.Color = look.Color
	end
end

local function applyNeon(instance: Instance, on: boolean): ()
	if instance:IsA("BasePart") then
		local look = remember(instance)
		instance.Material = if on then Enum.Material.Neon else look.Material
	end
end

local function applyLight(instance: Instance, on: boolean): ()
	if instance:IsA("Light") then
		instance.Enabled = on
	end
end

local APPLIERS: { [string]: (Instance, boolean) -> () } = {
	[WorldTags.Window] = applyWindow,
	[WorldTags.NightNeon] = applyNeon,
	[WorldTags.NightLight] = applyLight,
}

local function setCityLights(on: boolean): ()
	lightsOn = on
	for tag, apply in APPLIERS do
		for _, instance in CollectionService:GetTagged(tag) do
			apply(instance, on)
		end
	end
end

local function setLamp(lamp: Instance?, color: Color3?): ()
	if lamp ~= nil and lamp:IsA("BasePart") then
		lamp.Material = if color ~= nil then Enum.Material.Neon else Enum.Material.SmoothPlastic
		lamp.Color = color or SIGNAL_OFF
	end
end

local function updateTrafficLights(now: number): ()
	for _, head in CollectionService:GetTagged(WorldTags.TrafficLight) do
		local axis = head:GetAttribute(WorldTags.Attributes.Axis)
		local offset = if axis == 1 then SIGNAL_CYCLE_SECONDS / 2 else 0
		local t = (now + offset) % SIGNAL_CYCLE_SECONDS
		local active = if t < SIGNAL_GREEN_SECONDS
			then "Green"
			elseif t < SIGNAL_GREEN_SECONDS + SIGNAL_YELLOW_SECONDS then "Yellow"
			else "Red"
		for name, color in SIGNAL_COLORS do
			setLamp(head:FindFirstChild(name), if name == active then color else nil)
		end
	end
end

local function updateClocks(hour: number): ()
	local text = DayCycle.Format(hour)
	for _, clock in CollectionService:GetTagged(WorldTags.Clock) do
		local gui = clock:FindFirstChildOfClass("SurfaceGui")
		local label = if gui ~= nil then gui:FindFirstChildOfClass("TextLabel") else nil
		if label ~= nil and label.Text ~= text then
			label.Text = text
		end
	end
end

-- De noche: parpadeo irregular de las ruinas y baliza lenta de las azoteas.
local function updateBlinkers(now: number, on: boolean): ()
	for _, part in CollectionService:GetTagged(WorldTags.Flicker) do
		local light = part:FindFirstChildWhichIsA("Light")
		local seed = if part:IsA("BasePart") then part.Position.X * 0.13 else 0.37
		local lit = on and math.noise(now * 6, seed) > -0.25
		if light ~= nil then
			light.Enabled = lit
		end
		applyNeon(part, lit)
	end
	local beaconOn = on and (now % 2) < 0.8
	for _, part in CollectionService:GetTagged(WorldTags.Beacon) do
		local light = part:FindFirstChildWhichIsA("Light")
		if light ~= nil then
			light.Enabled = beaconOn
		end
		if part:IsA("BasePart") then
			part.Material = if beaconOn then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

local EnvironmentController = {
	Name = "EnvironmentController",
}

function EnvironmentController:Start(): ()
	effects = {
		Atmosphere = ensureEffect("Atmosphere", "Atmosphere"),
		Bloom = ensureEffect("BloomEffect", "Bloom"),
		ColorCorrection = ensureEffect("ColorCorrectionEffect", "ColorCorrection"),
	}
	effects.Bloom.Size = 28
	effects.Bloom.Threshold = 0.95
	local sunRays: SunRaysEffect = ensureEffect("SunRaysEffect", "SunRays")
	sunRays.Intensity = 0.06

	-- Lo que llega por streaming se pone al día con el estado actual.
	for tag, apply in APPLIERS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if lightsOn ~= nil then
				apply(instance, lightsOn)
			end
		end)
	end

	local lightingElapsed, animationElapsed = math.huge, math.huge
	RunService.Heartbeat:Connect(function(deltaTime)
		lightingElapsed += deltaTime
		animationElapsed += deltaTime
		local hour = Lighting.ClockTime
		if lightingElapsed >= LIGHTING_STEP_SECONDS then
			lightingElapsed = 0
			applyLighting(hour)
			local on = DayCycle.LightsOn(hour, EnvironmentConfig)
			if on ~= lightsOn then
				setCityLights(on)
			end
			updateClocks(hour)
		end
		if animationElapsed >= ANIMATION_STEP_SECONDS then
			animationElapsed = 0
			local now = Workspace:GetServerTimeNow()
			updateTrafficLights(now)
			updateBlinkers(now, lightsOn == true)
		end
	end)
end

return EnvironmentController
