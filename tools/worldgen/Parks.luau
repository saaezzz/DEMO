--!strict

-- Parques: césped con seto, caminos en cruz, árboles, bancos y farolas.
-- Variantes: estanque (parques grandes), parque infantil (columpios,
-- tobogán, arenero) y orilla del río (cerezos y una piedra conmemorativa).

local roblox = require("@lune/roblox")

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Props = require("./Props")
local Styles = require("./Styles")

type Context = Context.Context
type Point = Geometry.Point

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local Parks = {}

type ParkFrame = {
	Frame: any,
	Width: number,
	Depth: number,
	-- Punto y dirección en coordenadas del parque (-Z = su norte).
	Local: (x: number, z: number) -> Point,
	Direction: (x: number, z: number) -> Point,
}

local function parkFrame(park: any): ParkFrame
	local yaw = math.rad(park.Rotation)
	local frame = Build.At(park.Position, 0, yaw)
	return {
		Frame = frame,
		Width = park.Size.X,
		Depth = park.Size.Z,
		Local = function(x: number, z: number): Point
			local position = (frame * CFrame.new(x, 0, z)).Position
			return { X = position.X, Z = position.Z }
		end,
		Direction = function(x: number, z: number): Point
			return Geometry.Rotate({ X = x, Z = z }, yaw)
		end,
	}
end

local function lawn(folder: any, pf: ParkFrame, color: string): ()
	Build.Box(folder, pf.Frame * CFrame.new(0, 0.12, 0), Vector3.new(pf.Width, 0.24, pf.Depth), color, "Grass", {
		Name = "Lawn",
		Shadow = false,
	})
end

-- Seto alrededor con entradas en el centro de cada lado.
local function hedge(folder: any, pf: ParkFrame, gap: number): ()
	local w, d = pf.Width, pf.Depth
	for _, spec in
		{
			{ 0, -d / 2, w, true },
			{ 0, d / 2, w, true },
			{ -w / 2, 0, d, false },
			{ w / 2, 0, d, false },
		}
	do
		local length = (spec[3] - gap) / 2
		for _, sign in { -1, 1 } do
			local offset = sign * (gap / 2 + length / 2)
			local x = if spec[4] then offset else spec[1]
			local z = if spec[4] then spec[2] else offset
			local size = if spec[4] then Vector3.new(length, 2.6, 1.6) else Vector3.new(1.6, 2.6, length)
			Build.Box(
				folder,
				pf.Frame * CFrame.new(x, 1.3, z),
				size,
				"#3E7036",
				"Grass",
				{ Name = "Hedge", Shadow = false }
			)
		end
	end
end

