--!strict

-- Mobiliario urbano y detalles pequeños. Cada función coloca un objeto en un
-- punto del suelo; `facing` es hacia dónde mira su frente (dirección en el
-- plano). Casi todo es decorativo (no choca): solo chocan troncos, postes y
-- cosas grandes.

local roblox = require("@lune/roblox")

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Rng = require("./Rng")
local Styles = require("./Styles")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Context = Context.Context
type Point = Geometry.Point
type Rng = Rng.Rng

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local Props = {}

local function yawOf(facing: Point): number
	return Geometry.YawForLook(facing)
end

-- Punto relativo al objeto: `right` a su derecha y `forward` hacia su frente.
local function offset(base: Point, facing: Point, right: number, forward: number): Point
	local rightVector = Geometry.Scale(Geometry.Normal(facing), -1)
	return Geometry.Add(Geometry.Add(base, Geometry.Scale(rightVector, right)), Geometry.Scale(facing, forward))
end

-- Farola de calle: poste, brazo hacia la calzada y luz cálida de noche.
function Props.StreetLamp(folder: any, p: Point, facing: Point, base: number?): ()
	local bottom = base or 0
	Build.Pillar(folder, p, bottom, 13, 0.55, Styles.MetalDark, "Metal", { Name = "LampPost" })
	local armEnd = Geometry.Add(p, Geometry.Scale(facing, 2.6))
	Build.Segment(folder, p, armEnd, bottom + 13, 0.3, 0.3, Styles.MetalDark, "Metal", { Decor = true })
	local head = Build.Decor(
		folder,
		Build.At(armEnd, bottom + 12.6, yawOf(facing)),
		Build.V3(1.1, 0.5, 2.2),
		"#E9E2D2",
		"SmoothPlastic",
		{ Name = "LampHead", Tags = { WorldTags.NightNeon } }
	)
	Build.Light(head, { Range = 22, Brightness = 1.4, Color = Styles.LampWarm })
end

-- Farola baja de parque, con globo.
function Props.ParkLamp(folder: any, p: Point): ()
	Build.Pillar(folder, p, 0, 8, 0.4, "#2F3A33", "Metal", { Name = "ParkLamp" })
	local globe = Build.Ball(folder, Vector3.new(p.X, 8.5, p.Z), 1.4, "#F4EEDC", "SmoothPlastic", {
		Tags = { WorldTags.NightNeon },
	})
	Build.Light(globe, { Range = 16, Brightness = 1.2, Color = Styles.LampWarm })
end

export type PoleWires = {
	Holder: any,
	Points: { any },
}

-- Poste eléctrico de hormigón con travesaño (y a veces transformador).
-- Devuelve los puntos de amarre de sus tres cables.
function Props.UtilityPole(folder: any, p: Point, along: Point, rng: Rng): PoleWires
	Build.Pillar(folder, p, 0, 22, 0.9, Styles.Pole, "Concrete", { Name = "UtilityPole" })
	local across = Geometry.Normal(along)
	local arm = Build.Decor(
		folder,
		Build.At(p, 20.5, Geometry.YawForBack(across)),
		Build.V3(0.35, 0.35, 5),
		Styles.MetalDark,
		"Metal",
		{ Name = "CrossArm" }
	)
	if rng:Chance(0.25) then
		local side = Geometry.Add(p, Geometry.Scale(along, 1.1))
		Build.Pillar(folder, side, 15, 2.6, 1.6, "#9AA2A6", "Metal", { Decor = true, Name = "Transformer" })
	end
	-- Placa amarilla con franjas negras en la base (típica de los postes).
	Build.Decor(folder, Build.At(p, 1.8, Geometry.YawForBack(across)), Build.V3(1, 2.2, 1), "#E4C23A", "SmoothPlastic")
	local points = {}
	for _, k in { -2.2, 0, 2.2 } do
		local q = Geometry.Add(p, Geometry.Scale(across, k))
		table.insert(points, Vector3.new(q.X, 20.8, q.Z))
	end
	return { Holder = arm, Points = points }
end

function Props.ConnectPoles(a: PoleWires, b: PoleWires, rng: Rng): ()
	local sag = rng:Range(0.8, 1.6)
	for i = 1, 3 do
		Build.Wire(a.Holder, a.Points[i], b.Holder, b.Points[i], sag)
	end
