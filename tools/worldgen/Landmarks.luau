--!strict

-- Edificios singulares (Content/Maps: Landmarks). Cada Kind tiene su
-- constructor; todos reciben un marco en el centro de la parcela con la
-- fachada hacia -Z local. Para un tipo nuevo, añade su función a BUILDERS.

local roblox = require("@lune/roblox")

local Build = require("./Build")
local Buildings = require("./Buildings")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Props = require("./Props")
local Rng = require("./Rng")
local Styles = require("./Styles")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Context = Context.Context
type Point = Geometry.Point
type Rng = Rng.Rng

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local FLOOR = 10

-- Túnel de bajada a la galería subterránea.
local TUNNEL_WIDTH = 10
local TUNNEL_HEIGHT = 12
-- Entrada del túnel en coordenadas de la parcela de la tienda.
local TUNNEL_ENTRANCE = { X = -24, Z = -22 }

local Landmarks = {}

type LandmarkFrame = {
	Frame: any,
	Width: number,
	Depth: number,
	Rng: Rng,
	-- Punto del suelo y dirección en coordenadas de la parcela.
	Local: (x: number, z: number) -> Point,
	Direction: (x: number, z: number) -> Point,
	At: (x: number, y: number, z: number) -> any,
}

local function frameOf(ctx: Context, landmark: any): LandmarkFrame
	local yaw = math.rad(landmark.Rotation)
	local frame = Build.At(landmark.Position, 0, yaw)
	return {
		Frame = frame,
		Width = landmark.Size.X,
		Depth = landmark.Size.Z,
		Rng = ctx.Rng,
		Local = function(x: number, z: number): Point
			local position = (frame * CFrame.new(x, 0, z)).Position
			return { X = position.X, Z = position.Z }
		end,
		Direction = function(x: number, z: number): Point
			return Geometry.Rotate({ X = x, Z = z }, yaw)
		end,
		At = function(x: number, y: number, z: number): any
			return frame * CFrame.new(x, y, z)
		end,
	}
end

local function window(folder: any, cframe: any, size: any, rng: Rng, litChance: number): ()
	Build.Decor(folder, cframe, size, Styles.WindowDay, "Glass", {
		Name = "Window",
		Reflectance = 0.15,
		Tags = { WorldTags.Window },
		Attributes = { [WorldTags.Attributes.Lit] = rng:Chance(litChance) },
	})
end

-- Cuerpo de edificio con bandas de ventanas por planta en las caras pedidas.
local function block(
	folder: any,
	lf: LandmarkFrame,
	x: number,
	z: number,
	width: number,
	depth: number,
	floors: number,
	wall: string,
	litChance: number,
	faces: { string }?
): any
	local height = floors * FLOOR
	local body = Build.Box(folder, lf.At(x, height / 2, z), Vector3.new(width, height, depth), wall, "Concrete", {
		Name = "Building",
	})
	for floor = 1, floors do
		local y = (floor - 1) * FLOOR + 5.5
		for _, face in faces or { "Front", "Back" } do
			if face == "Front" then
				window(folder, lf.At(x, y, z - depth / 2 - 0.08), Vector3.new(width - 3, 4, 0.2), lf.Rng, litChance)
			elseif face == "Back" then
				window(folder, lf.At(x, y, z + depth / 2 + 0.08), Vector3.new(width - 3, 4, 0.2), lf.Rng, litChance)
			elseif face == "Left" then
				window(folder, lf.At(x - width / 2 - 0.08, y, z), Vector3.new(0.2, 4, depth - 3), lf.Rng, litChance)
			elseif face == "Right" then
				window(folder, lf.At(x + width / 2 + 0.08, y, z), Vector3.new(0.2, 4, depth - 3), lf.Rng, litChance)
			end
		end
	end
	Build.Decor(folder, lf.At(x, height + 0.5, z), Vector3.new(width + 0.4, 1, depth + 0.4), "#8E8B84", "Concrete")
	return body
end

-- Valla alrededor de la parcela con un hueco centrado delante.
local function fence(
	folder: any,
	lf: LandmarkFrame,
	gap: number,
	color: string,
	height: number,
	transparency: number?
): ()
	local w, d = lf.Width - 1, lf.Depth - 1
	local sideLength = (w - gap) / 2
	local extra = { Name = "Fence", Transparency = transparency or 0, Shadow = false }
	for _, sign in { -1, 1 } do
		Build.Box(
			folder,
			lf.At(sign * (gap / 2 + sideLength / 2), height / 2, -d / 2),
			Vector3.new(sideLength, height, 0.4),
			color,
			"Metal",
			extra
		)
	end
	Build.Box(folder, lf.At(0, height / 2, d / 2), Vector3.new(w, height, 0.4), color, "Metal", extra)
	Build.Box(folder, lf.At(-w / 2, height / 2, 0), Vector3.new(0.4, height, d), color, "Metal", extra)
	Build.Box(folder, lf.At(w / 2, height / 2, 0), Vector3.new(0.4, height, d), color, "Metal", extra)
end

local function ground(folder: any, lf: LandmarkFrame, color: string, material: string): ()
	Build.Box(
		folder,
		lf.At(0, 0.1, 0),
		Vector3.new(lf.Width, 0.2, lf.Depth),
		color,
		material,
		{ Name = "Lot", Shadow = false }
	)
end

local function signBoard(folder: any, cframe: any, size: any, text: string, textColor: string, background: string): any
	local board = Build.Decor(folder, cframe, size, background, "SmoothPlastic", { Name = "Sign" })
	Build.Sign(board, "Front", text, { TextColor = textColor, Background = background, Glow = true, Font = "Antique" })
	return board
end

-- Reloj de fachada: el cliente escribe la hora del juego.
local function clock(folder: any, cframe: any, size: number): ()
	local face = Build.Decor(folder, cframe, Vector3.new(size, size, 0.3), "#F4F4F0", "SmoothPlastic", {
		Name = "Clock",
		Tags = { WorldTags.Clock },
	})
	Build.Sign(face, "Front", "--:--", { TextColor = "#1A1A1A", Background = "#F4F4F0", Font = "GothamBold" })
end

-- Tienda con galería de entrenamiento ----------------------------------------

