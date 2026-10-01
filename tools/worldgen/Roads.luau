--!strict

-- Carreteras: asfalto, aceras (cortadas en los cruces), línea central en las
-- avenidas, pasos de cebra en los cruces con avenida, puentes sobre los ríos
-- y alcantarillas. Devuelve los cruces para colocar semáforos.

local Build = require("./Build")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Styles = require("./Styles")
local WorldTags = require("../../src/Shared/Config/WorldTags")

type Context = Context.Context
type Point = Geometry.Point
type RoadInfo = Context.RoadInfo

export type Arm = {
	Road: RoadInfo,
	Direction: Point,
}

export type Junction = {
	Position: Point,
	Arms: { Arm },
	HasArterial: boolean,
}

local PIECE = 6
local JOINT_TOLERANCE = 2

local Roads = {}

-- Tramos de una recta (a→b, desplazada `offset` a la izquierda) en los que
-- `keep(p)` se cumple, como pares de distancias (desde, hasta).
local function keptRuns(a: Point, b: Point, offset: number, keep: (Point) -> boolean): { { number } }
	local direction = Geometry.Unit(Geometry.Sub(b, a))
	local shift = Geometry.Scale(Geometry.Normal(direction), offset)
	local length = Geometry.Distance(a, b)
	local runs: { { number } } = {}
	local runStart: number? = nil
	local t = 0
	while t < length do
		local pieceEnd = math.min(t + PIECE, length)
		local center = Geometry.Add(Geometry.Add(a, Geometry.Scale(direction, (t + pieceEnd) / 2)), shift)
		if keep(center) then
			if runStart == nil then
				runStart = t
			end
		elseif runStart ~= nil then
			table.insert(runs, { runStart, t })
			runStart = nil
		end
		t = pieceEnd
	end
	if runStart ~= nil then
		table.insert(runs, { runStart, length })
	end
	return runs
end

local function pointAlong(a: Point, b: Point, distance: number, offset: number): Point
	local direction = Geometry.Unit(Geometry.Sub(b, a))
	return Geometry.Add(
		Geometry.Add(a, Geometry.Scale(direction, distance)),
		Geometry.Scale(Geometry.Normal(direction), offset)
	)
end

-- Tramo recto a lo largo de a→b entre dos distancias, desplazado a un lado.
local function strip(
	folder: any,
	a: Point,
	b: Point,
	run: { number },
	offset: number,
	top: number,
	width: number,
	height: number,
	color: string,
	material: string,
	decor: boolean
): ()
	if run[2] - run[1] < 1 then
		return
	end
	local from = pointAlong(a, b, run[1], offset)
	local to = pointAlong(a, b, run[2], offset)
	local extra = if decor then { Decor = true } else nil
	Build.Segment(folder, from, to, top, width, height, color, material, extra)
end