end

-- Máquina expendedora: cuerpo de color y frente iluminado.
function Props.VendingMachine(folder: any, p: Point, facing: Point, rng: Rng): ()
	local yaw = yawOf(facing)
	Build.Box(folder, Build.At(p, 3.2, yaw), Build.V3(3.2, 6.4, 2.4), rng:Pick(Styles.VendingColors), "SmoothPlastic", {
		Name = "VendingMachine",
	})
	local front = offset(p, facing, 0, 1.22)
	Build.Decor(folder, Build.At(front, 4.2, yaw), Build.V3(2.6, 2.6, 0.1), "#F6F8FF", "Neon", { Name = "Display" })
	Build.Decor(folder, Build.At(front, 1.2, yaw), Build.V3(2.2, 0.6, 0.12), "#1C1C1C", "SmoothPlastic")
	-- Papelera de latas al lado.
	local bin = offset(p, facing, 2.4, 0.3)
	Build.Pillar(folder, bin, 0, 2.6, 1.2, "#3E6DB5", "SmoothPlastic", { Decor = true, Name = "CanBin" })
end

export type TreeKind = "Leafy" | "Cherry" | "Pine" | "Maple"

-- Árbol: tronco (choca) y copa de bolas (no choca).
function Props.Tree(folder: any, p: Point, rng: Rng, kind: TreeKind?): ()
	local treeKind: TreeKind = kind or "Leafy"
	local scale = rng:Range(0.8, 1.25)
	local trunkHeight = (if treeKind == "Pine" then 10 else 7) * scale
	Build.Pillar(
		folder,
		p,
		0,
		trunkHeight,
		0.9 * scale,
		if treeKind == "Cherry" then "#5B4034" else "#5E4A38",
		"Wood",
		{
			Name = "Trunk",
		}
	)
	local leaves = if treeKind == "Cherry"
		then { "#F4B6C9", "#F7C8D6", "#EFA3BB" }
		elseif treeKind == "Maple" then { "#C8552E", "#D9772F", "#B8402A" }
		elseif treeKind == "Pine" then { "#2F5A3A", "#35613F" }
		else { "#4F8A3C", "#5C9745", "#467D36", "#6A9F4B" }
	local count = if treeKind == "Pine" then 3 else rng:Int(3, 4)
	for i = 1, count do
		local radius = (if treeKind == "Pine" then 5.5 - i * 1.3 else rng:Range(4, 5.8)) * scale
		local spread = if treeKind == "Pine" then 0 else 2.2 * scale
		local center = Vector3.new(
			p.X + rng:Range(-spread, spread),
			trunkHeight + (if treeKind == "Pine" then i * 2.6 - 1 else rng:Range(0, 2.5)) * scale,
			p.Z + rng:Range(-spread, spread)
		)
		Build.Ball(folder, center, radius * 2, rng:Pick(leaves), "Grass", { Name = "Leaves" })
	end
	-- Algunos cerezos sueltan pétalos.
	if treeKind == "Cherry" and rng:Chance(0.45) then
		local emitterPart = Build.Decor(
			folder,
			Build.At(p, trunkHeight + 2, 0),
			Build.V3(8, 0.2, 8),
			"#FFFFFF",
			"SmoothPlastic",
			{ Transparency = 1, Name = "Petals" }
		)
		local emitter = roblox.Instance.new("ParticleEmitter")
		emitter.Rate = 1.5
		emitter.Lifetime = roblox.NumberRange.new(5, 8)
		emitter.Speed = roblox.NumberRange.new(0.5, 1.5)
		emitter.Acceleration = Vector3.new(0.6, -1.2, 0.3)
		emitter.RotSpeed = roblox.NumberRange.new(-60, 60)
		emitter.Rotation = roblox.NumberRange.new(0, 360)
		emitter.Size = roblox.NumberSequence.new(0.25)
		emitter.Color = roblox.ColorSequence.new(Build.Color("#F7C6D4"))
		emitter.LightInfluence = 1
		emitter.EmissionDirection = roblox.Enum.NormalId.Bottom
		emitter.Parent = emitterPart
	end