-- Galería subterránea: suelo de tierra, paredes de roca, techo pintado de
-- cielo con luces, formaciones rocosas y el túnel de bajada.
local function buildUnderground(ctx: Context, folder: any, entrance: Point): ()
	local data = ctx.Map.Underground
	local rng = ctx.Rng
	local center = data.Center
	local size = data.Size
	local floorY, ceilingY = data.FloorY, data.CeilingY
	local height = ceilingY - floorY
	local model = Build.Folder(folder, "TrainingGround")

	Build.Box(
		model,
		Build.At(center, floorY - 2, 0),
		Vector3.new(size, 4, size),
		"#C4A67A",
		"Ground",
		{ Name = "Floor" }
	)
	for _, spec in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		local p = { X = center.X + spec[1] * (size / 2 + 2), Z = center.Z + spec[2] * (size / 2 + 2) }
		local wallSize = if spec[1] == 0
			then Vector3.new(size + 8, height + 8, 4)
			else Vector3.new(4, height + 8, size + 8)
		Build.Box(model, Build.At(p, floorY + height / 2, 0), wallSize, "#8B7B66", "Rock", { Name = "RockWall" })
	end
	-- Techo de cielo: paneles con luz hacia abajo.
	local panels = 3
	local panel = size / panels
	for i = 0, panels - 1 do
		for j = 0, panels - 1 do
			local p = { X = center.X - size / 2 + panel * (i + 0.5), Z = center.Z - size / 2 + panel * (j + 0.5) }
			local sky = Build.Box(
				model,
				Build.At(p, ceilingY + 2, 0),
				Vector3.new(panel, 4, panel),
				"#8EC5EA",
				"SmoothPlastic",
				{
					Name = "PaintedSky",
					Shadow = false,
				}
			)
			Build.Light(sky, {
				Kind = "Surface",
				Face = "Bottom",
				Range = 60,
				Brightness = 1.4,
				Color = "#FFF4E0",
				Angle = 90,
				Always = true,
			})
		end
	end
	for _ = 1, 7 do
		local p =
			{ X = center.X + rng:Range(-size / 2.5, size / 2.5), Z = center.Z + rng:Range(-size / 2.5, size / 2.5) }
		Build.Decor(
			model,
			Build.At(p, ceilingY - 0.5, rng:Range(0, math.pi)),
			Vector3.new(rng:Range(20, 40), 1, rng:Range(10, 18)),
			"#F4F8FB",
			"SmoothPlastic",
			{
				Name = "PaintedCloud",
			}
		)
	end
	-- Rocas: lejos del centro, donde están los muñecos.
	local placed = 0
	while placed < 18 do
		local p = {
			X = center.X + rng:Range(-size / 2 + 10, size / 2 - 10),
			Z = center.Z + rng:Range(-size / 2 + 10, size / 2 - 10),
		}
		if Geometry.Distance(p, center) > 60 and math.abs(p.X - entrance.X) > 14 then
			local rockHeight = rng:Range(12, height - 6)
			Build.Box(
				model,
				Build.At(p, floorY + rockHeight / 2, rng:Range(0, math.pi))
					* CFrame.Angles(rng:Range(-0.1, 0.1), 0, rng:Range(-0.12, 0.12)),
				Vector3.new(rng:Range(8, 18), rockHeight, rng:Range(8, 16)),
				rng:Pick({ "#9A8870", "#8A7962", "#A49277" }),
				"Rock",
				{ Name = "RockFormation" }
			)
			placed += 1
		end
	end
	for _ = 1, 24 do
		local p = {
			X = center.X + rng:Range(-size / 2 + 6, size / 2 - 6),
			Z = center.Z + rng:Range(-size / 2 + 6, size / 2 - 6),
		}
		if Geometry.Distance(p, center) > 35 then
			Build.Ball(model, Vector3.new(p.X, floorY + 0.8, p.Z), rng:Range(2, 5), "#9A8870", "Rock")
		end
	end

	-- Túnel: rampa recta de la entrada (Y = 0) a la pared norte de la galería.
	local tunnelEnd = { X = entrance.X, Z = center.Z - size / 2 - 2 }
	local run = tunnelEnd.Z - entrance.Z
	local drop = -floorY
	local slope = math.atan2(drop, run)
	local length = math.sqrt(run * run + drop * drop)
	local mid = { X = entrance.X, Z = (entrance.Z + tunnelEnd.Z) / 2 }
	local tilt = CFrame.Angles(slope, 0, 0)
	local tunnel = Build.Folder(folder, "Tunnel")
	local base = Build.At(mid, floorY / 2, 0) * tilt
	Build.Box(tunnel, base * CFrame.new(0, -1, 0), Vector3.new(TUNNEL_WIDTH, 2, length + 4), "#7C7466", "Concrete", {
		Name = "Ramp",
	})
	for _, side in { -1, 1 } do
		Build.Box(
			tunnel,
			base * CFrame.new(side * (TUNNEL_WIDTH / 2 + 1), TUNNEL_HEIGHT / 2, 0),
			Vector3.new(2, TUNNEL_HEIGHT + 2, length + 4),
			"#6B5E4E",
			"Rock",
			{
				Name = "TunnelWall",
			}
		)
	end
	Build.Box(
		tunnel,
		base * CFrame.new(0, TUNNEL_HEIGHT + 1, 0),
		Vector3.new(TUNNEL_WIDTH + 4, 2, length + 4),
		"#6B5E4E",
		"Rock",
		{
			Name = "TunnelCeiling",
		}
	)
	-- Escalones pintados en la rampa y luces cada pocos metros.
	for i = 1, math.floor(length / 16) do
		local lamp = Build.Decor(
			tunnel,
			base * CFrame.new(0, TUNNEL_HEIGHT - 0.4, -length / 2 + i * 16),
			Vector3.new(1.4, 0.4, 1.4),
			"#FFE3B0",
			"Neon"
		)
		Build.Light(lamp, { Range = 20, Brightness = 1.2, Color = "#FFD9A0", Always = true })
	end
	-- Tapa a ras de suelo sobre el tramo en el que el túnel pasa por la losa.
	local lidStart = entrance.Z + TUNNEL_HEIGHT / math.tan(slope) + 1
	local lidEnd = entrance.Z + (-ctx.Settings.GroundBottom + TUNNEL_HEIGHT) / math.tan(slope) + 2
	if lidEnd > lidStart then
		Build.Box(
			tunnel,
			Build.CF(entrance.X, -0.5, (lidStart + lidEnd) / 2),
			Vector3.new(TUNNEL_WIDTH + 6, 1, lidEnd - lidStart),
			Styles.Dirt,
			"Ground",
			{ Name = "Lid" }
		)
	end
end

