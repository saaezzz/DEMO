--!strict

-- Ayudas para crear piezas del mapa con Lune (@lune/roblox). Todas las piezas
-- son Anchored. Las decorativas (Decor = true) no chocan, no proyectan
-- sombra y no las encuentran las hitboxes ni los raycasts: el mapa pesa menos
-- en móvil y no interfiere con el combate.

local roblox = require("@lune/roblox")

local WorldTags = require("../../src/Shared/Config/WorldTags")
local Geometry = require("./Geometry")

type Point = Geometry.Point

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

export type PartSpec = {
	Name: string?,
	Class: string?, -- "Part" (por defecto), "WedgePart", "TrussPart", "SpawnLocation"...
	Shape: string?, -- "Block" (por defecto), "Ball", "Cylinder"
	CFrame: any,
	Size: any,
	Color: any, -- "#RRGGBB" o Color3
	Material: string?,
	Transparency: number?,
	Reflectance: number?,
	-- Pieza decorativa: sin colisión, sombra ni consultas.
	Decor: boolean?,
	Collide: boolean?,
	Shadow: boolean?,
	Tags: { string }?,
	Attributes: { [string]: any }?,
}

local Build = {}

Build.Stats = { Parts = 0, Lights = 0, Guis = 0, Beams = 0 }

function Build.Color(value: any): any
	if typeof(value) == "string" then
		return Color3.fromHex(value)
	end
	return value
end

-- CFrame en (x, y, z) girado `yaw` radianes alrededor de Y.
function Build.CF(x: number, y: number, z: number, yaw: number?): any
	return CFrame.new(x, y, z) * CFrame.Angles(0, yaw or 0, 0)
end

-- Igual que CF pero desde un punto del plano.
function Build.At(p: Point, y: number, yaw: number?): any
	return Build.CF(p.X, y, p.Z, yaw)
end

function Build.V3(x: number, y: number, z: number): any
	return Vector3.new(x, y, z)
end

function Build.Part(parent: any, spec: PartSpec): any
	local part = Instance.new(spec.Class or "Part")
	if spec.Name ~= nil then
		part.Name = spec.Name
	end
	if spec.Shape ~= nil then
		part.Shape = (Enum.PartType :: any)[spec.Shape]
	end
	part.Anchored = true
	part.Size = spec.Size
	part.CFrame = spec.CFrame
	part.Color = Build.Color(spec.Color)
	part.Material = (Enum.Material :: any)[spec.Material or "SmoothPlastic"]
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if spec.Transparency ~= nil then
		part.Transparency = spec.Transparency
	end
	if spec.Reflectance ~= nil then
		part.Reflectance = spec.Reflectance
	end
	local decor = spec.Decor == true
	part.CanCollide = if spec.Collide ~= nil then spec.Collide else not decor
	part.CastShadow = if spec.Shadow ~= nil then spec.Shadow else not decor
	if decor then
		part.CanQuery = false
		part.CanTouch = false
	end
	for _, tag in spec.Tags or {} do
		part:AddTag(tag)
	end
	for name, value in spec.Attributes or {} do
		part:SetAttribute(name, value)
	end
	part.Parent = parent
	Build.Stats.Parts += 1
	return part
end

-- Caja: la forma más usada.
function Build.Box(parent: any, cframe: any, size: any, color: any, material: string?, extra: { [string]: any }?): any
	local spec: PartSpec = { CFrame = cframe, Size = size, Color = color, Material = material }
	for key, value in extra or {} do
		(spec :: any)[key] = value
	end
	return Build.Part(parent, spec)
end

-- Caja decorativa (ver arriba).
function Build.Decor(parent: any, cframe: any, size: any, color: any, material: string?, extra: { [string]: any }?): any
	local options: { [string]: any } = { Decor = true }
	for key, value in extra or {} do
		options[key] = value
	end
	return Build.Box(parent, cframe, size, color, material, options)
end

-- Caja a lo largo del tramo a→b: `width` de ancho, `height` de alto y la
-- cara superior a la altura `top`. `extend` alarga cada extremo.
function Build.Segment(
	parent: any,
	a: Point,
	b: Point,
	top: number,
	width: number,
	height: number,
	color: any,
	material: string?,
	extra: { [string]: any }?,
	extend: number?
): any
	local direction = Geometry.Sub(b, a)
	local length = Geometry.Length(direction) + 2 * (extend or 0)
	local mid = Geometry.Lerp(a, b, 0.5)
	return Build.Box(
		parent,
		Build.At(mid, top - height / 2, Geometry.YawForLook(direction)),
		Vector3.new(width, height, math.max(length, 0.05)),
		color,
		material,
		extra
	)
end