local function buildBridge(ctx: Context, folder: any, road: RoadInfo, a: Point, b: Point): ()
	local direction = Geometry.Unit(Geometry.Sub(b, a))
	local normal = Geometry.Normal(direction)
	local length = Geometry.Distance(a, b)
	local settings = ctx.Settings
	-- Tramo del segmento que pasa sobre algún cauce.
	local spanStart: number? = nil
	local t = 0
	local function finish(fromT: number, toT: number): ()
		local from = Geometry.Add(a, Geometry.Scale(direction, fromT - 2))
		local to = Geometry.Add(a, Geometry.Scale(direction, toT + 2))
		local deckWidth = road.Width + 2 * settings.SidewalkWidth
		Build.Segment(folder, from, to, settings.RoadTop - 0.05, deckWidth + 1, 3, Styles.Concrete, "Concrete", {
			Name = "BridgeDeck",
		})
		for _, side in { 1, -1 } do
			local shift = Geometry.Scale(normal, side * (deckWidth / 2 + 0.3))
			Build.Segment(
				folder,
				Geometry.Add(from, shift),
				Geometry.Add(to, shift),
				settings.SidewalkTop + 3,
				0.6,
				3,
				Styles.Metal,
				"Metal",
				{ Name = "BridgeRailing" }
			)
			-- Farolas del puente, en los dos extremos.
			for _, anchor in { from, to } do
				local base = Geometry.Add(anchor, shift)
				Build.Pillar(folder, base, settings.SidewalkTop, 12, 0.5, Styles.MetalDark, "Metal", {
					Decor = true,
				})
				local head = Build.Decor(
					folder,
					Build.At(Geometry.Add(base, Geometry.Scale(normal, -side * 1.2)), settings.SidewalkTop + 12, 0),
					Build.V3(1.4, 0.5, 1.4),
					Styles.LampWarm,
					"SmoothPlastic",
					{ Tags = { WorldTags.NightNeon } }
				)
				Build.Light(head, { Range = 22, Brightness = 1.6, Color = Styles.LampWarm })
			end
		end
		-- Pilares donde empieza el agua.
		for _, pierT in { fromT + (toT - fromT) * 0.3, fromT + (toT - fromT) * 0.7 } do
			local p = Geometry.Add(a, Geometry.Scale(direction, pierT))
			Build.Box(
				folder,
				Build.At(p, (settings.RoadTop - 3 + settings.ChannelBottom) / 2, Geometry.YawForLook(direction)),
				Build.V3(deckWidth - 2, settings.RoadTop - 3 - settings.ChannelBottom, 3),
				Styles.ConcreteDark,
				"Concrete",
				{ Name = "BridgePier" }
			)
		end
	end
	while t <= length do
		local over = ctx.RiverClearance(Geometry.Add(a, Geometry.Scale(direction, t))) < 0
		if over and spanStart == nil then
			spanStart = t
		elseif not over and spanStart ~= nil then
			finish(spanStart, t)
			spanStart = nil
		end
		t += 2
	end
	if spanStart ~= nil then
		finish(spanStart, length)
	end
end

