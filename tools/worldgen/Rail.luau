--!strict

-- Vía del tren: balasto, raíles, traviesas, vallas, postes de catenaria con
-- su cable, puentes sobre los ríos y pasos a nivel con luces y barreras
-- (el cliente las anima cuando pasa el tren, D-043).

local roblox = require("@lune/roblox")

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Styles = require("./Styles")
local Ground = require("./Ground")
local PathLogic = require("../../src/Shared/Modules/PathLogic")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Context = Context.Context
type Point = Geometry.Point

local BALLAST_WIDTH = 12
local BALLAST_TOP = 0.5
local RAIL_GAUGE = 4.6
local RAIL_TOP = 0.95
local SLEEPER_SPACING = 4
local FENCE_OFFSET = 9
local CATENARY_SPACING = 48
local CATENARY_HEIGHT = 16

local Rail = {}

local function inBounds(ctx: Context, p: Point): boolean
	local minPoint, maxPoint = Ground.Bounds(ctx)
	return p.X > minPoint.X and p.X < maxPoint.X and p.Z > minPoint.Z and p.Z < maxPoint.Z
end

local function onRoad(ctx: Context, p: Point): boolean
	return ctx.RoadClearance(p) < 0
end

-- Paso a nivel: barreras y luces a los dos lados de la vía.
local function buildCrossing(ctx: Context, folder: any, center: Point, railDirection: Point, road: Context.RoadInfo): ()
	local railDistance = PathLogic.ProjectDistance(ctx.Rail, center)
	local _, roadDirection = Geometry.ClosestOnPolyline(center, road.Points)
	for _, side in { 1, -1 } do
		-- A un lado de la vía, en el borde derecho de la calle.
		local along = Geometry.Scale(roadDirection, side * (BALLAST_WIDTH / 2 + 3))
		local roadNormal = Geometry.Normal(roadDirection)
		local edge = Geometry.Scale(roadNormal, -side * (road.Width / 2 + 1.5))
		local base = Geometry.Add(Geometry.Add(center, along), edge)
		Build.Pillar(folder, base, 0, 7, 0.4, "#F2F2F2", "SmoothPlastic", { Decor = true })
		-- Cruz de San Andrés (amarilla y negra) y luces rojas.
		for _, tilt in { 35, -35 } do
			Build.Decor(
				folder,
				Build.At(base, 7.4, Geometry.YawForLook(roadDirection)) * roblox.CFrame.Angles(0, 0, math.rad(tilt)),
				Build.V3(3.2, 0.5, 0.15),
				"#E8C020",
				"SmoothPlastic"
			)
		end
		local signal = Build.Decor(
			folder,
			Build.At(base, 5.6, Geometry.YawForLook(Geometry.Scale(roadDirection, -side))),
			Build.V3(2.4, 0.9, 0.5),
			"#1E1E1E",
			"SmoothPlastic",
			{
				Name = "CrossingSignal",
				Tags = { WorldTags.CrossingSignal },
				Attributes = {
					[WorldTags.Attributes.RailDistance] = railDistance,
				},
			}
		)
		for index, name in { "Left", "Right" } do
			local lamp = Build.Decor(
				folder,
				signal.CFrame * Build.CF((index - 1.5) * 1.2, 0, -0.3),
				Build.V3(0.7, 0.7, 0.15),
				"#4A1010",
				"SmoothPlastic",
				{ Name = name }
			)
			lamp.Parent = signal
		end
		-- Barrera levantada (vertical); el cliente la baja girándola sobre su base.
		local armLength = road.Width / 2 + 1
		local pivot = Build.At(base, 3.2, Geometry.YawForLook(roadDirection))
		Build.Decor(
			folder,
			pivot * Build.CF(0, armLength / 2, 0),
			Build.V3(0.35, armLength, 0.35),
			"#F0C419",
			"SmoothPlastic",
			{
				Name = "CrossingGate",
				Tags = { WorldTags.CrossingGate },
				Attributes = {
					[WorldTags.Attributes.RailDistance] = railDistance,
					-- Hacia dónde cae al bajar: hacia el centro de la calle.
					[WorldTags.Attributes.GateAngle] = side * 90,
					Pivot = pivot,
				},
			}
		)
	end
	-- Placas entre los raíles sobre la calle.
	Build.Decor(
		folder,
		Build.At(center, RAIL_TOP - 0.1, Geometry.YawForLook(railDirection)),
		Build.V3(RAIL_GAUGE - 0.6, 0.3, road.Width),
		"#5A5A5A",
		"DiamondPlate"
	)
end

