--!strict

-- Suelo: franjas horizontales de losa (de GroundBottom a 0) que cubren todo
-- menos los cauces de los ríos, el mar y los huecos (escaleras al subsuelo).
-- Las franjas se solapan un poco con los taludes para que no queden rendijas.

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Styles = require("./Styles")

type Context = Context.Context
type Point = Geometry.Point

local ROW_DEPTH = 6
local SAMPLE_STEP = 2
-- Cuánto entra la losa bajo el talud del río y bajo el muro del mar.
local RIVER_OVERLAP = 5
local SEA_OVERLAP = 2

local Ground = {}

-- Extensión de todo el mundo generado (pueblo + alrededores).
function Ground.Bounds(ctx: Context): (Point, Point)
	local minPoint, maxPoint = Geometry.PolygonBounds(ctx.Map.TownBoundary)
	local margin = 460
	return { X = minPoint.X - margin, Z = minPoint.Z - margin }, { X = maxPoint.X + margin, Z = maxPoint.Z + 260 }
end

local function isLand(ctx: Context, p: Point): boolean
	return ctx.RiverClearance(p) > -RIVER_OVERLAP and not ctx.IsSea(p, -SEA_OVERLAP) and not ctx.InHole(p)
end

function Ground.Build(ctx: Context): ()
	local folder = ctx.Folder("Ground")
	local settings = ctx.Settings
	local height = settings.GroundTop - settings.GroundBottom
	local minPoint, maxPoint = Ground.Bounds(ctx)

	local z = minPoint.Z
	while z < maxPoint.Z do
		local rowCenter = z + ROW_DEPTH / 2
		local runStart: number? = nil
		local x = minPoint.X
		while x <= maxPoint.X + SAMPLE_STEP do
			local land = x <= maxPoint.X and isLand(ctx, { X = x, Z = rowCenter })
			if land and runStart == nil then
				runStart = x
			elseif not land and runStart ~= nil then
				local startX = runStart
				local width = x - startX
				Build.Box(
					folder,
					Build.CF(startX + width / 2 - SAMPLE_STEP / 2, settings.GroundTop - height / 2, rowCenter),
					Build.V3(width, height, ROW_DEPTH),
					Styles.Ground,
					"Concrete",
					{ Name = "Ground" }
				)
				runStart = nil
			end
			x += SAMPLE_STEP
		end
		z += ROW_DEPTH
	end
end

return Ground
