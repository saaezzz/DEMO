--!strict

-- Tipos de edificio del relleno urbano. Cada función recibe `frame` (CFrame
-- en el suelo, con la fachada mirando a -Z local) y el tamaño de la planta.
-- Las ventanas llevan la etiqueta Window: de noche el cliente enciende las
-- que tienen Lit = true.

local roblox = require("@lune/roblox")

local Build = require("./Build")
local Props = require("./Props")
local Rng = require("./Rng")
local Styles = require("./Styles")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Rng = Rng.Rng

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local FLOOR_HEIGHT = 9

local Buildings = {}

-- Punto del suelo a (x, z) en el marco local del edificio.
local function groundPoint(frame: any, x: number, z: number): { X: number, Z: number }
	local position = (frame * CFrame.new(x, 0, z)).Position
	return { X = position.X, Z = position.Z }
end

-- Ventana en una fachada: `frame * offset` es su centro y `size` su tamaño.
local function window(folder: any, cframe: any, size: any, rng: Rng, litChance: number?, material: string?): any
	return Build.Decor(folder, cframe, size, Styles.WindowDay, material or "Glass", {
		Name = "Window",
		Reflectance = 0.15,
		Tags = { WorldTags.Window },
		Attributes = { [WorldTags.Attributes.Lit] = rng:Chance(litChance or 0.55) },
	})
end

-- Tejado a dos aguas con la cumbrera a lo largo del ancho (eje X).
local function gableRoof(folder: any, frame: any, width: number, depth: number, top: number, color: string): number
	local rise = math.min(depth * 0.32, 6)
	local half = depth / 2 + 0.6
	local size = Vector3.new(width + 1.4, rise, half)
	Build.Part(folder, {
		Name = "Roof",
		Class = "WedgePart",
		CFrame = frame * CFrame.new(0, top + rise / 2, -half / 2),
		Size = size,
		Color = color,
		Material = "Slate",
	})
	Build.Part(folder, {
		Name = "Roof",
		Class = "WedgePart",
		CFrame = frame * CFrame.new(0, top + rise / 2, half / 2) * CFrame.Angles(0, math.pi, 0),
		Size = size,
		Color = color,
		Material = "Slate",
	})
	return rise
end

export type HouseOptions = {
	Floors: number?,
	Wall: string?,
	Roof: string?,
	-- Nombre en la placa junto a la puerta (表札).
	Nameplate: string?,
	-- Aparcamiento con coche al lado (la parcela debe tener sitio a +X).
	Carport: boolean?,
}