end

function Props.Bush(folder: any, p: Point, rng: Rng): ()
	local size = rng:Range(2.5, 4)
	Build.Ball(folder, Vector3.new(p.X, size * 0.35, p.Z), size, rng:Pick({ "#3F7A34", "#4C8A3E", "#56923F" }), "Grass")
end

function Props.Bench(folder: any, p: Point, facing: Point): ()
	local yaw = yawOf(facing)
	Build.Decor(folder, Build.At(p, 1.7, yaw), Build.V3(5, 0.35, 1.6), Styles.Wood, "Wood", { Name = "Bench" })
	Build.Decor(folder, Build.At(offset(p, facing, 0, -0.8), 2.6, yaw), Build.V3(5, 1.4, 0.25), Styles.Wood, "Wood")
	for _, side in { -2, 2 } do
		Build.Decor(
			folder,
			Build.At(offset(p, facing, side, 0), 0.8, yaw),
			Build.V3(0.3, 1.6, 1.4),
			Styles.MetalDark,
			"Metal"
		)
	end
end

-- Coche aparcado (carrocería, habitáculo con cristales y ruedas).
function Props.Car(folder: any, p: Point, facing: Point, rng: Rng, color: string?): ()
	local yaw = yawOf(facing)
	local paint = color or rng:Pick(Styles.Cars)
	local model = Build.Folder(folder, "Car")
	Build.Box(model, Build.At(p, 2.1, yaw), Build.V3(6, 2.2, 13), paint, "SmoothPlastic", { Name = "Body" })
	Build.Decor(model, Build.At(offset(p, facing, 0, -1), 4.1, yaw), Build.V3(5.4, 1.9, 7), "#2B3640", "Glass", {
		Reflectance = 0.2,
	})
	Build.Decor(model, Build.At(offset(p, facing, 0, -1), 5.1, yaw), Build.V3(5.2, 0.2, 6.6), paint, "SmoothPlastic")
	for _, forward in { -4.2, 4.2 } do
		local axle = offset(p, facing, 0, forward)
		Build.Decor(
			model,
			Build.At(axle, 1.1, yaw),
			Build.V3(2.2, 2.2, 6.2),
			"#1A1A1A",
			"SmoothPlastic",
			{ Shape = "Cylinder" }
		)
	end
	-- Faros delanteros.
	Build.Decor(
		model,
		Build.At(offset(p, facing, 0, 6.52), 2.4, yaw),
		Build.V3(4.6, 0.5, 0.1),
		"#F2F0E0",
		"SmoothPlastic"
	)
end

function Props.Bicycle(folder: any, p: Point, facing: Point): ()
	local yaw = yawOf(facing)
	for _, forward in { -1.3, 1.3 } do
		Build.Decor(
			folder,
			Build.At(offset(p, facing, 0, forward), 1.1, yaw),
			Build.V3(0.15, 2.2, 2.2),
			"#222222",
			"SmoothPlastic",
			{ Shape = "Cylinder" }
		)
	end
	Build.Decor(folder, Build.At(p, 1.8, yaw), Build.V3(0.18, 0.18, 2.6), "#B8B8B8", "Metal")
	Build.Decor(folder, Build.At(offset(p, facing, 0, 1.1), 2.6, yaw), Build.V3(1.4, 0.15, 0.15), "#444444", "Metal")
	Build.Decor(folder, Build.At(offset(p, facing, 0, 1.4), 2.1, yaw), Build.V3(0.9, 0.5, 0.7), "#D0D0D0", "Metal")
end

-- Buzón rojo de correos.
function Props.PostBox(folder: any, p: Point, facing: Point): ()
	local yaw = yawOf(facing)
	Build.Box(folder, Build.At(p, 1.9, yaw), Build.V3(1.6, 3.8, 1.3), "#C62828", "SmoothPlastic", { Name = "PostBox" })
	Build.Decor(folder, Build.At(p, 3.95, yaw), Build.V3(1.8, 0.3, 1.5), "#A51F1F", "SmoothPlastic")
	Build.Decor(
		folder,
		Build.At(offset(p, facing, 0, 0.66), 3.1, yaw),
		Build.V3(1, 0.15, 0.05),
		"#1A1A1A",
		"SmoothPlastic"
	)