function Rail.Build(ctx: Context): ()
	local folder = ctx.Folder("Railway")
	local rail = ctx.Rail

	-- Balasto y raíles, cortados sobre las calles (allí van las placas).
	for _, pair in Geometry.Segments(rail) do
		local a, b = pair[1], pair[2]
		local mid = Geometry.Lerp(a, b, 0.5)
		if inBounds(ctx, mid) then
			local direction = Geometry.Unit(Geometry.Sub(b, a))
			local normal = Geometry.Normal(direction)
			local overRiver = ctx.RiverClearance(mid) < 0
			if not onRoad(ctx, mid) then
				Build.Segment(folder, a, b, BALLAST_TOP, BALLAST_WIDTH, 1.1, Styles.Ballast, "Slate", {
					Name = "Ballast",
				}, 0.4)
			end
			for _, side in { 1, -1 } do
				local shift = Geometry.Scale(normal, side * RAIL_GAUGE / 2)
				Build.Segment(
					folder,
					Geometry.Add(a, shift),
					Geometry.Add(b, shift),
					RAIL_TOP,
					0.35,
					0.45,
					Styles.Rail,
					"Metal",
					{ Name = "Rail", Decor = true },
					0.2
				)
			end
			if overRiver then
				-- Puente: tablero y vigas laterales.
				Build.Segment(folder, a, b, BALLAST_TOP - 1, BALLAST_WIDTH + 1, 3, Styles.MetalDark, "Metal", {
					Name = "RailBridge",
				}, 0.4)
				for _, side in { 1, -1 } do
					local shift = Geometry.Scale(normal, side * (BALLAST_WIDTH / 2 + 0.6))
					Build.Segment(
						folder,
						Geometry.Add(a, shift),
						Geometry.Add(b, shift),
						5,
						0.8,
						4.5,
						"#5C6B73",
						"Metal",
						{ Name = "Girder" },
						0.4
					)
				end
			end
		end
	end

	-- Traviesas.
	for _, sample in Geometry.SampleEvery(rail, SLEEPER_SPACING) do
		if inBounds(ctx, sample.Position) and not onRoad(ctx, sample.Position) then
			Build.Decor(
				folder,
				Build.At(sample.Position, BALLAST_TOP + 0.15, Geometry.YawForLook(sample.Direction)),
				Build.V3(7, 0.3, 1.1),
				Styles.Sleeper,
				"Wood"
			)
		end
	end

	-- Vallas a los dos lados (no en calles, ríos ni en la estación).
	for _, sample in Geometry.SampleEvery(rail, 16) do
		local normal = Geometry.Normal(sample.Direction)
		for _, side in { 1, -1 } do
			local p = Geometry.Add(sample.Position, Geometry.Scale(normal, side * FENCE_OFFSET))
			if
				inBounds(ctx, p)
				and ctx.RoadClearance(p) > 1
				and ctx.RiverClearance(p) > 0
				and not ctx.IsReserved(p, 2)
				and not ctx.IsSea(p)
			then
				Build.Decor(
					folder,
					Build.At(p, 2, Geometry.YawForLook(sample.Direction)),
					Build.V3(0.15, 4, 16),
					"#7E8A7E",
					"Metal",
					{ Name = "Fence", Transparency = 0.35 }
				)
			end
		end
	end

	-- Catenaria: postes a un lado y un cable sobre la vía.
	local previous: any = nil
	for _, sample in Geometry.SampleEvery(rail, CATENARY_SPACING) do
		local normal = Geometry.Normal(sample.Direction)
		local base = Geometry.Add(sample.Position, Geometry.Scale(normal, BALLAST_WIDTH / 2 + 1))
		if inBounds(ctx, base) and ctx.RoadClearance(base) > 1 and ctx.RiverClearance(base) > -2 then
			Build.Pillar(folder, base, 0, CATENARY_HEIGHT + 1, 0.6, Styles.Pole, "Concrete", { Decor = true })
			local armCenter = Geometry.Add(sample.Position, Geometry.Scale(normal, BALLAST_WIDTH / 4 + 0.5))
			local arm = Build.Decor(
				folder,
				Build.At(armCenter, CATENARY_HEIGHT + 0.5, Geometry.YawForBack(normal)),
				Build.V3(0.3, 0.3, BALLAST_WIDTH / 2 + 1),
				Styles.MetalDark,
				"Metal",
				{ Name = "CatenaryArm" }
			)
			local wirePoint = Build.V3(sample.Position.X, CATENARY_HEIGHT, sample.Position.Z)
			if previous ~= nil then
				Build.Wire(previous.Arm, previous.Point, arm, wirePoint, 0.6, "#2A2A2A")
			end
			previous = { Arm = arm, Point = wirePoint }
		else
			previous = nil
		end
	end

	-- Pasos a nivel donde la vía cruza una calle (fuera de los ríos).
	local crossingsFolder = ctx.Folder("LevelCrossings")
	for _, road in ctx.Roads do
		for _, roadPair in Geometry.Segments(road.Points, road.Closed) do
			for _, railPair in Geometry.Segments(rail) do
				local hit = Geometry.SegmentIntersection(roadPair[1], roadPair[2], railPair[1], railPair[2])
				if hit ~= nil and ctx.RiverClearance(hit) > 2 then
					buildCrossing(
						ctx,
						crossingsFolder,
						hit,
						Geometry.Unit(Geometry.Sub(railPair[2], railPair[1])),
						road
					)
				end
			end
		end
	end
end

return Rail