local function paths(folder: any, pf: ParkFrame): ()
	Build.Decor(folder, pf.Frame * CFrame.new(0, 0.27, 0), Vector3.new(6, 0.1, pf.Depth), Styles.Sand, "Pebble")
	Build.Decor(folder, pf.Frame * CFrame.new(0, 0.27, 0), Vector3.new(pf.Width, 0.1, 6), Styles.Sand, "Pebble")
	Build.Decor(
		folder,
		pf.Frame * CFrame.new(0, 0.26, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(0.12, 18, 18),
		Styles.Sand,
		"Pebble",
		{ Shape = "Cylinder" }
	)
end

-- Árboles en los cuatro cuadrantes, lejos de los caminos.
local function trees(ctx: Context, folder: any, pf: ParkFrame, count: number, kinds: { Props.TreeKind }): ()
	local rng = ctx.Rng
	local placed = 0
	local attempts = 0
	while placed < count and attempts < count * 12 do
		attempts += 1
		local x = rng:Range(-pf.Width / 2 + 4, pf.Width / 2 - 4)
		local z = rng:Range(-pf.Depth / 2 + 4, pf.Depth / 2 - 4)
		if math.abs(x) > 7 and math.abs(z) > 7 and (x * x + z * z) > 150 then
			Props.Tree(folder, pf.Local(x, z), rng, rng:Pick(kinds))
			placed += 1
		end
	end
end

local function benchesAndLamps(folder: any, pf: ParkFrame): ()
	for _, spec in { { 5, 14, -1, 0 }, { -5, -14, 1, 0 }, { 14, -5, 0, 1 }, { -14, 5, 0, -1 } } do
		Props.Bench(folder, pf.Local(spec[1], spec[2]), pf.Direction(spec[3], spec[4]))
	end
	for _, corner in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		Props.ParkLamp(folder, pf.Local(corner[1] * 5, corner[2] * (pf.Depth / 2 - 6)))
	end
	for _, side in { 1, -1 } do
		Props.TrashBin(folder, pf.Local(side * 4.5, 10))
	end
end

-- Estanque redondo con piedras.
local function pond(ctx: Context, folder: any, pf: ParkFrame, x: number, z: number, radius: number): ()
	local center = pf.Local(x, z)
	Build.Pillar(folder, center, 0.05, 0.3, radius * 2 + 2, "#8D8A80", "Slate", { Decor = true, Name = "PondRim" })
	Build.Pillar(folder, center, 0.1, 0.3, radius * 2, "#4C8FA0", "Glass", {
		Decor = true,
		Name = "Pond",
		Transparency = 0.2,
		Reflectance = 0.25,
	})
	for i = 1, 7 do
		local angle = i / 7 * math.pi * 2 + ctx.Rng:Range(-0.2, 0.2)
		local p = { X = center.X + math.cos(angle) * (radius + 1.5), Z = center.Z + math.sin(angle) * (radius + 1.5) }
		Build.Ball(folder, Vector3.new(p.X, 0.5, p.Z), ctx.Rng:Range(1.5, 2.8), "#8A877E", "Slate")
	end
end

local function publicToilet(folder: any, pf: ParkFrame, x: number, z: number): ()
	Build.Box(folder, pf.Frame * CFrame.new(x, 4.5, z), Vector3.new(10, 9, 7), "#D8D2C4", "Brick", { Name = "Toilet" })
	Build.Decor(folder, pf.Frame * CFrame.new(x, 9.3, z), Vector3.new(11, 0.6, 8), "#5A4A3A", "Wood")
end

-- Columpios, tobogán, arenero y barras.
local function playground(folder: any, pf: ParkFrame, x: number, z: number): ()
	local base = pf.Frame * CFrame.new(x, 0, z)
	-- Columpios: pórtico y dos asientos colgando.
	for _, px in { -4, 4 } do
		Build.Box(
			folder,
			base * CFrame.new(px, 4, 0),
			Vector3.new(0.4, 8, 0.4),
			"#C23B22",
			"Metal",
			{ Name = "SwingFrame" }
		)
	end
	Build.Decor(folder, base * CFrame.new(0, 8, 0), Vector3.new(8.6, 0.4, 0.4), "#C23B22", "Metal")
	for _, sx in { -1.8, 1.8 } do
		Build.Decor(
			folder,
			base * CFrame.new(sx, 1.6, 0),
			Vector3.new(1.6, 0.2, 0.8),
			"#F2C12E",
			"SmoothPlastic",
			{ Name = "Seat" }
		)
		for _, rope in { -0.7, 0.7 } do
			Build.Decor(folder, base * CFrame.new(sx + rope, 4.8, 0), Vector3.new(0.08, 6.4, 0.08), "#8A8A8A", "Metal")
		end
	end
	-- Tobogán.
	local slide = base * CFrame.new(0, 0, 10)
	Build.Box(
		folder,
		slide * CFrame.new(-2.5, 2.5, 0),
		Vector3.new(3, 5, 3),
		"#2F7FC1",
		"SmoothPlastic",
		{ Name = "SlideTower" }
	)
	Build.Part(folder, {
		Name = "Slide",
		Class = "WedgePart",
		CFrame = slide * CFrame.new(2.2, 2.5, 0) * CFrame.Angles(0, math.rad(90), 0),
		Size = Vector3.new(2.4, 5, 6.4),
		Color = "#F2C12E",
		Material = "SmoothPlastic",
	})
	-- Arenero.
	Build.Decor(folder, base * CFrame.new(-10, 0.3, 5), Vector3.new(7, 0.4, 7), "#D8C48E", "Sand", { Name = "Sandbox" })
	for _, edge in { { 0, 3.6, 7.4, 0.4 }, { 0, -3.6, 7.4, 0.4 }, { 3.6, 0, 0.4, 7 }, { -3.6, 0, 0.4, 7 } } do
		Build.Decor(
			folder,
			base * CFrame.new(-10 + edge[1], 0.5, 5 + edge[2]),
			Vector3.new(edge[3], 0.8, edge[4]),
			Styles.Wood,
			"Wood"
		)
	end
	-- Barras.
	for i = 0, 2 do
		Build.Decor(
			folder,
			base * CFrame.new(10, 1.5 + i * 0.8, -4 + i * 2),
			Vector3.new(0.25, 3 + i * 1.6, 0.25),
			"#4DA35A",
			"Metal"
		)
	end
	Build.Decor(folder, base * CFrame.new(10, 5.6, -2), Vector3.new(0.25, 0.25, 5), "#4DA35A", "Metal")
end

local function buildPark(ctx: Context, park: any): ()
	local folder = Build.Folder(ctx.Folder("Parks"), park.Id)
	local pf = parkFrame(park)
	local rng = ctx.Rng

	if park.Kind == "Riverside" then
		-- Césped abierto hasta el río, cerezos en el borde y la piedra en recuerdo.
		lawn(folder, pf, Styles.Grass)
		for i = 1, 9 do
			local t = (i - 0.5) / 9
			Props.Tree(folder, pf.Local(-pf.Width / 2 + 5, -pf.Depth / 2 + t * pf.Depth), rng, "Cherry")
			if i % 3 == 0 then
				Props.Tree(folder, pf.Local(-pf.Width / 2 + t * pf.Width, pf.Depth / 2 - 5), rng, "Cherry")
			end
		end
		Build.Box(
			folder,
			pf.Frame * CFrame.new(pf.Width / 2 - 14, 2.5, 0),
			Vector3.new(3, 5, 1.4),
			"#7F7C74",
			"Slate",
			{
				Name = "MemorialStone",
			}
		)
		Build.Decor(
			folder,
			pf.Frame * CFrame.new(pf.Width / 2 - 14, 0.5, -1.4),
			Vector3.new(2.4, 1, 0.8),
			"#6A665E",
			"Slate"
		)
		for _, flower in { -0.6, 0, 0.6 } do
			Build.Ball(
				folder,
				(pf.Frame * CFrame.new(pf.Width / 2 - 14 + flower, 1.2, -1.4)).Position,
				0.6,
				"#F5E6A8",
				"SmoothPlastic"
			)
		end
		for _, z in { -pf.Depth / 3, pf.Depth / 3 } do
			Props.ParkLamp(folder, pf.Local(pf.Width / 2 - 4, z))
			Props.Bench(folder, pf.Local(pf.Width / 2 - 8, z + 5), pf.Direction(-1, 0))
		end
		return
	end

	lawn(folder, pf, Styles.Grass)
	hedge(folder, pf, 8)
	if park.Kind == "Playground" then
		playground(folder, pf, 0, -3)
		trees(ctx, folder, pf, 4, { "Leafy" })
		Props.ParkLamp(folder, pf.Local(pf.Width / 2 - 3, pf.Depth / 2 - 3))
		Props.Bench(folder, pf.Local(-pf.Width / 2 + 5, pf.Depth / 2 - 4), pf.Direction(0, -1))
		return
	end

	paths(folder, pf)
	benchesAndLamps(folder, pf)
	local big = pf.Width * pf.Depth > 7000
	if big then
		pond(ctx, folder, pf, pf.Width * 0.25, pf.Depth * 0.25, 9)
		publicToilet(folder, pf, -pf.Width / 2 + 10, pf.Depth / 2 - 9)
		trees(ctx, folder, pf, 22, { "Leafy", "Leafy", "Cherry", "Maple" })
	else
		trees(ctx, folder, pf, 10, { "Leafy", "Cherry" })
		playground(folder, pf, -pf.Width / 4, -pf.Depth / 4 + 2)
	end
	for _ = 1, 8 do
		Props.Bush(
			folder,
			pf.Local(rng:Range(-pf.Width / 2 + 3, pf.Width / 2 - 3), rng:Range(-pf.Depth / 2 + 3, pf.Depth / 2 - 3)),
			rng
		)
	end
end

function Parks.Build(ctx: Context): ()
	for _, park in ctx.Map.Parks do
		buildPark(ctx, park)
	end
end

return Parks