end

function Props.TrashBin(folder: any, p: Point): ()
	Build.Pillar(folder, p, 0, 2.4, 1.3, "#6D7B6A", "Metal", { Decor = true, Name = "TrashBin" })
end

-- Punto de basura de un bloque: caja de rejilla con red verde.
function Props.GarbageStation(folder: any, p: Point, facing: Point): ()
	local yaw = yawOf(facing)
	Build.Decor(folder, Build.At(p, 1.5, yaw), Build.V3(5, 3, 3), "#3F8C4A", "Fabric", { Transparency = 0.25 })
	Build.Decor(folder, Build.At(p, 0.6, yaw), Build.V3(4.4, 1.2, 2.4), "#DADADA", "SmoothPlastic")
end

function Props.AirConditioner(folder: any, cframe: any): ()
	Build.Decor(folder, cframe, Build.V3(2.6, 1.8, 1.1), "#E6E6E2", "SmoothPlastic", { Name = "AirConditioner" })
	Build.Decor(folder, cframe * CFrame.new(0.4, 0, -0.56), Build.V3(1.2, 1.2, 0.05), "#8B8B8B", "DiamondPlate")
end

-- Semáforo en una esquina: poste, brazo sobre la calle y cabeza con tres luces.
-- `axis` agrupa las cabezas que se ponen en verde a la vez.
function Props.TrafficLight(folder: any, corner: Point, across: Point, facing: Point, axis: number): ()
	Build.Pillar(folder, corner, 0, 14, 0.6, "#9AA0A5", "Metal", { Name = "SignalPole" })
	local armEnd = Geometry.Add(corner, Geometry.Scale(across, 7))
	Build.Segment(folder, corner, armEnd, 13.6, 0.4, 0.4, "#9AA0A5", "Metal", { Decor = true })
	local yaw = yawOf(facing)
	local head = Build.Decor(
		folder,
		Build.At(armEnd, 13, yaw),
		Build.V3(4.2, 1.4, 0.9),
		"#2B2E31",
		"SmoothPlastic",
		{ Name = "SignalHead", Tags = { WorldTags.TrafficLight }, Attributes = { [WorldTags.Attributes.Axis] = axis } }
	)
	for index, name in { "Green", "Yellow", "Red" } do
		local lamp = Build.Decor(
			folder,
			head.CFrame * CFrame.new((index - 2) * 1.35, 0, -0.5),
			Build.V3(1, 1, 0.12),
			"#2A2A2A",
			"SmoothPlastic",
			{ Name = name }
		)
		lamp.Parent = head
	end
end

-- Placa azul con el nombre del distrito.
function Props.DistrictSign(folder: any, p: Point, facing: Point, kanji: string, name: string): ()
	local yaw = yawOf(facing)
	Build.Pillar(folder, p, 0, 9, 0.35, "#9AA0A5", "Metal", { Name = "DistrictSign" })
	local plate = Build.Decor(
		folder,
		Build.At(offset(p, facing, 0, 0.25), 8, yaw),
		Build.V3(5, 1.9, 0.15),
		"#1F4F8F",
		"SmoothPlastic"
	)
	Build.Sign(plate, "Front", `{kanji}\n{name}`, { TextColor = "#FFFFFF", Background = "#1F4F8F" })
	Build.Sign(plate, "Back", `{kanji}\n{name}`, { TextColor = "#FFFFFF", Background = "#1F4F8F" })
end

-- Marquesina de autobús con banco.
function Props.BusStop(folder: any, p: Point, facing: Point): ()
	local yaw = yawOf(facing)
	Build.Box(folder, Build.At(offset(p, facing, 0, -1.5), 3.5, yaw), Build.V3(8, 7, 0.2), "#A8C8D8", "Glass", {
		Transparency = 0.5,
		Name = "BusShelter",
	})
	Build.Decor(folder, Build.At(p, 7.2, yaw), Build.V3(8.6, 0.3, 3.6), "#E0E0E0", "Metal")
	Props.Bench(folder, offset(p, facing, 0, -0.6), facing)
	local sign = offset(p, facing, 4.8, 1.2)
	Build.Pillar(folder, sign, 0, 8, 0.25, "#8A8A8A", "Metal", { Decor = true })
	local plate = Build.Decor(folder, Build.At(sign, 7.8, yaw), Build.V3(1.8, 1.8, 0.12), "#2E6FB0", "SmoothPlastic")
	Build.Sign(plate, "Front", "バス", { TextColor = "#FFFFFF", Background = "#2E6FB0" })