local function buildRoad(ctx: Context, road: RoadInfo): ()
	local folder = Build.Folder(ctx.Folder("Roads"), road.Id)
	local settings = ctx.Settings
	local segments = Geometry.Segments(road.Points, road.Closed)
	local arterial = road.Kind == "Arterial"

	for _, pair in segments do
		local a, b = pair[1], pair[2]
		Build.Segment(folder, a, b, settings.RoadTop, road.Width, 0.6, Styles.Asphalt, "Asphalt", { Name = "Road" })

		-- Aceras: se cortan donde cruza otra calle, la vía o un cauce sin puente.
		local sidewalkOffset = road.Width / 2 + settings.SidewalkWidth / 2
		for _, side in { 1, -1 } do
			local runs = keptRuns(a, b, side * sidewalkOffset, function(p: Point): boolean
				return ctx.RoadClearance(p, road.Id) > -0.5 and ctx.RailClearance(p) > 6
			end)
			for _, run in runs do
				strip(
					folder,
					a,
					b,
					run,
					side * sidewalkOffset,
					settings.SidewalkTop,
					settings.SidewalkWidth,
					0.85,
					Styles.Sidewalk,
					"Pavement",
					false
				)
			end
		end

		-- Marcas viales de las avenidas: línea central y bordes.
		if arterial then
			local runs = keptRuns(a, b, 0, function(p: Point): boolean
				return ctx.RoadClearance(p, road.Id) > 2 and ctx.RailClearance(p) > 8
			end)
			for _, run in runs do
				strip(
					folder,
					a,
					b,
					run,
					0,
					settings.RoadTop + 0.03,
					0.5,
					0.1,
					Styles.RoadLineYellow,
					"SmoothPlastic",
					true
				)
				for _, side in { 1, -1 } do
					strip(
						folder,
						a,
						b,
						run,
						side * (road.Width / 2 - 1.2),
						settings.RoadTop + 0.03,
						0.35,
						0.1,
						Styles.RoadLine,
						"SmoothPlastic",
						true
					)
				end
			end
		end

		buildBridge(ctx, folder, road, a, b)

		-- Alcantarillas.
		local length = Geometry.Distance(a, b)
		local count = math.floor(length / 70)
		for i = 1, count do
			local p = pointAlong(a, b, length * i / (count + 1), ctx.Rng:Range(-road.Width / 4, road.Width / 4))
			if ctx.RiverClearance(p) > 0 then
				Build.Pillar(folder, p, settings.RoadTop - 0.05, 0.1, 2.4, "#2E2F31", "DiamondPlate", { Decor = true })
			end
		end
	end

	-- Uniones entre tramos: disco de asfalto en cada vértice.
	local vertices = if road.Closed then road.Points else { table.unpack(road.Points, 2, #road.Points - 1) }
	for _, p in vertices do
		Build.Pillar(folder, p, settings.RoadTop - 0.6, 0.6, road.Width, Styles.Asphalt, "Asphalt", { Name = "Joint" })
	end
end

-- Cruces: vértices de una calle que tocan otra calle.
local function findJunctions(ctx: Context): { Junction }
	local junctions: { Junction } = {}
	local function junctionAt(p: Point): Junction
		for _, junction in junctions do
			if Geometry.Distance(junction.Position, p) < 6 then
				return junction
			end
		end
		local created: Junction = { Position = p, Arms = {}, HasArterial = false }
		table.insert(junctions, created)
		return created
	end

	for _, road in ctx.Roads do
		for _, other in ctx.Roads do
			if other ~= road then
				for _, p in road.Points do
					if Geometry.DistanceToPolyline(p, other.Points, other.Closed) < JOINT_TOLERANCE then
						local junction = junctionAt(p)
						for _, candidate in { road, other } do
							local known = false
							for _, arm in junction.Arms do
								if arm.Road == candidate then
									known = true
								end
							end
							if not known then
								local _, direction = Geometry.ClosestOnPolyline(p, candidate.Points)
								table.insert(junction.Arms, { Road = candidate, Direction = direction })
								junction.HasArterial = junction.HasArterial or candidate.Kind == "Arterial"
							end
						end
					end
				end
			end
		end
	end
	return junctions
end

-- Paso de cebra sobre `arm.Road`, a `distance` del centro del cruce.
local function crosswalk(
	ctx: Context,
	folder: any,
	center: Point,
	direction: Point,
	road: RoadInfo,
	distance: number
): ()
	local normal = Geometry.Normal(direction)
	local base = Geometry.Add(center, Geometry.Scale(direction, distance))
	local stripes = math.floor((road.Width - 2) / 2.2)
	for i = 0, stripes - 1 do
		local offset = -road.Width / 2 + 1.6 + i * 2.2
		local p = Geometry.Add(base, Geometry.Scale(normal, offset))
		Build.Decor(
			folder,
			Build.At(p, ctx.Settings.RoadTop + 0.04, Geometry.YawForLook(direction)),
			Build.V3(1.1, 0.1, 4.5),
			Styles.RoadLine,
			"SmoothPlastic"
		)
	end
end

function Roads.Build(ctx: Context): { Junction }
	for _, road in ctx.Roads do
		buildRoad(ctx, road)
	end

	local junctions = findJunctions(ctx)
	local folder = ctx.Folder("Crosswalks")
	for _, junction in junctions do
		if junction.HasArterial and #junction.Arms >= 2 then
			for _, arm in junction.Arms do
				-- A cada lado del cruce, pasado el ancho de la otra calle.
				local otherHalf = 0
				for _, other in junction.Arms do
					if other ~= arm then
						otherHalf = math.max(otherHalf, other.Road.Half)
					end
				end
				for _, sign in { 1, -1 } do
					local direction = Geometry.Scale(arm.Direction, sign)
					local probe = Geometry.Add(junction.Position, Geometry.Scale(direction, otherHalf + 4))
					if
						Geometry.DistanceToPolyline(probe, arm.Road.Points, arm.Road.Closed) < arm.Road.Width / 2
						and ctx.RiverClearance(probe) > 0
					then
						crosswalk(ctx, folder, junction.Position, direction, arm.Road, otherHalf + 4)
					end
				end
			end
		end
	end
	return junctions
end

return Roads