-- Casa unifamiliar japonesa de 1 a 3 plantas.
function Buildings.House(folder: any, frame: any, width: number, depth: number, rng: Rng, options: HouseOptions?): ()
	local opts = options or {}
	local model = Build.Folder(folder, "House")
	local floors = opts.Floors or (if rng:Chance(0.12) then 1 elseif rng:Chance(0.12) then 3 else 2)
	local height = floors * FLOOR_HEIGHT
	local wall = opts.Wall or rng:Pick(Styles.HouseWalls)

	Build.Box(model, frame * CFrame.new(0, height / 2, 0), Vector3.new(width, height, depth), wall, "Plaster", {
		Name = "Walls",
	})
	Build.Decor(model, frame * CFrame.new(0, 0.6, 0), Vector3.new(width + 0.3, 1.2, depth + 0.3), "#6E6B66", "Concrete")

	if rng:Chance(0.72) then
		local rise = gableRoof(model, frame, width, depth, height, opts.Roof or rng:Pick(Styles.Roofs))
		if rng:Chance(0.12) then
			-- Placas solares en el faldón delantero.
			local slope = math.atan2(rise, depth / 2)
			Build.Decor(
				model,
				frame * CFrame.new(0, height + rise / 2 + 0.35, -depth / 4) * CFrame.Angles(slope, 0, 0),
				Vector3.new(width * 0.6, 0.2, depth / 2 * 0.8),
				"#223A5E",
				"Glass",
				{ Reflectance = 0.3 }
			)
		end
	else
		Build.Decor(
			model,
			frame * CFrame.new(0, height + 0.3, 0),
			Vector3.new(width + 0.4, 0.6, depth + 0.4),
			"#8A8780",
			"Concrete"
		)
		if rng:Chance(0.5) then
			Build.Decor(
				model,
				frame * CFrame.new(width * 0.2, height + 1.6, depth * 0.1),
				Vector3.new(2.5, 2, 2.5),
				"#D0CEC8",
				"Metal"
			)
		end
	end
	if rng:Chance(0.3) then
		Build.Decor(
			model,
			frame * CFrame.new(width * 0.3, height + 5, depth * 0.2),
			Vector3.new(0.15, 6, 0.15),
			"#6A6A6A",
			"Metal"
		)
	end

	-- Puerta con tejadillo y ventanas por planta.
	Build.Decor(
		model,
		frame * CFrame.new(-width * 0.28, 3.6, -depth / 2 - 0.12),
		Vector3.new(3, 7.2, 0.3),
		Styles.WoodDark,
		"Wood",
		{
			Name = "Door",
		}
	)
	Build.Decor(
		model,
		frame * CFrame.new(-width * 0.28, 7.8, -depth / 2 - 0.7),
		Vector3.new(4.2, 0.3, 1.4),
		"#5A5A5A",
		"Metal"
	)
	if opts.Nameplate ~= nil then
		local plate = Build.Decor(
			model,
			frame * CFrame.new(-width * 0.28 + 2.4, 5, -depth / 2 - 0.12),
			Vector3.new(1.2, 1.6, 0.1),
			"#E8E0CC",
			"Wood"
		)
		Build.Sign(plate, "Front", opts.Nameplate, { TextColor = "#1A1A1A", Background = "#E8E0CC", Font = "Antique" })
	end
	for floor = 1, floors do
		local y = (floor - 1) * FLOOR_HEIGHT + 5
		if floor == 1 then
			window(
				model,
				frame * CFrame.new(width * 0.18, y, -depth / 2 - 0.08),
				Vector3.new(width * 0.34, 3.4, 0.2),
				rng
			)
		else
			window(model, frame * CFrame.new(0, y, -depth / 2 - 0.08), Vector3.new(width * 0.62, 3.6, 0.2), rng)
		end
		window(model, frame * CFrame.new(0, y, depth / 2 + 0.08), Vector3.new(width * 0.5, 3.2, 0.2), rng, 0.4)
		local side = if rng:Chance(0.5) then 1 else -1
		window(
			model,
			frame * CFrame.new(side * (width / 2 + 0.08), y, 0),
			Vector3.new(0.2, 3.2, depth * 0.35),
			rng,
			0.4
		)
	end
	if floors >= 2 and rng:Chance(0.35) then
		Build.Decor(
			model,
			frame * CFrame.new(0, FLOOR_HEIGHT + 0.2, -depth / 2 - 1.1),
			Vector3.new(width * 0.7, 0.4, 2.2),
			"#9A978F",
			"Concrete"
		)
		Build.Decor(
			model,
			frame * CFrame.new(0, FLOOR_HEIGHT + 1.8, -depth / 2 - 2.1),
			Vector3.new(width * 0.7, 2.8, 0.2),
			"#E0E0DA",
			"Metal"
		)
	end
	if rng:Chance(0.6) then
		Props.AirConditioner(
			model,
			frame
				* CFrame.new(width / 2 + 0.6, 1.1, rng:Range(-depth / 4, depth / 4))
				* CFrame.Angles(0, -math.pi / 2, 0)
		)
	end
	if opts.Carport then
		local look = frame.LookVector
		Props.Car(model, groundPoint(frame, width / 2 + 4.2, -depth / 2 + 7), { X = look.X, Z = look.Z }, rng)
	end
end