local function trainingShop(ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	local rng = lf.Rng
	ground(folder, lf, Styles.Dirt, "Ground")
	fence(folder, lf, 14, Styles.WoodDark, 5)

	-- Tienda de madera: puertas correderas, noren, letrero y farolillos.
	local shopX, shopZ, width, depth = 11, 4, 40, 18
	local height = 11
	Build.Box(
		folder,
		lf.At(shopX, height / 2, shopZ),
		Vector3.new(width, height, depth),
		"#5E4A38",
		"WoodPlanks",
		{ Name = "Shop" }
	)
	local roofFrame = lf.Frame * CFrame.new(shopX, 0, shopZ)
	local rise = 5
	for _, sign in { -1, 1 } do
		Build.Part(folder, {
			Name = "Roof",
			Class = "WedgePart",
			CFrame = roofFrame
				* CFrame.new(0, height + rise / 2, sign * (depth / 4 + 0.6))
				* CFrame.Angles(0, if sign < 0 then 0 else math.pi, 0),
			Size = Vector3.new(width + 3, rise, depth / 2 + 1.2),
			Color = "#2E3238",
			Material = "Slate",
		})
	end
	for i = -1, 1 do
		window(folder, lf.At(shopX + i * 8, 3.8, shopZ - depth / 2 - 0.1), Vector3.new(7, 7.2, 0.2), rng, 1)
	end
	for i = -1, 1 do
		Build.Decor(
			folder,
			lf.At(shopX + i * 2.6, 7.2, shopZ - depth / 2 - 0.4),
			Vector3.new(2.4, 2.6, 0.1),
			"#23324A",
			"Fabric",
			{
				Name = "Noren",
			}
		)
	end
	signBoard(
		folder,
		lf.At(shopX, 9.4, shopZ - depth / 2 - 0.4),
		Vector3.new(16, 2.6, 0.4),
		landmark.Sign or "",
		"#2A1F16",
		"#E8DCC0"
	)
	for _, x in { shopX - width / 2 + 1.5, shopX + width / 2 - 1.5 } do
		Props.Lantern(folder, lf.At(x, 8.5, shopZ - depth / 2 - 1.2).Position)
	end
	Props.Bench(folder, lf.Local(shopX - 12, shopZ - depth / 2 - 3), lf.Direction(0, -1))
	-- Estandarte vertical (nobori).
	local banner = lf.Local(shopX + width / 2 + 2, shopZ - depth / 2 - 3)
	Build.Pillar(folder, banner, 0, 10, 0.25, "#CFCFCF", "Metal", { Decor = true })
	local cloth = Build.Decor(
		folder,
		Build.At(Geometry.Add(banner, lf.Direction(0.9, 0)), 6, math.rad(landmark.Rotation)),
		Vector3.new(1.6, 7, 0.1),
		"#C8342A",
		"Fabric"
	)
	Build.Sign(cloth, "Front", "駄\n菓\n子", { TextColor = "#FFFFFF" })
	-- Vivienda detrás.
	Buildings.House(folder, lf.At(15, 0, 22), 26, 10, rng, { Floors = 1, Wall = "#6B5A48", Roof = "#2E3238" })

	-- Entrada al subsuelo y cartel.
	local entrance = lf.Local(TUNNEL_ENTRANCE.X, TUNNEL_ENTRANCE.Z)
	signBoard(
		folder,
		lf.At(TUNNEL_ENTRANCE.X, 14.2, TUNNEL_ENTRANCE.Z - 0.6),
		Vector3.new(9, 2, 0.3),
		"地下訓練場",
		"#F4EAD0",
		"#3A2A1E"
	)
	buildUnderground(ctx, folder, entrance)

	-- Punto de aparición en el patio.
	local spawnAnchor = ctx.Map.Anchors.Spawn
	Build.Part(folder, {
		Name = "SpawnLocation",
		Class = "SpawnLocation",
		CFrame = Build.CF(spawnAnchor.X, 0.3, spawnAnchor.Z, math.rad(landmark.Rotation + 180)),
		Size = Vector3.new(8, 0.4, 8),
		Color = "#B8A07C",
		Material = "Slate",
		Collide = true,
		Attributes = {},
	})
end

-- Registra el hueco del túnel en la losa (antes de construir el suelo).
local function prepareTrainingShop(ctx: Context, landmark: any): ()
	local data = ctx.Map.Underground
	local entrance = Geometry.ToWorld(TUNNEL_ENTRANCE, landmark.Position, math.rad(landmark.Rotation))
	local run = (data.Center.Z - data.Size / 2 - 2) - entrance.Z
	local slope = math.atan2(-data.FloorY, run)
	local holeLength = (-ctx.Settings.GroundBottom + TUNNEL_HEIGHT) / math.tan(slope) + 4
	table.insert(
		ctx.Holes,
		Geometry.Rect({ X = entrance.X, Z = entrance.Z + holeLength / 2 - 2 }, TUNNEL_WIDTH + 4, holeLength, 0)
	)
	if math.abs(entrance.X - data.Center.X) > 1 then
		ctx.Warn("La galería subterránea debe estar justo al sur de la entrada del túnel")
	end
end

-- Resto de lugares ---------------------------------------------------------------

local function clinic(_ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	ground(folder, lf, Styles.Curb, "Pavement")
	block(folder, lf, 0, 3, 24, 16, 2, "#F2F1EC", 0.6, { "Front", "Back", "Left" })
	-- Tercera planta retranqueada (vivienda) y letrero luminoso.
	block(folder, lf, 3, 6, 16, 10, 3, "#E9E6DE", 0.5, { "Front" })
	window(folder, lf.At(-6, 3.6, 3 - 8.12), Vector3.new(4.5, 7, 0.2), lf.Rng, 1)
	signBoard(folder, lf.At(4, 8.4, 3 - 8.3), Vector3.new(11, 2.2, 0.3), landmark.Sign or "", "#1F5FA0", "#FFFFFF")
	local stand = lf.Local(-10, -10)
	Build.Pillar(folder, stand, 0, 6, 0.3, "#9A9A9A", "Metal", { Decor = true })
	signBoard(
		folder,
		Build.At(stand, 5.2, math.rad(landmark.Rotation)),
		Vector3.new(3.4, 2.2, 0.2),
		"内科\n外科",
		"#C62828",
		"#FFFFFF"
	)
	for _, x in { -2, 2 } do
		Build.Pillar(folder, lf.Local(x - 6, -7.5), 0, 1.4, 1.4, "#8A6E52", "Wood", { Decor = true })
		Build.Ball(folder, lf.At(x - 6, 2, -7.5).Position, 2, "#4E8C3A", "Grass")
	end
end

local function house(ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	Buildings.House(
		folder,
		lf.At(0, 0, 2),
		lf.Width - 6,
		lf.Depth - 8,
		ctx.Rng,
		{ Floors = 2, Nameplate = landmark.Sign }
	)
	Buildings.LotWall(folder, lf.Frame, lf.Width, lf.Depth, -(lf.Width - 6) * 0.28)
end

local function dojo(_ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	ground(folder, lf, Styles.Curb, "Pavement")
	block(folder, lf, 0, 2, lf.Width - 6, lf.Depth - 10, 2, "#D9CDB6", 0.5, { "Front", "Back", "Left", "Right" })
	signBoard(
		folder,
		lf.At(0, 8.5, 2 - (lf.Depth - 10) / 2 - 0.3),
		Vector3.new(12, 2.2, 0.3),
		landmark.Sign or "",
		"#1A1A1A",
		"#F2E8D2"
	)
	window(folder, lf.At(0, 3.6, 2 - (lf.Depth - 10) / 2 - 0.12), Vector3.new(5, 7, 0.2), lf.Rng, 1)
end

-- Bloque bajo de apartamentos con pasillo y escalera exteriores.
local function smallApartment(_ctx: Context, folder: any, _landmark: any, lf: LandmarkFrame): ()
	local width, depth = lf.Width - 6, lf.Depth - 10
	Build.Box(folder, lf.At(0, 9, 2), Vector3.new(width, 18, depth), "#D8CFC0", "Plaster", { Name = "Building" })
	Build.Decor(folder, lf.At(0, 18.3, 2), Vector3.new(width + 1, 0.6, depth + 1), "#5A5F66", "Metal")
	local front = 2 - depth / 2
	Build.Box(
		folder,
		lf.At(0, 9, front - 1.6),
		Vector3.new(width, 0.5, 3.2),
		"#9A968E",
		"Concrete",
		{ Name = "Corridor" }
	)
	Build.Decor(folder, lf.At(0, 10.6, front - 3.1), Vector3.new(width, 2.6, 0.2), "#E8E8E4", "Metal")
	Build.Part(folder, {
		Name = "Stairs",
		Class = "WedgePart",
		CFrame = lf.At(width / 2 + 2.5, 4.5, front - 1.6) * CFrame.Angles(0, math.rad(-90), 0),
		Size = Vector3.new(3.2, 9, 14),
		Color = "#8C8F94",
		Material = "DiamondPlate",
	})
	for floor = 0, 1 do
		for i = 0, 3 do
			local x = -width / 2 + width / 8 + i * width / 4
			Build.Decor(
				folder,
				lf.At(x, floor * 9 + 3.6, front - 0.1),
				Vector3.new(2.6, 7, 0.2),
				"#7B5E44",
				"Wood",
				{ Name = "Door" }
			)
			window(folder, lf.At(x + 3, floor * 9 + 5, front - 0.1), Vector3.new(2, 2.2, 0.2), lf.Rng, 0.6)
			window(folder, lf.At(x, floor * 9 + 5, 2 + depth / 2 + 0.1), Vector3.new(4.5, 3.5, 0.2), lf.Rng, 0.55)
		end
	end
	for i = 1, 3 do
		Props.Bicycle(folder, lf.Local(-width / 2 + i * 2, front - 6), lf.Direction(1, 0))
	end
end

-- Hospital abandonado: paneles de pared con huecos, forjados rotos,
-- escombros, valla y una luz que parpadea.
local function ruins(_ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	local rng = lf.Rng
	ground(folder, lf, "#7C7A6E", "Ground")
	local floors, width, depth = 4, 56, 30
	local cz = lf.Depth / 2 - depth / 2 - 6
	local panel = 8
	for floor = 0, floors - 1 do
		local y = floor * FLOOR
		for _, slab in { { -width / 4, width / 2 }, { width / 4, width / 2 } } do
			if not (floor > 0 and rng:Chance(0.25)) then
				Build.Box(
					folder,
					lf.At(slab[1], y + 0.4, cz),
					Vector3.new(slab[2], 0.8, depth),
					"#6E6C66",
					"Concrete",
					{
						Name = "Slab",
					}
				)
			end
		end
		local function wallRun(fixed: number, alongX: boolean, length: number): ()
			local count = math.floor(length / panel)
			for i = 0, count - 1 do
				local offset = -length / 2 + panel * (i + 0.5)
				local isDoor = floor == 0 and alongX and fixed < 0 and math.abs(offset) < panel
				if not isDoor and not rng:Chance(0.22 + floor * 0.06) then
					local x = if alongX then offset else fixed
					local z = if alongX then cz + fixed else cz + offset
					local size = if alongX
						then Vector3.new(panel, FLOOR - 0.8, 1)
						else Vector3.new(1, FLOOR - 0.8, panel)
					Build.Box(
						folder,
						lf.At(x, y + 0.8 + (FLOOR - 0.8) / 2, z),
						size,
						rng:Pick({ "#8C8A82", "#7A7872", "#9A968C" }),
						"Concrete",
						{
							Name = "WallPanel",
						}
					)
					-- Ventana vacía (oscura) en algunos paneles.
					if rng:Chance(0.5) then
						local inset = if alongX then Vector3.new(4, 3.4, 1.1) else Vector3.new(1.1, 3.4, 4)
						Build.Decor(folder, lf.At(x, y + 5.6, z), inset, "#141414", "SmoothPlastic")
					end
				end
			end
		end
		wallRun(-depth / 2, true, width)
		wallRun(depth / 2, true, width)
		wallRun(-width / 2, false, depth)
		wallRun(width / 2, false, depth)
	end
	-- Escombros, maleza y valla con carteles.
	for _ = 1, 26 do
		local x = rng:Range(-lf.Width / 2 + 4, lf.Width / 2 - 4)
		local z = rng:Range(cz - depth / 2 - 8, cz + depth / 2 + 4)
		if rng:Chance(0.5) then
			Build.Decor(
				folder,
				lf.At(x, 0.8, z) * CFrame.Angles(rng:Range(-0.4, 0.4), rng:Range(0, 3), rng:Range(-0.4, 0.4)),
				Vector3.new(rng:Range(1.5, 4), rng:Range(1, 2.5), rng:Range(1.5, 4)),
				"#77756E",
				"Concrete"
			)
		else
			Props.Bush(folder, lf.Local(x, z), rng)
		end
	end
	fence(folder, lf, 12, "#6F7A70", 7, 0.35)
	local warning = lf.Local(-10, -lf.Depth / 2 + 1.5)
	signBoard(
		folder,
		Build.At(warning, 4, math.rad(landmark.Rotation)),
		Vector3.new(6, 2, 0.2),
		"立入禁止",
		"#C62828",
		"#F2F2F2"
	)
	signBoard(
		folder,
		lf.At(0, FLOOR * floors - 3, cz - depth / 2 - 0.7),
		Vector3.new(14, 3, 0.4),
		landmark.Sign or "",
		"#3A3A3A",
		"#A8A49A"
	)
	local bulb =
		Build.Decor(folder, lf.At(6, 8, cz - depth / 2 - 1.2), Vector3.new(0.8, 0.8, 0.8), "#FFF1C4", "SmoothPlastic", {
			Tags = { WorldTags.Flicker },
		})
	Build.Light(bulb, { Range = 18, Brightness = 1.4, Color = "#FFE0A0" })
end

local function schoolBuilding(folder: any, lf: LandmarkFrame, x: number, z: number, width: number, floors: number): ()
	local depth = 20
	block(folder, lf, x, z, width, depth, floors, "#EAE6DC", 0.15, { "Front", "Back" })
	local roof = floors * FLOOR
	-- Valla de la azotea y caseta de escalera.
	for _, spec in
		{
			{ 0, -depth / 2, width, 0.2 },
			{ 0, depth / 2, width, 0.2 },
			{ -width / 2, 0, 0.2, depth },
			{ width / 2, 0, 0.2, depth },
		}
	do
		Build.Box(
			folder,
			lf.At(x + spec[1], roof + 3, z + spec[2]),
			Vector3.new(spec[3], 5, spec[4]),
			"#9FB0A6",
			"Metal",
			{
				Name = "RooftopFence",
				Transparency = 0.45,
				Shadow = false,
			}
		)
	end
	Build.Box(
		folder,
		lf.At(x + width / 2 - 8, roof + 4.5, z),
		Vector3.new(8, 9, 8),
		"#DAD5CA",
		"Concrete",
		{ Name = "RooftopStairs" }
	)
	Build.Decor(folder, lf.At(x + width / 2 - 8, roof + 3.5, z - 4.1), Vector3.new(3, 7, 0.2), "#5A6470", "Metal")
	clock(folder, lf.At(x, roof - 3, z - depth / 2 - 0.3), 4)
	Build.Decor(folder, lf.At(x, 8, z - depth / 2 - 2.2), Vector3.new(12, 0.5, 4.4), "#8E8E8A", "Concrete")
end

-- Patio con pista, porterías, verja con placa y cerezos.
local function schoolGrounds(folder: any, lf: LandmarkFrame, sign: string?, yardDepth: number): ()
	local yardZ = -lf.Depth / 2 + yardDepth / 2 + 2
	Build.Box(
		folder,
		lf.At(0, 0.12, yardZ),
		Vector3.new(lf.Width - 6, 0.24, yardDepth),
		"#B89D74",
		"Ground",
		{ Name = "Yard", Shadow = false }
	)
	local trackW, trackD = lf.Width - 20, yardDepth - 10
	for _, spec in
		{
			{ 0, -trackD / 2, trackW, 0.4 },
			{ 0, trackD / 2, trackW, 0.4 },
			{ -trackW / 2, 0, 0.4, trackD },
			{ trackW / 2, 0, 0.4, trackD },
		}
	do
		Build.Decor(
			folder,
			lf.At(spec[1], 0.26, yardZ + spec[2]),
			Vector3.new(spec[3], 0.05, spec[4]),
			"#F4F4F0",
			"SmoothPlastic"
		)
	end
	for _, side in { -1, 1 } do
		local goal = lf.At(side * (trackW / 2 - 4), 0, yardZ)
		for _, dz in { -4, 4 } do
			Build.Decor(folder, goal * CFrame.new(0, 3, dz), Vector3.new(0.4, 6, 0.4), "#F4F4F4", "Metal")
		end
		Build.Decor(folder, goal * CFrame.new(0, 6, 0), Vector3.new(0.4, 0.4, 8.4), "#F4F4F4", "Metal")
	end
	fence(folder, lf, 14, "#8FA095", 6, 0.4)
	for _, x in { -9, 9 } do
		local pillar =
			Build.Box(folder, lf.At(x, 3.5, -lf.Depth / 2 + 0.5), Vector3.new(2.4, 7, 2.4), "#A8A49A", "Concrete", {
				Name = "GatePillar",
			})
		if sign ~= nil and x < 0 then
			local plate = Build.Decor(
				folder,
				pillar.CFrame * CFrame.new(0, 0.5, -1.25),
				Vector3.new(1.6, 5, 0.1),
				"#E8E2D0",
				"Wood"
			)
			local chars = {}
			for _, code in utf8.codes(sign) do
				table.insert(chars, utf8.char(code))
			end
			Build.Sign(
				plate,
				"Front",
				table.concat(chars, "\n"),
				{ TextColor = "#1A1A1A", Background = "#E8E2D0", Font = "Antique" }
			)
		end
	end
	for i = 1, 6 do
		local x = -lf.Width / 2 + 5 + (i - 1) * (lf.Width - 10) / 5
		if math.abs(x) > 12 then
			Props.Tree(folder, lf.Local(x, -lf.Depth / 2 + 5), lf.Rng, "Cherry")
		end
	end
end

local function highSchool(_ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	local yardDepth = lf.Depth - 36
	schoolGrounds(folder, lf, landmark.Sign, yardDepth)
	local buildingZ = lf.Depth / 2 - 14
	schoolBuilding(folder, lf, -12, buildingZ, lf.Width - 36, 4)
	-- Gimnasio con tejado curvo.
	local gymX = lf.Width / 2 - 13
	Build.Box(folder, lf.At(gymX, 7, buildingZ), Vector3.new(20, 14, 24), "#CFC6B4", "Concrete", { Name = "Gym" })
	for _, sign in { -1, 1 } do
		Build.Part(folder, {
			Name = "GymRoof",
			Class = "WedgePart",
			CFrame = lf.At(gymX + sign * 5.25, 16, buildingZ)
				* CFrame.Angles(0, if sign < 0 then math.rad(-90) else math.rad(90), 0),
			Size = Vector3.new(25, 4, 10.5),
			Color = "#6A7B8C",
			Material = "Metal",
		})
	end
	for i = 1, 6 do
		Props.Bicycle(folder, lf.Local(-lf.Width / 2 + 6 + i * 2.2, -lf.Depth / 2 + yardDepth + 6), lf.Direction(0, 1))
	end
end

local function school(_ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	local yardDepth = lf.Depth - 30
	schoolGrounds(folder, lf, landmark.Sign, yardDepth)
	schoolBuilding(folder, lf, 0, lf.Depth / 2 - 12, lf.Width - 16, 3)
end

local function hospital(ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	ground(folder, lf, Styles.Curb, "Pavement")
	local width, depth, floors = lf.Width - 14, lf.Depth - 24, 7
	block(folder, lf, 0, 6, width, depth, floors, "#F1F1EE", 0.55, { "Front", "Back", "Left", "Right" })
	local roof = floors * FLOOR
	signBoard(
		folder,
		lf.At(0, roof - 3, 6 - depth / 2 - 0.4),
		Vector3.new(20, 3.2, 0.4),
		landmark.Sign or "",
		"#1B4F8F",
		"#FFFFFF"
	)
	local cross = Build.Decor(
		folder,
		lf.At(width / 2 - 5, roof + 4, 6 - depth / 2 + 2),
		Vector3.new(6, 6, 0.6),
		"#FFFFFF",
		"SmoothPlastic",
		{
			Tags = { WorldTags.NightNeon },
		}
	)
	Build.Sign(cross, "Front", "✚", { TextColor = "#D32F2F", Background = "#FFFFFF", Glow = true })
	-- Helipuerto.
	Build.Pillar(folder, lf.Local(-6, 8), roof + 1, 0.2, 18, "#4A4E54", "Concrete", { Decor = true, Name = "Helipad" })
	local letter = Build.Decor(
		folder,
		lf.At(-6, roof + 1.25, 8),
		Vector3.new(8, 0.1, 8),
		"#FFFFFF",
		"SmoothPlastic",
		{ Transparency = 1 }
	)
	Build.Sign(letter, "Top", "H", { TextColor = "#F4F4F4" })
	Build.Decor(folder, lf.At(0, 8, 6 - depth / 2 - 3), Vector3.new(14, 0.6, 6), "#7D8A96", "Metal")
	window(folder, lf.At(0, 3.6, 6 - depth / 2 - 0.12), Vector3.new(8, 7, 0.2), lf.Rng, 1)
	Props.Car(folder, lf.Local(10, 6 - depth / 2 - 8), lf.Direction(1, 0), ctx.Rng, "#F4F4F4")
	Props.BusStop(folder, lf.Local(-16, -lf.Depth / 2 + 3), lf.Direction(0, -1))
end

-- Estación: andenes a los dos lados de la vía, marquesinas, edificio y plaza.
local function station(ctx: Context, folder: any, landmark: any, _lf: LandmarkFrame): ()
	local rng = ctx.Rng
	local railPoint, railDirection = Geometry.ClosestOnPolyline(landmark.Position, ctx.Rail)
	-- -Z local hacia la plaza (el lado de la vía donde está la parcela); X a lo largo de la vía.
	local toPlaza = Geometry.Sub(landmark.Position, railPoint)
	local along = toPlaza.X * railDirection.X + toPlaza.Z * railDirection.Z
	local facing = Geometry.Unit(Geometry.Sub(toPlaza, Geometry.Scale(railDirection, along)))
	local frame = Build.At(railPoint, 0, Geometry.YawForLook(facing))
	local function at(x: number, y: number, z: number): any
		return frame * CFrame.new(x, y, z)
	end
	local length = 130
	for _, sign in { -1, 1 } do
		local z = sign * 10.6
		Build.Box(folder, at(0, 1.6, z), Vector3.new(length, 3.2, 10), "#B9B5AA", "Concrete", { Name = "Platform" })
		Build.Decor(folder, at(0, 3.23, z - sign * 4.3), Vector3.new(length, 0.06, 0.9), "#E8C24A", "SmoothPlastic")
		-- Marquesina sobre postes.
		for i = -3, 3 do
			Build.Pillar(
				folder,
				Geometry.Add(railPoint, Geometry.Add(Geometry.Scale(railDirection, i * 16), Geometry.Scale(facing, -z))),
				3.2,
				9,
				0.5,
				"#8A8F95",
				"Metal",
				{ Decor = true }
			)
		end
		Build.Decor(folder, at(0, 12.4, z), Vector3.new(length - 20, 0.5, 11), "#6D7780", "Metal", { Name = "Canopy" })
		-- Rampas en los extremos.
		for _, ramp in { -1, 1 } do
			Build.Part(folder, {
				Name = "PlatformRamp",
				Class = "WedgePart",
				CFrame = at(ramp * (length / 2 + 4), 1.6, z) * CFrame.Angles(0, ramp * math.rad(90), 0),
				Size = Vector3.new(10, 3.2, 8),
				Color = "#A9A59A",
				Material = "Concrete",
			})
		end
		for i = -2, 2 do
			Props.Bench(
				folder,
				Geometry.Add(
					railPoint,
					Geometry.Add(Geometry.Scale(railDirection, i * 18 + 8), Geometry.Scale(facing, -z - sign * 2))
				),
				Geometry.Scale(facing, sign)
			)
		end
		local nameplate = Build.Decor(folder, at(10, 8, z), Vector3.new(8, 1.6, 0.2), "#FFFFFF", "SmoothPlastic")
		Build.Sign(
			nameplate,
			"Front",
			landmark.Sign or "",
			{ TextColor = "#1A1A1A", Background = "#FFFFFF", Glow = true }
		)
		Build.Sign(
			nameplate,
			"Back",
			landmark.Sign or "",
			{ TextColor = "#1A1A1A", Background = "#FFFFFF", Glow = true }
		)
	end
	-- Edificio de la estación del lado de la plaza.
	local buildingZ = -26
	Build.Box(folder, at(0, 7, buildingZ), Vector3.new(46, 14, 18), "#E4DED2", "Concrete", { Name = "StationBuilding" })
	window(folder, at(0, 4, buildingZ - 9.1), Vector3.new(30, 7.5, 0.2), rng, 1)
	signBoard(folder, at(0, 11.4, buildingZ - 9.3), Vector3.new(24, 3, 0.4), landmark.Sign or "", "#FFFFFF", "#1E4E8C")
	clock(folder, at(18, 11, buildingZ - 9.3), 2.6)
	Build.Decor(folder, at(0, 8, buildingZ - 11), Vector3.new(34, 0.5, 4), "#6D7780", "Metal")
	-- Plaza: pavimento, reloj, parada de autobús, taxis, bicis y máquinas.
	local plazaZ = buildingZ - 22
	Build.Box(
		folder,
		at(0, 0.3, plazaZ),
		Vector3.new(70, 0.4, 26),
		"#C9C2B2",
		"Pavement",
		{ Name = "Plaza", Shadow = false }
	)
	local clockPole = Geometry.Add(railPoint, Geometry.Scale(facing, -plazaZ))
	Build.Pillar(folder, clockPole, 0.5, 10, 0.5, "#4A4F55", "Metal", { Decor = true })
	clock(folder, Build.At(clockPole, 10.5, Geometry.YawForLook(facing)), 2.4)
	local function plazaPoint(x: number, z: number): Point
		local position = at(x, 0, z).Position
		return { X = position.X, Z = position.Z }
	end
	Props.BusStop(folder, plazaPoint(-24, plazaZ - 8), facing)
	Props.Car(folder, plazaPoint(20, plazaZ - 6), railDirection, rng, "#F2C230")
	Props.Car(folder, plazaPoint(20, plazaZ + 2), railDirection, rng, "#2E8B57")
	for i = 1, 8 do
		Props.Bicycle(folder, plazaPoint(-30 + i * 1.8, plazaZ + 9), facing)
	end
	Props.VendingMachine(folder, plazaPoint(24, buildingZ - 11), facing, rng)
	Props.VendingMachine(folder, plazaPoint(27.4, buildingZ - 11), facing, rng)
	for _, x in { -12, 12 } do
		Props.Tree(folder, plazaPoint(x, plazaZ), rng, "Leafy")
	end
	Props.PostBox(folder, plazaPoint(-8, plazaZ - 10), facing)
end

local function mall(ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	ground(folder, lf, Styles.AsphaltLane, "Asphalt")
	local width, depth = lf.Width - 8, 28
	local z = lf.Depth / 2 - depth / 2 - 2
	block(folder, lf, 0, z, width, depth, 3, "#EDE9E0", 0.9, { "Front", "Left", "Right" })
	signBoard(
		folder,
		lf.At(0, 3 * FLOOR + 3, z - depth / 2 + 1),
		Vector3.new(26, 5, 0.6),
		landmark.Sign or "",
		"#FFFFFF",
		"#D2452D"
	)
	for i = 0, 4 do
		local x = -width / 2 + 6 + i * 11
		Build.Decor(
			folder,
			lf.At(x, 0.25, -lf.Depth / 2 + 12),
			Vector3.new(0.4, 0.05, 12),
			Styles.RoadLine,
			"SmoothPlastic"
		)
		if ctx.Rng:Chance(0.7) then
			Props.Car(folder, lf.Local(x + 5.5, -lf.Depth / 2 + 12), lf.Direction(0, 1), ctx.Rng)
		end
	end
end

local function supermarket(ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	ground(folder, lf, Styles.AsphaltLane, "Asphalt")
	local depth = lf.Depth - 16
	local z = lf.Depth / 2 - depth / 2 - 1
	block(folder, lf, 0, z, lf.Width - 6, depth, 1, "#F2EFE6", 1, { "Front" })
	signBoard(
		folder,
		lf.At(0, 8.6, z - depth / 2 - 0.4),
		Vector3.new(16, 2.4, 0.4),
		landmark.Sign or "",
		"#FFFFFF",
		"#2E8B57"
	)
	for i = 1, 2 do
		Props.Car(folder, lf.Local(-10 + i * 9, -lf.Depth / 2 + 7), lf.Direction(0, 1), ctx.Rng)
	end
	for i = 1, 5 do
		Props.Bicycle(folder, lf.Local(lf.Width / 2 - 4 - i * 1.8, -lf.Depth / 2 + 12), lf.Direction(0, -1))
	end
end

-- Galería comercial cubierta: dos filas de tiendas y techo translúcido.
local function shopStreet(ctx: Context, folder: any, landmark: any, lf: LandmarkFrame): ()
	local rng = ctx.Rng
	Build.Box(
		folder,
		lf.At(0, 0.15, 0),
		Vector3.new(8, 0.3, lf.Depth),
		"#CFC6B5",
		"Pavement",
		{ Name = "Arcade", Shadow = false }
	)
	local shopDepth = (lf.Width - 8) / 2
	local count = math.floor(lf.Depth / 12)
	for _, side in { -1, 1 } do
		for i = 0, count - 1 do
			local z = -lf.Depth / 2 + 6 + i * 12
			local x = side * (4 + shopDepth / 2)
			Build.Box(
				folder,
				lf.At(x, 6, z),
				Vector3.new(shopDepth, 12, 11.6),
				rng:Pick(Styles.HouseWalls),
				"Plaster",
				{ Name = "ArcadeShop" }
			)
			window(folder, lf.At(side * 4.1, 3.2, z), Vector3.new(0.2, 5.4, 9), rng, 0.95)
			local board =
				Build.Decor(folder, lf.At(side * 4.2, 7.3, z), Vector3.new(0.2, 1.8, 9), "#F4F1E8", "SmoothPlastic")
			Build.Sign(board, if side < 0 then "Right" else "Left", rng:Pick(Styles.ShopSigns), {
				TextColor = rng:Pick(Styles.Awnings),
				Background = "#F4F1E8",
				Glow = true,
			})
		end
	end
	-- Techo arqueado translúcido con costillas y farolillos.
	Build.Decor(folder, lf.At(0, 13, 0), Vector3.new(9, 0.3, lf.Depth), "#DCE8EE", "Glass", { Transparency = 0.45 })
	for i = 0, count do
		local z = -lf.Depth / 2 + i * 12
		Build.Decor(folder, lf.At(0, 13.3, z), Vector3.new(9.4, 0.5, 0.5), "#8A9096", "Metal")
		if i % 2 == 1 then
			Props.Lantern(folder, lf.At(0, 10.5, z).Position)
		end
	end
	for _, z in { -lf.Depth / 2 - 0.5, lf.Depth / 2 + 0.5 } do
		local gate = Build.Decor(
			folder,
			lf.At(0, 15, z),
			Vector3.new(12, 3, 0.4),
			"#B8352E",
			"SmoothPlastic",
			{ Name = "ArcadeGate" }
		)
		Build.Sign(
			gate,
			if z < 0 then "Front" else "Back",
			landmark.Sign or "",
			{ TextColor = "#FFF4D6", Background = "#B8352E", Glow = true }
		)
		for _, x in { -5.5, 5.5 } do
			Build.Box(folder, lf.At(x, 7, z), Vector3.new(0.8, 14, 0.8), "#8A9096", "Metal", { Name = "GatePost" })
		end
	end
end

-- Santuario: torii, camino de piedra, capilla, faroles y árbol sagrado.
local function shrine(ctx: Context, folder: any, _landmark: any, lf: LandmarkFrame): ()
	local rng = ctx.Rng
	ground(folder, lf, "#B9B2A1", "Pebble")
	local toriiZ = -lf.Depth / 2 + 3
	for _, x in { -4, 4 } do
		Build.Pillar(folder, lf.Local(x, toriiZ), 0, 11, 0.9, "#C8352A", "SmoothPlastic", { Name = "ToriiPillar" })
	end
	Build.Box(
		folder,
		lf.At(0, 11.4, toriiZ),
		Vector3.new(12, 0.9, 1.3),
		"#2A2A2A",
		"SmoothPlastic",
		{ Name = "Kasagi" }
	)
	Build.Decor(folder, lf.At(0, 10.5, toriiZ), Vector3.new(11, 0.6, 1), "#C8352A", "SmoothPlastic")
	Build.Decor(folder, lf.At(0, 8.6, toriiZ), Vector3.new(9.6, 0.6, 0.6), "#C8352A", "SmoothPlastic")
	for i = 0, 7 do
		Build.Decor(folder, lf.At(0, 0.25, toriiZ + 4 + i * 3.2), Vector3.new(3, 0.2, 2.6), "#8F8B80", "Slate")
	end
	local hallZ = lf.Depth / 2 - 10
	Build.Box(folder, lf.At(0, 1, hallZ), Vector3.new(12, 2, 10), "#8A8478", "Slate", { Name = "Platform" })
	Build.Box(folder, lf.At(0, 5, hallZ), Vector3.new(9, 6, 7), "#8A5A3A", "Wood", { Name = "Hall" })
	for _, sign in { -1, 1 } do
		Build.Part(folder, {
			Name = "HallRoof",
			Class = "WedgePart",
			CFrame = lf.At(0, 9.5, hallZ + sign * 2.6) * CFrame.Angles(0, if sign < 0 then 0 else math.pi, 0),
			Size = Vector3.new(12, 3, 5.2),
			Color = "#3A3F44",
			Material = "Slate",
		})
	end
	Build.Decor(
		folder,
		lf.At(0, 2.8, hallZ - 5.2),
		Vector3.new(2.6, 1.4, 1.4),
		"#6B4A2E",
		"Wood",
		{ Name = "OfferingBox" }
	)
	for _, x in { -3.5, 3.5 } do
		local lantern = lf.Local(x, hallZ - 9)
		Build.Pillar(folder, lantern, 0, 3, 0.9, "#9A968C", "Slate", { Decor = true })
		local head = Build.Decor(folder, Build.At(lantern, 3.7, 0), Vector3.new(1.6, 1.4, 1.6), "#A7A399", "Slate", {
			Tags = { WorldTags.NightNeon },
		})
		Build.Light(head, { Range = 10, Brightness = 0.9, Color = "#FFC98A" })
		Build.Decor(folder, Build.At(lantern, 4.6, 0), Vector3.new(2.2, 0.5, 2.2), "#8F8B80", "Slate")
	end
	-- Árbol sagrado con cuerda (shimenawa).
	local tree = lf.Local(-lf.Width / 2 + 7, hallZ - 4)
	Props.Tree(folder, tree, rng, "Leafy")
	Build.Decor(
		folder,
		Build.At(tree, 3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(0.5, 1.6, 1.6),
		"#D8C39A",
		"Fabric",
		{
			Shape = "Cylinder",
		}
	)
	for _ = 1, 8 do
		local x = rng:Range(-lf.Width / 2 + 3, lf.Width / 2 - 3)
		local z = rng:Range(-lf.Depth / 2 + 8, lf.Depth / 2 - 3)
		if math.abs(x) > 8 then
			Props.Tree(folder, lf.Local(x, z), rng, rng:Pick({ "Pine", "Leafy", "Maple" }))
		end
	end
end

-- Tribuna en ruinas del antiguo hipódromo: gradas rotas, pilares caídos y
-- torres de luz. Delante queda una explanada abierta.
local function racecourseRuins(ctx: Context, folder: any, _landmark: any, lf: LandmarkFrame): ()
	local rng = ctx.Rng
	ground(folder, lf, "#9C8566", "Ground")
	local standZ = lf.Depth / 2 - 14
	local length = lf.Width - 20
	for step = 0, 5 do
		local pieces = 6
		for i = 0, pieces - 1 do
			if not rng:Chance(0.2 + step * 0.05) then
				local x = -length / 2 + length / pieces * (i + 0.5)
				Build.Box(
					folder,
					lf.At(x, 1 + step * 2, standZ - 10 + step * 4),
					Vector3.new(length / pieces - 0.4, 2 + step * 4, 4),
					"#8E8A80",
					"Concrete",
					{
						Name = "Grandstand",
					}
				)
			end
		end
	end
	for i = 0, 4 do
		local x = -length / 2 + i * length / 4
		if rng:Chance(0.6) then
			Build.Box(
				folder,
				lf.At(x, 11, standZ + 12),
				Vector3.new(1.6, 22, 1.6),
				"#7A766E",
				"Concrete",
				{ Name = "Column" }
			)
		else
			Build.Box(
				folder,
				lf.At(x + rng:Range(-4, 4), 1, standZ + 4) * CFrame.Angles(0, rng:Range(0, math.pi), math.rad(88)),
				Vector3.new(1.6, 20, 1.6),
				"#7A766E",
				"Concrete",
				{
					Name = "FallenColumn",
				}
			)
		end
	end
	Build.Box(
		folder,
		lf.At(length / 6, 22.5, standZ + 6) * CFrame.Angles(math.rad(12), 0, math.rad(4)),
		Vector3.new(length / 2, 1, 18),
		"#6E6A62",
		"Concrete",
		{
			Name = "BrokenRoof",
		}
	)
	for _ = 1, 30 do
		local x = rng:Range(-lf.Width / 2 + 4, lf.Width / 2 - 4)
		local z = rng:Range(-lf.Depth / 2 + 4, standZ - 12)
		if math.abs(x) > 18 or math.abs(z) > 18 then
			Build.Decor(
				folder,
				lf.At(x, 0.8, z) * CFrame.Angles(rng:Range(-0.5, 0.5), rng:Range(0, 3), rng:Range(-0.5, 0.5)),
				Vector3.new(rng:Range(1.5, 5), rng:Range(1, 3), rng:Range(1.5, 5)),
				"#7F7B72",
				"Concrete"
			)
		end
	end
	for _, x in { -lf.Width / 2 + 5, lf.Width / 2 - 5 } do
		local base = lf.Local(x, -lf.Depth / 2 + 6)
		Build.Pillar(folder, base, 0, 30, 1.2, "#6B5E52", "CorrodedMetal", { Name = "LightTower" })
		local head =
			Build.Decor(folder, Build.At(base, 30.5, 0), Vector3.new(5, 2.5, 1.2), "#4C4A46", "CorrodedMetal", {
				Tags = if x < 0 then { WorldTags.Flicker } else nil,
			})
		if x < 0 then
			Build.Light(head, { Range = 40, Brightness = 1.3, Color = "#FFE7B8" })
		end
	end
	for _ = 1, 10 do
		Props.Bush(
			folder,
			lf.Local(rng:Range(-lf.Width / 2 + 3, lf.Width / 2 - 3), rng:Range(-lf.Depth / 2 + 3, lf.Depth / 2 - 3)),
			rng
		)
	end
end

local BUILDERS: { [string]: (Context, any, any, LandmarkFrame) -> () } = {
	TrainingShop = trainingShop,
	Clinic = clinic,
	House = house,
	Dojo = dojo,
	SmallApartment = smallApartment,
	Ruins = ruins,
	HighSchool = highSchool,
	School = school,
	Hospital = hospital,
	Station = station,
	Mall = mall,
	Supermarket = supermarket,
	ShopStreet = shopStreet,
	Shrine = shrine,
	RacecourseRuins = racecourseRuins,
}

-- Antes del suelo: huecos que necesitan algunos lugares.
function Landmarks.Prepare(ctx: Context): ()
	for _, landmark in ctx.Map.Landmarks do
		if landmark.Kind == "TrainingShop" then
			prepareTrainingShop(ctx, landmark)
		end
	end
end

function Landmarks.Build(ctx: Context): ()
	for _, landmark in ctx.Map.Landmarks do
		local builder = BUILDERS[landmark.Kind]
		if builder == nil then
			ctx.Warn(`Tipo de lugar sin constructor: {landmark.Kind} ({landmark.Id})`)
		else
			local folder = Build.Folder(ctx.Folder("Landmarks"), landmark.Id)
			folder:SetAttribute("DisplayName", landmark.DisplayName)
			builder(ctx, folder, landmark, frameOf(ctx, landmark))
		end
	end
end

return Landmarks
