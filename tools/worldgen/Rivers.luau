--!strict

-- Ríos y mar. Cada río es un cauce con taludes de hierba, una llanura a cada
-- lado y el agua en medio; arriba, un paseo a cada orilla. El agua es una
-- pieza provisional (etiqueta Water) que el servidor cambia por agua de
-- Terrain al arrancar. Al sur, el mar con su muro.

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Styles = require("./Styles")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Context = Context.Context
type Point = Geometry.Point

local OVERLAP = 1.2
local PATH_WIDTH = 5

local Rivers = {}

local function waterPart(folder: any, cframe: any, size: any): any
	return Build.Box(folder, cframe, size, Styles.Water, "Glass", {
		Name = "Water",
		Transparency = 0.35,
		Reflectance = 0.1,
		Decor = true,
		Tags = { WorldTags.Water },
	})
end

local function buildRiver(ctx: Context, river: Context.RiverInfo): ()
	local folder = Build.Folder(ctx.Folder("Rivers"), river.Id)
	local settings = ctx.Settings
	local bankHeight = settings.GroundTop - settings.BankBottom
	local baseHeight = settings.BankBottom - settings.ChannelBottom
	local waterDepth = settings.WaterTop - (settings.ChannelBottom + 2)

	for index, pair in Geometry.Segments(river.Points) do
		local a, b = pair[1], pair[2]
		-- En el mar ya no hay cauce: allí el agua es la del mar.
		if ctx.IsSea(b, -ctx.Settings.SidewalkWidth) and ctx.IsSea(a, -ctx.Settings.SidewalkWidth) then
			continue
		end
		local direction = Geometry.Unit(Geometry.Sub(b, a))
		local normal = Geometry.Normal(direction)
		local length = Geometry.Distance(a, b) + 2 * OVERLAP
		local mid = Geometry.Lerp(a, b, 0.5)
		local look = Geometry.YawForLook(direction)

		for _, side in { 1, -1 } do
			local outward = Geometry.Scale(normal, side)
			-- Talud: alto (Y = 0) en el borde del cauce, bajo en la llanura.
			local bankCenter = Geometry.Add(mid, Geometry.Scale(outward, (river.FloodHalf + river.Half) / 2))
			Build.Part(folder, {
				Name = "Bank",
				Class = "WedgePart",
				CFrame = Build.At(bankCenter, settings.BankBottom + bankHeight / 2, Geometry.YawForBack(outward)),
				Size = Build.V3(length, bankHeight, river.Half - river.FloodHalf),
				Color = Styles.Grass,
				Material = "Grass",
			})
			-- Llanura (y relleno bajo el talud) desde el agua hasta el borde del cauce.
			local baseCenter = Geometry.Add(mid, Geometry.Scale(outward, (river.WaterHalf + river.Half) / 2))
			Build.Box(
				folder,
				Build.At(baseCenter, settings.BankBottom - baseHeight / 2, look),
				Build.V3(river.Half - river.WaterHalf, baseHeight, length),
				Styles.GrassDark,
				"Grass",
				{ Name = "FloodPlain" }
			)
			-- Paseo por lo alto de la orilla (cada dos tramos, para ahorrar piezas).
			if index % 2 == 1 then
				local pathCenter = Geometry.Add(mid, Geometry.Scale(outward, river.Half + PATH_WIDTH / 2 + 1))
				local pathLength = length + Geometry.Distance(a, b)
				local ahead = Geometry.Add(pathCenter, Geometry.Scale(direction, Geometry.Distance(a, b) / 2))
				if ctx.RoadClearance(ahead) > 0 and not ctx.IsSea(ahead, 4) then
					Build.Decor(
						folder,
						Build.At(ahead, 0.08, look),
						Build.V3(PATH_WIDTH, 0.2, pathLength),
						Styles.Sand,
						"Pebble",
						{ Name = "RiversidePath" }
					)
				end
			end
		end

		-- Lecho y agua.
		Build.Decor(
			folder,
			Build.At(mid, settings.ChannelBottom + 1, look),
			Build.V3(river.WaterHalf * 2 + 2, 2, length),
			Styles.Riverbed,
			"Mud"
		)
		waterPart(
			folder,
			Build.At(mid, settings.WaterTop - waterDepth / 2, look),
			Build.V3(river.WaterHalf * 2 + 1, waterDepth, length)
		)
	end
end

-- Mar al sur, con un muro de hormigón a lo largo de la costa.
local function buildSea(ctx: Context): ()
	local folder = ctx.Folder("Sea")
	local settings = ctx.Settings
	local shore = ctx.Map.Shoreline
	local depth = settings.WaterTop - settings.ChannelBottom
	local farZ = 0
	for _, p in shore do
		farZ = math.max(farZ, p.Z)
	end
	farZ += 700

	for _, pair in Geometry.Segments(shore) do
		local a, b = pair[1], pair[2]
		-- Muro: sobresale 1,2 studs como pretil y baja hasta el fondo.
		Build.Segment(folder, a, b, 1.2, 5, 1.2 - settings.ChannelBottom, Styles.Concrete, "Concrete", {
			Name = "Seawall",
		}, 1.5)
		-- Franja de agua desde la costa hasta lejos.
		local nearZ = math.min(a.Z, b.Z)
		local mid = Geometry.Lerp(a, b, 0.5)
		local stripDepth = farZ - nearZ
		waterPart(
			folder,
			Build.CF(mid.X, settings.WaterTop - depth / 2, nearZ + stripDepth / 2),
			Build.V3(math.abs(b.X - a.X) + 2, depth, stripDepth)
		)
		Build.Decor(
			folder,
			Build.CF(mid.X, settings.ChannelBottom - 1, nearZ + stripDepth / 2),
			Build.V3(math.abs(b.X - a.X) + 2, 2, stripDepth),
			Styles.Riverbed,
			"Sand"
		)
	end
end

function Rivers.Build(ctx: Context): ()
	for _, river in ctx.Rivers do
		buildRiver(ctx, river)
	end
	buildSea(ctx)
end

return Rivers