-- Muro bajo de bloques delante de una parcela, con hueco para la entrada.
function Buildings.LotWall(folder: any, frame: any, width: number, depth: number, gateAt: number): ()
	local z = -depth / 2 + 0.3
	local gate = 4.5
	local left = (gateAt - gate / 2) + width / 2
	local right = width / 2 - (gateAt + gate / 2)
	if left > 0.5 then
		Build.Box(
			folder,
			frame * CFrame.new(-width / 2 + left / 2, 1.8, z),
			Vector3.new(left, 3.6, 0.6),
			"#A9A69E",
			"Concrete",
			{
				Name = "BlockWall",
				Shadow = false,
			}
		)
	end
	if right > 0.5 then
		Build.Box(
			folder,
			frame * CFrame.new(width / 2 - right / 2, 1.8, z),
			Vector3.new(right, 3.6, 0.6),
			"#A9A69E",
			"Concrete",
			{
				Name = "BlockWall",
				Shadow = false,
			}
		)
	end
end

-- Bloque de pisos (マンション) con balcones corridos.
function Buildings.Apartment(folder: any, frame: any, width: number, depth: number, rng: Rng, floors: number?): ()
	local model = Build.Folder(folder, "Apartment")
	local count = floors or rng:Int(4, 7)
	local height = count * FLOOR_HEIGHT
	local wall = rng:Pick(Styles.ApartmentWalls)
	Build.Box(model, frame * CFrame.new(0, height / 2, 0), Vector3.new(width, height, depth), wall, "Plaster", {
		Name = "Walls",
	})
	-- Entrada: puerta de cristal y marquesina.
	window(model, frame * CFrame.new(0, 3.5, -depth / 2 - 0.1), Vector3.new(5, 7, 0.2), rng, 1, "Glass")
	Build.Decor(model, frame * CFrame.new(0, 7.6, -depth / 2 - 1.6), Vector3.new(7, 0.4, 3.2), "#6D6D6D", "Metal")
	for floor = 1, count do
		local base = (floor - 1) * FLOOR_HEIGHT
		if floor > 1 then
			window(model, frame * CFrame.new(0, base + 3.6, -depth / 2 - 0.08), Vector3.new(width - 4, 5.6, 0.2), rng)
			Build.Decor(
				model,
				frame * CFrame.new(0, base + 0.25, -depth / 2 - 1.5),
				Vector3.new(width - 1, 0.5, 3),
				wall,
				"Concrete"
			)
			Build.Decor(
				model,
				frame * CFrame.new(0, base + 2, -depth / 2 - 2.9),
				Vector3.new(width - 1, 3, 0.3),
				"#DCE3E8",
				"Glass",
				{
					Transparency = 0.25,
				}
			)
		end
		window(model, frame * CFrame.new(0, base + 5, depth / 2 + 0.08), Vector3.new(width - 6, 3.4, 0.2), rng, 0.45)
	end
	-- Azotea: pretil, depósito de agua y aparatos.
	for _, spec in
		{
			{ 0, -depth / 2, width, 0.5 },
			{ 0, depth / 2, width, 0.5 },
			{ -width / 2, 0, 0.5, depth },
			{ width / 2, 0, 0.5, depth },
		}
	do
		Build.Decor(
			model,
			frame * CFrame.new(spec[1], height + 0.7, spec[2]),
			Vector3.new(spec[3], 1.4, spec[4]),
			wall,
			"Concrete"
		)
	end
	Build.Decor(
		model,
		frame * CFrame.new(width * 0.25, height + 3.5, depth * 0.15) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(4, 4, 4),
		"#BFC5C9",
		"Metal",
		{ Shape = "Cylinder" }
	)
	Build.Decor(
		model,
		frame * CFrame.new(width * 0.25, height + 0.75, depth * 0.15),
		Vector3.new(3, 1.5, 3),
		"#6E6E6E",
		"Metal"
	)
	Props.AirConditioner(model, frame * CFrame.new(-width * 0.25, height + 1, 0))
	-- Escalera exterior en un lateral.
	Build.Box(
		model,
		frame * CFrame.new(width / 2 + 2.6, (height + 3) / 2, depth * 0.2),
		Vector3.new(5, height + 3, 6),
		"#9D9A93",
		"Concrete",
		{
			Name = "StairTower",
		}
	)
	window(
		model,
		frame * CFrame.new(width / 2 + 5.15, height / 2, depth * 0.2),
		Vector3.new(0.2, height - 4, 1.4),
		rng,
		0.8
	)
