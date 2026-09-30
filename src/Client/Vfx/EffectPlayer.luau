--!strict

-- Reproduce efectos visuales de Content/Effects (D-035). Si Arte ha colocado
-- el efecto en Studio (Assets/VFX/<Asset>), se usa ese; si no, se genera uno
-- provisional según su Kind. Todo es local al cliente.
--
-- Efectos de Arte: un Model o una Part con ParticleEmitters. Al reproducirlo,
-- cada emisor lanza `EmitCount` partículas (atributo del emisor, 20 por
-- defecto) y el objeto se borra tras `Lifetime` segundos (atributo del objeto;
-- por defecto, la duración del efecto + 2 s para que acaben las partículas).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Effects = require(ReplicatedStorage.Shared.Content.Effects)
local AssetLibrary = require(ReplicatedStorage.Shared.Modules.AssetLibrary)

local DEFAULT_EMIT_COUNT = 20
local PARTICLE_GRACE_SECONDS = 2
local FOLDER_NAME = "Effects"

export type PlayOptions = {
	-- Sustituyen a los del efecto (p. ej. el radio de un ataque en área).
	Radius: number?,
	Duration: number?,
	-- Instancias que el rayo al suelo debe atravesar (p. ej. el propio atacante,
	-- para que un círculo no se quede a media altura sobre su cuerpo).
	Ignore: { Instance }?,
}

local folder: Folder? = nil

local function getFolder(): Folder
	local current = folder
	if current == nil or current.Parent == nil then
		local created = Instance.new("Folder")
		created.Name = FOLDER_NAME
		created.Parent = Workspace
		folder = created
		return created
	end
	return current
end

-- Pieza decorativa: sin colisiones ni consultas, para no interferir con hitboxes.
local function effectPart(shape: Enum.PartType, color: Color3): Part
	local part = Instance.new("Part")
	part.Shape = shape
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function fadeAndDestroy(part: BasePart, duration: number, goal: { [string]: any }): ()
	goal.Transparency = 1
	TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	task.delay(duration, function()
		part:Destroy()
	end)
end

-- Punto del suelo bajo `position` (o `position` si no hay suelo cerca).
local function groundBelow(position: Vector3, ignore: { Instance }?): Vector3
	local excluded: { Instance } = { getFolder() }
	if ignore ~= nil then
		table.move(ignore, 1, #ignore, 2, excluded)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	local result = Workspace:Raycast(position, Vector3.new(0, -25, 0), params)
	return if result ~= nil then result.Position else position
end

local function playAsset(instance: Instance, origin: CFrame, duration: number): ()
	if instance:IsA("Model") then
		instance:PivotTo(origin)
	elseif instance:IsA("BasePart") then
		instance.CFrame = origin
	end
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
		end
	end
	instance.Parent = getFolder()
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			local count = descendant:GetAttribute("EmitCount")
			descendant:Emit(if typeof(count) == "number" then count else DEFAULT_EMIT_COUNT)
		end
	end
	local lifetime = instance:GetAttribute("Lifetime")
	task.delay(if typeof(lifetime) == "number" then lifetime else duration + PARTICLE_GRACE_SECONDS, function()
		instance:Destroy()
	end)
end

local EffectPlayer = {}

-- Reproduce el efecto `effectId` en `origin` (normalmente el HumanoidRootPart).
function EffectPlayer.Play(effectId: string, origin: CFrame, options: PlayOptions?): ()
	local definition = Effects[effectId]
	if definition == nil then
		return
	end
	local cframe = origin * (definition.Offset or CFrame.identity)
	local duration = if options ~= nil and options.Duration ~= nil then options.Duration else definition.Duration
	local radius = if options ~= nil and options.Radius ~= nil then options.Radius else definition.Radius or 3

	if definition.Kind == "Ring" then
		-- Los avisos de área van en el suelo, también el asset de Arte.
		local ground = groundBelow(cframe.Position, if options ~= nil then options.Ignore else nil)
		cframe = CFrame.new(ground + Vector3.new(0, 0.1, 0))
	end

	local asset = if definition.Asset ~= nil then AssetLibrary.Clone(definition.Asset) else nil
	if asset ~= nil then
		playAsset(asset, cframe, duration)
		return
	end

	local color = Color3.fromHex(definition.Color)
	if definition.Kind == "Beam" then
		local length = definition.Length or 20
		local width = definition.Width or 1
		local beam = effectPart(Enum.PartType.Block, color)
		beam.Size = Vector3.new(width, width, length)
		beam.CFrame = cframe * CFrame.new(0, 0, -length / 2)
		beam.Transparency = 0.1
		beam.Parent = getFolder()
		fadeAndDestroy(beam, duration, { Size = Vector3.new(width * 0.2, width * 0.2, length) })
	elseif definition.Kind == "Burst" then
		local ball = effectPart(Enum.PartType.Ball, color)
		ball.Size = Vector3.one
		ball.CFrame = cframe
		ball.Transparency = 0.3
		ball.Parent = getFolder()
		fadeAndDestroy(ball, duration, { Size = Vector3.one * radius * 2 })
	else
		-- Ring: disco plano en el suelo que se vuelve más visible hasta el impacto.
		local ring = effectPart(Enum.PartType.Cylinder, color)
		ring.Size = Vector3.new(0.15, radius * 2, radius * 2)
		ring.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.75
		ring.Parent = getFolder()
		TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Transparency = 0.35 }):Play()
		task.delay(duration, function()
			ring:Destroy()
		end)
	end
end

return EffectPlayer