-- Cilindro vertical (el eje de un Cylinder de Roblox es X: se gira 90°).
function Build.Pillar(
	parent: any,
	p: Point,
	bottom: number,
	height: number,
	diameter: number,
	color: any,
	material: string?,
	extra: { [string]: any }?
): any
	local spec: PartSpec = {
		Shape = "Cylinder",
		CFrame = CFrame.new(p.X, bottom + height / 2, p.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Size = Vector3.new(height, diameter, diameter),
		Color = color,
		Material = material,
	}
	for key, value in extra or {} do
		(spec :: any)[key] = value
	end
	return Build.Part(parent, spec)
end

function Build.Ball(
	parent: any,
	position: any,
	diameter: number,
	color: any,
	material: string?,
	extra: { [string]: any }?
): any
	local spec: PartSpec = {
		Shape = "Ball",
		CFrame = CFrame.new(position),
		Size = Vector3.new(diameter, diameter, diameter),
		Color = color,
		Material = material,
		Decor = true,
	}
	for key, value in extra or {} do
		(spec :: any)[key] = value
	end
	return Build.Part(parent, spec)
end

function Build.Folder(parent: any, name: string, className: string?): any
	local folder = Instance.new(className or "Model")
	folder.Name = name
	folder.Parent = parent
	return folder
end

export type SignOptions = {
	TextColor: string?,
	Background: string?,
	-- Brilla por sí solo (sin depender de la luz de la escena).
	Glow: boolean?,
	Font: string?,
	-- Transparencia del fondo (1 = solo el texto).
	BackgroundTransparency: number?,
}

-- Texto en una cara de la pieza (SurfaceGui). `face`: "Front" (-Z), "Back", "Top"...
function Build.Sign(part: any, face: string, text: string, options: SignOptions?): any
	local opts: SignOptions = options or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = (Enum.NormalId :: any)[face]
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = if opts.Glow then 0 else 1
	gui.Brightness = if opts.Glow then 1.6 else 1
	gui.ZOffset = 1
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = roblox.UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Build.Color(opts.Background or "#FFFFFF")
	label.BackgroundTransparency = opts.BackgroundTransparency or (if opts.Background ~= nil then 0 else 1)
	label.TextColor3 = Build.Color(opts.TextColor or "#1A1A1A")
	label.TextScaled = true
	label.FontFace = roblox.Font.fromEnum((Enum.Font :: any)[opts.Font or "GothamBold"])
	label.Text = text
	label.BorderSizePixel = 0
	label.Parent = gui
	gui.Parent = part
	Build.Stats.Guis += 1
	return gui
end

export type LightOptions = {
	Range: number,
	Brightness: number,
	Color: string,
	-- "Point" (por defecto), "Surface" o "Spot".
	Kind: string?,
	Face: string?,
	Angle: number?,
	-- Encendida siempre (no solo de noche).
	Always: boolean?,
	Shadows: boolean?,
}

function Build.Light(part: any, options: LightOptions): any
	local light = Instance.new((options.Kind or "Point") .. "Light")
	light.Range = options.Range
	light.Brightness = options.Brightness
	light.Color = Build.Color(options.Color)
	light.Shadows = options.Shadows == true
	if options.Face ~= nil then
		light.Face = (Enum.NormalId :: any)[options.Face]
	end
	if options.Angle ~= nil then
		light.Angle = options.Angle
	end
	if not options.Always then
		light.Enabled = false
		light:AddTag(WorldTags.NightLight)
	end
	light.Parent = part
	Build.Stats.Lights += 1
	return light
end

-- Cable combado entre dos puntos del mundo (Beam entre dos Attachments).
-- Los Attachments se crean en `holderA` y `holderB`.
function Build.Wire(holderA: any, worldA: any, holderB: any, worldB: any, sag: number, color: string?): any
	local function attach(holder: any, world: any): any
		local attachment = Instance.new("Attachment")
		-- Eje X hacia abajo: la curva del Beam cuelga.
		attachment.CFrame = holder.CFrame:ToObjectSpace(CFrame.new(world)) * CFrame.Angles(0, 0, math.rad(-90))
		attachment.Parent = holder
		return attachment
	end
	local beam = Instance.new("Beam")
	beam.Attachment0 = attach(holderA, worldA)
	beam.Attachment1 = attach(holderB, worldB)
	beam.CurveSize0 = sag
	beam.CurveSize1 = -sag
	beam.Width0 = 0.12
	beam.Width1 = 0.12
	beam.Segments = 8
	beam.FaceCamera = true
	beam.Color = roblox.ColorSequence.new(Build.Color(color or "#1C1C1C"))
	beam.LightInfluence = 1
	beam.Parent = holderA
	Build.Stats.Beams += 1
	return beam
end

return Build
