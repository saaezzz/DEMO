--!strict

-- Lo que rodea al pueblo: muros invisibles (límite jugable), la ciudad que
-- sigue más allá (edificios sencillos que se iluminan de noche) y colinas
-- verdes. Nada de esto se visita: da sensación de continuidad.

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Ground = require("./Ground")
local Styles = require("./Styles")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Context = Context.Context
type Point = Geometry.Point

local WALL_HEIGHT = 600
local BACKDROP_SPACING = 36
local BACKDROP_REACH = 330

local Backdrop = {}

local function boundaryPolygon(ctx: Context): { Point }
	return Geometry.OffsetPolygon(ctx.Map.TownBoundary, ctx.Map.BoundaryMargin)
end

local function buildWalls(ctx: Context, polygon: { Point }): ()
	local folder = ctx.Folder("Boundary")
	for _, pair in Geometry.Segments(polygon, true) do
		Build.Segment(folder, pair[1], pair[2], WALL_HEIGHT, 4, WALL_HEIGHT + 30, "#FFFFFF", "SmoothPlastic", {
			Name = "BoundaryWall",
			Transparency = 1,
			Shadow = false,
			Collide = true,
		}, 3)
	end
	for _, wall in folder:GetChildren() do
		wall.CanQuery = false
		wall.CanTouch = false
	end
end

local function buildCity(ctx: Context, polygon: { Point }): ()
	local folder = ctx.Folder("Backdrop")
	local rng = ctx.Rng
	local minPoint, maxPoint = Ground.Bounds(ctx)
	local z = minPoint.Z + BACKDROP_SPACING / 2
	while z < maxPoint.Z do
		local x = minPoint.X + BACKDROP_SPACING / 2
		while x < maxPoint.X do
			local p = { X = x + rng:Range(-6, 6), Z = z + rng:Range(-6, 6) }
			local distance = Geometry.DistanceToPolyline(p, polygon, true)
			local outside = not Geometry.PointInPolygon(p, polygon)
			if
				outside
				and distance > 16
				and distance < BACKDROP_REACH
				and ctx.RiverClearance(p) > 6
				and not ctx.IsSea(p, 12)
				and ctx.RailClearance(p) > 14
				and rng:Chance(0.78)
			then
				-- Más altos cuanto más lejos del pueblo.
				local far = distance / BACKDROP_REACH
				local height = rng:Range(14, 30) + far * rng:Range(10, 70)
				local width, depth = rng:Range(16, 30), rng:Range(16, 30)
				local yaw = math.rad(rng:Range(-8, 8))
				local wall = if height > 50 then rng:Pick(Styles.OfficeGlass) else rng:Pick(Styles.ApartmentWalls)
				Build.Box(folder, Build.At(p, height / 2, yaw), Build.V3(width, height, depth), wall, "Concrete", {
					Name = "Building",
					Collide = false,
				})
				local bands = math.max(1, math.floor(height / 22))
				for band = 1, bands do
					Build.Decor(
						folder,
						Build.At(p, band * height / (bands + 1), yaw),
						Build.V3(width + 0.2, 4, depth + 0.2),
						Styles.WindowDay,
						"Glass",
						{
							Name = "Window",
							Tags = { WorldTags.Window },
							Attributes = { [WorldTags.Attributes.Lit] = rng:Chance(0.6) },
						}
					)
				end
			end
			x += BACKDROP_SPACING
		end
		z += BACKDROP_SPACING
	end
end

local function buildHills(ctx: Context): ()
	local folder = ctx.Folder("Hills")
	local rng = ctx.Rng
	for _, hill in ctx.Map.Hills do
		local r = hill.Radius
		Build.Ball(folder, Build.V3(hill.Position.X, -r * 0.62, hill.Position.Z), r * 2, "#4F7A3E", "Grass", {
			Name = "Hill",
			Shadow = true,
		})
		-- Bosque: bolas más oscuras repartidas por la ladera.
		for _ = 1, 26 do
			local angle = rng:Range(0, math.pi * 2)
			local distance = rng:Range(0, r * 0.7)
			local px, pz = hill.Position.X + math.cos(angle) * distance, hill.Position.Z + math.sin(angle) * distance
			local surface = math.sqrt(math.max(r * r - distance * distance, 0)) - r * 0.62
			if surface > 4 then
				Build.Ball(
					folder,
					Build.V3(px, surface + 2, pz),
					rng:Range(12, 26),
					rng:Pick({ "#3B6431", "#44703A", "#355B2C" }),
					"Grass"
				)
			end
		end
	end
end

function Backdrop.Build(ctx: Context): ()
	local polygon = boundaryPolygon(ctx)
	buildWalls(ctx, polygon)
	buildCity(ctx, polygon)
	buildHills(ctx)
end

return Backdrop