end

-- Casa-tienda: escaparate, toldo y letrero; vivienda arriba.
function Buildings.Shop(folder: any, frame: any, width: number, depth: number, rng: Rng): ()
	local model = Build.Folder(folder, "Shop")
	local floors = rng:Int(2, 3)
	local height = floors * FLOOR_HEIGHT
	local wall = rng:Pick(Styles.HouseWalls)
	Build.Box(model, frame * CFrame.new(0, height / 2, 0), Vector3.new(width, height, depth), wall, "Plaster", {
		Name = "Walls",
	})
	window(model, frame * CFrame.new(0, 3.2, -depth / 2 - 0.1), Vector3.new(width - 2, 5.6, 0.2), rng, 0.95)
	local awning = rng:Pick(Styles.Awnings)
	Build.Decor(
		model,
		frame * CFrame.new(0, 7.1, -depth / 2 - 1.5) * CFrame.Angles(math.rad(-18), 0, 0),
		Vector3.new(width - 1, 0.25, 3.2),
		awning,
		"Fabric"
	)
	local board = Build.Decor(
		model,
		frame * CFrame.new(0, 8.9, -depth / 2 - 0.2),
		Vector3.new(width - 2, 2, 0.3),
		"#F4F1E8",
		"SmoothPlastic"
	)
	Build.Sign(board, "Front", rng:Pick(Styles.ShopSigns), { TextColor = awning, Background = "#F4F1E8", Glow = true })
	for floor = 2, floors do
		window(
			model,
			frame * CFrame.new(0, (floor - 1) * FLOOR_HEIGHT + 5, -depth / 2 - 0.08),
			Vector3.new(width * 0.6, 3.4, 0.2),
			rng
		)
	end
	if rng:Chance(0.35) then
		-- Letrero vertical luminoso en la esquina.
		local vertical = Build.Decor(
			model,
			frame * CFrame.new(width / 2 - 0.6, height - 4, -depth / 2 - 1),
			Vector3.new(0.6, 6, 2),
			rng:Pick({ "#FF5A5A", "#FFD24A", "#5AD1FF", "#FF7AD9" }),
			"SmoothPlastic",
			{ Tags = { WorldTags.NightNeon } }
		)
		local text = rng:Pick(Styles.ShopSigns)
		local chars = {}
		for _, code in utf8.codes(text) do
			table.insert(chars, utf8.char(code))
		end
		Build.Sign(vertical, "Right", table.concat(chars, "\n"), { TextColor = "#FFFFFF", Glow = true })
	end
	Build.Decor(
		model,
		frame * CFrame.new(0, height + 0.3, 0),
		Vector3.new(width + 0.3, 0.6, depth + 0.3),
		"#8A8780",
		"Concrete"
	)
end