end

-- Farolillo de papel rojo que brilla de noche.
function Props.Lantern(folder: any, position: any): ()
	local lantern = Build.Ball(folder, position, 1.6, "#D83A2A", "SmoothPlastic", {
		Tags = { WorldTags.NightNeon },
		Name = "Lantern",
	})
	Build.Light(lantern, { Range = 10, Brightness = 1, Color = "#FF8A5A" })
end

-- Farolas a lo largo de las carreteras y semáforos en los cruces.
function Props.Streets(ctx: Context, junctions: { any }): ()
	local folder = ctx.Folder("StreetLights")
	local settings = ctx.Settings
	for _, road in ctx.Roads do
		local spacing = if road.Kind == "Arterial" then 46 else 58
		local side = 1
		local points = if road.Closed then table.clone(road.Points) else road.Points
		if road.Closed then
			table.insert(points, road.Points[1])
		end
		for _, sample in Geometry.SampleEvery(points, spacing) do
			side = -side
			local normal = Geometry.Normal(sample.Direction)
			local p = Geometry.Add(sample.Position, Geometry.Scale(normal, side * (road.Width / 2 + 1.2)))
			if
				ctx.RoadClearance(p, road.Id) > 2
				and ctx.RiverClearance(p) > 0
				and ctx.RailClearance(p) > 10
				and not ctx.IsReserved(p, 1)
			then
				Props.StreetLamp(folder, p, Geometry.Scale(normal, -side), settings.SidewalkTop)
			end
		end
	end

	local signals = ctx.Folder("TrafficLights")
	for _, junction in junctions do
		if junction.HasArterial and #junction.Arms >= 2 then
			local a, b = junction.Arms[1], junction.Arms[2]
			local da, db = a.Direction, b.Direction
			-- Dos esquinas opuestas; cada semáforo cuelga sobre una calle.
			for _, sign in { 1, -1 } do
				local corner = Geometry.Add(
					junction.Position,
					Geometry.Add(
						Geometry.Scale(da, sign * (b.Road.Half + 1.5)),
						Geometry.Scale(db, sign * (a.Road.Half + 1.5))
					)
				)
				if ctx.RiverClearance(corner) > 0 and ctx.RailClearance(corner) > 8 then
					local towardA = Geometry.Unit(Geometry.Scale(db, -sign))
					Props.TrafficLight(signals, corner, towardA, Geometry.Scale(da, sign), 0)
					local towardB = Geometry.Unit(Geometry.Scale(da, -sign))
					Props.TrafficLight(signals, corner, towardB, Geometry.Scale(db, sign), 1)
				end
			end
		end
	end

	-- Placa de cada distrito junto a la calle más cercana a su centro.
	local signs = ctx.Folder("DistrictSigns")
	local seen: { [string]: boolean } = {}
	for _, district in ctx.Map.Districts do
		if not seen[district.DisplayName] then
			seen[district.DisplayName] = true
			local center = Geometry.Centroid(district.Polygon)
			local bestPoint, bestDirection, bestRoad = nil, nil, nil
			local bestDistance = math.huge
			for _, road in ctx.Roads do
				local q, direction = Geometry.ClosestOnPolyline(center, road.Points)
				local distance = Geometry.Distance(q, center)
				if distance < bestDistance then
					bestPoint, bestDirection, bestRoad, bestDistance = q, direction, road, distance
				end
			end
			if bestPoint ~= nil and bestDirection ~= nil and bestRoad ~= nil then
				local toCenter = Geometry.Unit(Geometry.Sub(center, bestPoint))
				local p = Geometry.Add(bestPoint, Geometry.Scale(toCenter, bestRoad.Width / 2 + 2.5))
				Props.DistrictSign(signs, p, bestDirection, district.Kanji, district.DisplayName)
			end
		end
	end
end

return Props