-- Tienda de conveniencia: fachada de cristal muy iluminada y franjas de color.
function Buildings.Konbini(folder: any, frame: any, width: number, depth: number, rng: Rng): ()
	local model = Build.Folder(folder, "Konbini")
	local height = 11
	Build.Box(
		model,
		frame * CFrame.new(0, height / 2, 0),
		Vector3.new(width, height, depth),
		"#F4F4F2",
		"SmoothPlastic",
		{
			Name = "Walls",
		}
	)
	window(model, frame * CFrame.new(0, 3.6, -depth / 2 - 0.1), Vector3.new(width - 2, 6.6, 0.2), rng, 1)
	local stripes = rng:Pick({ { "#2E8B57", "#1E6FB8" }, { "#F08A24", "#2E8B57" }, { "#1E6FB8", "#E03C31" } })
	Build.Decor(
		model,
		frame * CFrame.new(0, 7.8, -depth / 2 - 0.15),
		Vector3.new(width, 0.8, 0.2),
		stripes[1],
		"SmoothPlastic"
	)
	Build.Decor(
		model,
		frame * CFrame.new(0, 8.7, -depth / 2 - 0.15),
		Vector3.new(width, 0.8, 0.2),
		stripes[2],
		"SmoothPlastic"
	)
	local board = Build.Decor(
		model,
		frame * CFrame.new(0, 10, -depth / 2 - 0.15),
		Vector3.new(width * 0.5, 1.6, 0.2),
		"#FFFFFF",
		"SmoothPlastic"
	)
	Build.Sign(board, "Front", "コンビニ  24h", { TextColor = stripes[2], Background = "#FFFFFF", Glow = true })
	local light = Build.Decor(
		model,
		frame * CFrame.new(0, 4, -depth / 2 - 2),
		Vector3.new(1, 0.2, 1),
		"#FFFFFF",
		"SmoothPlastic",
		{
			Transparency = 1,
		}
	)
	Build.Light(light, { Range = 20, Brightness = 1.2, Color = "#EAF4FF" })
	for _, x in { -width / 2 + 2, -width / 2 + 3.6 } do
		Props.TrashBin(model, groundPoint(frame, x, -depth / 2 - 2))
	end
end

-- Torre de oficinas de cristal con una banda iluminable por planta.
function Buildings.Office(folder: any, frame: any, width: number, depth: number, rng: Rng, floors: number?): ()
	local model = Build.Folder(folder, "Office")
	local count = floors or rng:Int(6, 12)
	local floorHeight = 10
	local height = count * floorHeight
	local glass = rng:Pick(Styles.OfficeGlass)
	local frameColor = rng:Pick(Styles.OfficeFrame)
	Build.Box(
		model,
		frame * CFrame.new(0, height / 2, 0),
		Vector3.new(width - 0.4, height, depth - 0.4),
		"#4A4F55",
		"Concrete",
		{
			Name = "Core",
		}
	)
	for floor = 1, count do
		local base = (floor - 1) * floorHeight
		Build.Decor(
			model,
			frame * CFrame.new(0, base + 0.7, 0),
			Vector3.new(width + 0.3, 1.4, depth + 0.3),
			frameColor,
			"Concrete"
		)
		Build.Decor(
			model,
			frame * CFrame.new(0, base + 5.7, 0),
			Vector3.new(width, floorHeight - 1.4, depth),
			glass,
			"Glass",
			{
				Name = "Window",
				Reflectance = 0.3,
				Tags = { WorldTags.Window },
				Attributes = { [WorldTags.Attributes.Lit] = rng:Chance(0.6) },
			}
		)
	end
	Build.Decor(
		model,
		frame * CFrame.new(0, height + 0.5, 0),
		Vector3.new(width + 0.3, 1, depth + 0.3),
		frameColor,
		"Concrete"
	)
	Build.Decor(
		model,
		frame * CFrame.new(width * 0.15, height + 3, 0),
		Vector3.new(width * 0.4, 5, depth * 0.4),
		"#8A8A86",
		"Concrete"
	)
	local beacon = Build.Ball(
		model,
		(frame * CFrame.new(-width * 0.3, height + 1.5, depth * 0.3)).Position,
		1,
		"#8A1010",
		"SmoothPlastic",
		{ Tags = { WorldTags.Beacon } }
	)
	Build.Light(beacon, { Range = 14, Brightness = 2, Color = "#FF2A2A" })
	Build.Decor(model, frame * CFrame.new(0, 7.8, -depth / 2 - 2), Vector3.new(10, 0.4, 4), "#5E6166", "Metal")
end

return Buildings
