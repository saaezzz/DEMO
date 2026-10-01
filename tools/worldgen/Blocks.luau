--!strict

-- Relleno de los distritos. Cada distrito tiene una cuadrícula de callejuelas
-- (girada GridAngle); entre ellas quedan manzanas que se dividen en parcelas
-- según el estilo del distrito. En cada parcela libre (sin calles, ríos, vía
-- ni lugares reservados) va un edificio y sus detalles. Por las callejuelas
-- corren los postes eléctricos con sus cables.

local roblox = require("@lune/roblox")

local Build = require("./Build")
local Buildings = require("./Buildings")
local Context = require("./Context")
local Geometry = require("./Geometry")
local Props = require("./Props")
local Styles = require("./Styles")

type Context = Context.Context
type Point = Geometry.Point

local CFrame = roblox.CFrame

local CELL = 54
local LANE_STEP = 4
local LANE_EXTEND = 8
local POLE_SPACING = 38
-- Tamaño de la parcela reducida junto a calles y bordes.
local SHRINK = 0.7

local Blocks = {}

-- Ocupación en celdas de OCCUPANCY studs: parcelas construidas y callejuelas.
local OCCUPANCY = 4
local occupied: { [string]: boolean } = {}

local function occupancyKey(p: Point): string
	return math.floor(p.X / OCCUPANCY) .. ":" .. math.floor(p.Z / OCCUPANCY)
end

local function markRect(rect: Geometry.Rect): ()
	local stepsX = math.ceil(rect.HalfX * 2 / 2)
	local stepsZ = math.ceil(rect.HalfZ * 2 / 2)
	for i = 0, stepsX do
		for j = 0, stepsZ do
			local localPoint =
				{ X = -rect.HalfX + i * rect.HalfX * 2 / stepsX, Z = -rect.HalfZ + j * rect.HalfZ * 2 / stepsZ }
			occupied[occupancyKey(Geometry.ToWorld(localPoint, rect.Center, rect.Yaw))] = true
		end
	end
end

type Grid = {
	Origin: Point,
	Yaw: number,
	Polygon: { Point },
}

local function toWorld(grid: Grid, u: number, v: number): Point
	return Geometry.ToWorld({ X = u, Z = v }, grid.Origin, grid.Yaw)
end

local function laneOk(ctx: Context, grid: Grid, p: Point): boolean
	return Geometry.PointInPolygon(p, grid.Polygon)
		and ctx.RoadClearance(p) > 0
		and ctx.RiverClearance(p) > 3
		and ctx.RailClearance(p) > 8
		and not ctx.IsReserved(p, 1)
		and not ctx.IsSea(p, 6)
		and not ctx.InHole(p)
end

-- Callejuelas sobre la recta local u = fixed (vertical) o v = fixed.
local function buildLanes(
	ctx: Context,
	folder: any,
	grid: Grid,
	vertical: boolean,
	fixed: number,
	from: number,
	to: number,
	withPoles: boolean
): ()
	local settings = ctx.Settings
	local function at(t: number): Point
		return if vertical then toWorld(grid, fixed, t) else toWorld(grid, t, fixed)
	end
	local runs: { { number } } = {}
	local runStart: number? = nil
	local t = from
	while t <= to do
		if laneOk(ctx, grid, at(t)) then
			runStart = runStart or t
		elseif runStart ~= nil then
			table.insert(runs, { runStart, t - LANE_STEP })
			runStart = nil
		end
		t += LANE_STEP
	end
	if runStart ~= nil then
		table.insert(runs, { runStart, to })
	end

	for _, run in runs do
		local startT, endT = run[1], run[2]
		-- Se alargan hasta tocar la calle si la tienen al lado.
		if ctx.RoadClearance(at(startT - LANE_EXTEND)) < 0 then
			startT -= LANE_EXTEND
		end
		if ctx.RoadClearance(at(endT + LANE_EXTEND)) < 0 then
			endT += LANE_EXTEND
		end
		if endT - startT >= 16 then
			local a, b = at(startT), at(endT)
			local laneDirection = Geometry.Sub(b, a)
			markRect(
				Geometry.Rect(
					Geometry.Lerp(a, b, 0.5),
					settings.LaneWidth + 2,
					Geometry.Length(laneDirection),
					Geometry.YawForLook(laneDirection)
				)
			)
			Build.Segment(folder, a, b, settings.LaneTop, settings.LaneWidth, 0.5, Styles.AsphaltLane, "Asphalt", {
				Name = "Lane",
			})
			if withPoles then
				local direction = Geometry.Unit(Geometry.Sub(b, a))
				local side = Geometry.Scale(Geometry.Normal(direction), settings.LaneWidth / 2 + 0.9)
				local previous: Props.PoleWires? = nil
				for _, sample in Geometry.SampleEvery({ a, b }, POLE_SPACING) do
					local p = Geometry.Add(sample.Position, side)
					if ctx.RoadClearance(p) > 1 and not ctx.IsReserved(p, 1) then
						local pole = Props.UtilityPole(folder, p, direction, ctx.Rng)
						if previous ~= nil then
							Props.ConnectPoles(previous, pole, ctx.Rng)
						end
						previous = pole
					else
						previous = nil
					end
				end
			end
		end
	end
end

-- ¿Cabe una parcela (rectángulo en coordenadas del mundo)?
local function lotOk(ctx: Context, grid: Grid, rect: Geometry.Rect): boolean
	for _, p in Geometry.RectSamples(rect) do
		if
			not Geometry.PointInPolygon(p, grid.Polygon)
			or ctx.RoadClearance(p) < 0.8
			or ctx.RiverClearance(p) < 9
			or ctx.RailClearance(p) < 11
			or ctx.IsReserved(p, 1)
			or ctx.IsSea(p, 10)
			or ctx.InHole(p)
		then
			return false
		end
	end
	return true
end

type Lot = {
	U: number,
	V: number,
	SizeU: number,
	SizeV: number,
	-- Dirección local (unitaria) hacia la que mira la fachada.
	FaceU: number,
	FaceV: number,
	Kind: string,
}

-- Hacia qué lado de la parcela hay una calle cerca (si no, hacia su callejuela).
local function chooseFront(ctx: Context, grid: Grid, lot: Lot, candidates: { { number } }): (number, number)
	for _, candidate in candidates do
		local reach = (if candidate[1] ~= 0 then lot.SizeU else lot.SizeV) / 2 + 8
		local probe = toWorld(grid, lot.U + candidate[1] * reach, lot.V + candidate[2] * reach)
		if ctx.RoadClearance(probe) < 2 then
			return candidate[1], candidate[2]
		end
	end
	local pick = ctx.Rng:Pick(candidates)
	return pick[1], pick[2]
end

local function nearArterial(ctx: Context, p: Point): boolean
	local clearance, owner = ctx.RoadClearance(p)
	if owner == nil or clearance > 22 then
		return false
	end
	for _, road in ctx.Roads do
		if road.Id == owner then
			return road.Kind == "Arterial"
		end
	end
	return false
end

-- Reparto de una manzana (interior de CELL - calle) según el estilo.
local function planCell(ctx: Context, grid: Grid, style: string, cu: number, cv: number, inner: number): { Lot }
	local rng = ctx.Rng
	local center = toWorld(grid, cu, cv)
	local busy = nearArterial(ctx, center)
	local roll = rng:Next()
	local whole: string? = nil
	if style == "Commercial" then
		whole = if roll < 0.35 then "Office" elseif roll < 0.5 then "Konbini" elseif roll < 0.7 then "Apartment" else nil
	elseif style == "Dense" then
		whole = if roll < 0.3 then "Apartment" elseif roll < 0.36 and busy then "Konbini" else nil
	else
		whole = if roll < 0.07 then "Apartment" elseif roll < 0.1 and busy then "Konbini" else nil
	end

	local lots: { Lot } = {}
	if whole ~= nil then
		local lot: Lot = { U = cu, V = cv, SizeU = inner, SizeV = inner, FaceU = 0, FaceV = -1, Kind = whole }
		lot.FaceU, lot.FaceV = chooseFront(ctx, grid, lot, { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } })
		table.insert(lots, lot)
		return lots
	end

	local half = inner / 2
	for _, quadrant in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local lot: Lot = {
			U = cu + quadrant[1] * half / 2,
			V = cv + quadrant[2] * half / 2,
			SizeU = half,
			SizeV = half,
			FaceU = 0,
			FaceV = 0,
			Kind = "House",
		}
		lot.FaceU, lot.FaceV = chooseFront(ctx, grid, lot, { { quadrant[1], 0 }, { 0, quadrant[2] } })
		local probe = toWorld(grid, lot.U + lot.FaceU * (half / 2 + 8), lot.V + lot.FaceV * (half / 2 + 8))
		local onBusyStreet = ctx.RoadClearance(probe) < 2
		local shopChance = if style == "Commercial" then 0.7 elseif style == "Dense" then 0.45 else 0.12
		local apartmentChance = if style == "Commercial" then 0.25 elseif style == "Dense" then 0.22 else 0.04
		if onBusyStreet and rng:Chance(shopChance) then
			lot.Kind = "Shop"
		elseif rng:Chance(apartmentChance) then
			lot.Kind = "Apartment"
		end
		table.insert(lots, lot)
	end
	return lots
end

-- Edificio y detalles de una parcela.
local function buildLot(ctx: Context, folder: any, grid: Grid, lot: Lot): ()
	local rng = ctx.Rng
	local center = toWorld(grid, lot.U, lot.V)
	local facing = Geometry.Rotate({ X = lot.FaceU, Z = lot.FaceV }, grid.Yaw)
	local yaw = Geometry.YawForLook(facing)
	-- Ancho (a lo largo de la fachada) y fondo de la parcela.
	local lotWidth = if lot.FaceU ~= 0 then lot.SizeV else lot.SizeU
	local lotDepth = if lot.FaceU ~= 0 then lot.SizeU else lot.SizeV
	local frame = Build.At(center, 0, yaw)

	if lot.Kind == "House" then
		local carport = rng:Chance(0.3) and lotWidth >= 21
		local width = math.min(lotWidth - (if carport then 9.5 else 3), 20)
		local depth = math.min(lotDepth - 5, 17)
		local shift = if carport then -(lotWidth - width) / 2 + 1.2 else 0
		Buildings.House(folder, frame * CFrame.new(shift, 0, 1.5), width, depth, rng, { Carport = carport })
		if rng:Chance(0.7) then
			Buildings.LotWall(folder, frame, lotWidth, lotDepth, shift - width * 0.28)
		end
		-- Árbol de jardín en una esquina trasera.
		if rng:Chance(0.35) and lotDepth > 18 then
			local corner = (frame * CFrame.new(
				(lotWidth / 2 - 2.5) * (if carport then -1 else 1),
				0,
				lotDepth / 2 - 2.5
			)).Position
			Props.Tree(
				folder,
				{ X = corner.X, Z = corner.Z },
				rng,
				rng:Pick({ "Leafy", "Leafy", "Pine", "Cherry", "Maple" })
			)
		end
		if rng:Chance(0.15) then
			local p = (frame * CFrame.new(-lotWidth / 2 + 1.8, 0, -lotDepth / 2 + 2.6)).Position
			Props.VendingMachine(folder, { X = p.X, Z = p.Z }, facing, rng)
		elseif rng:Chance(0.15) then
			local p = (frame * CFrame.new(lotWidth / 2 - 2, 0, -lotDepth / 2 + 2.6)).Position
			Props.Bicycle(folder, { X = p.X, Z = p.Z }, Geometry.Normal(facing))
		end
	elseif lot.Kind == "Shop" then
		Buildings.Shop(folder, frame * CFrame.new(0, 0, 1), lotWidth - 2, lotDepth - 4, rng)
		if rng:Chance(0.3) then
			local p = (frame * CFrame.new(lotWidth / 2 - 1.8, 0, -lotDepth / 2 + 1.5)).Position
			Props.VendingMachine(folder, { X = p.X, Z = p.Z }, facing, rng)
		end
	elseif lot.Kind == "Apartment" and lotWidth < 30 then
		-- Bloque estrecho en un cuarto de manzana.
		Buildings.Apartment(folder, frame * CFrame.new(-1.5, 0, 1.5), lotWidth - 7, lotDepth - 8, rng, rng:Int(3, 5))
	elseif lot.Kind == "Apartment" then
		local width = math.min(lotWidth - 12, 44)
		local depth = math.min(lotDepth - 22, 22)
		Buildings.Apartment(folder, frame * CFrame.new(-3, 0, 4), width, depth, rng)
		local entrance = (frame * CFrame.new(-width / 2 - 1, 0, -depth / 2 - 2)).Position
		Props.GarbageStation(folder, { X = entrance.X, Z = entrance.Z }, facing)
		for i = 1, rng:Int(2, 5) do
			local p = (frame * CFrame.new(width / 2 - 3 - i * 1.4, 0, -lotDepth / 2 + 4)).Position
			Props.Bicycle(folder, { X = p.X, Z = p.Z }, Geometry.Normal(facing))
		end
		-- Aparcamiento delante.
		for i = 1, rng:Int(1, 3) do
			local p = (frame * CFrame.new(-lotWidth / 2 + 5 + (i - 1) * 8, 0, -lotDepth / 2 + 8)).Position
			Props.Car(folder, { X = p.X, Z = p.Z }, Geometry.Scale(facing, -1), rng)
		end
	elseif lot.Kind == "Konbini" then
		Buildings.Konbini(
			folder,
			frame * CFrame.new(0, 0, 8),
			math.min(lotWidth - 8, 32),
			math.min(lotDepth - 22, 22),
			rng
		)
		for i = 1, 3 do
			local x = -lotWidth / 2 + 6 + (i - 1) * 8
			local stripe = (frame * CFrame.new(x + 4, 0.25, -lotDepth / 2 + 7)).Position
			Build.Decor(
				folder,
				Build.CF(stripe.X, 0.25, stripe.Z, yaw),
				Build.V3(0.4, 0.1, 12),
				Styles.RoadLine,
				"SmoothPlastic"
			)
			if rng:Chance(0.6) then
				local p = (frame * CFrame.new(x, 0, -lotDepth / 2 + 7)).Position
				Props.Car(folder, { X = p.X, Z = p.Z }, facing, rng)
			end
		end
		local asphalt = (frame * CFrame.new(0, 0, -lotDepth / 2 + 7)).Position
		Build.Decor(
			folder,
			Build.CF(asphalt.X, 0.12, asphalt.Z, yaw),
			Build.V3(lotWidth - 2, 0.2, 14),
			Styles.AsphaltLane,
			"Asphalt"
		)
	elseif lot.Kind == "Office" then
		Buildings.Office(
			folder,
			frame * CFrame.new(0, 0, 2),
			math.min(lotWidth - 12, 36),
			math.min(lotDepth - 12, 30),
			rng
		)
		local plaza = (frame * CFrame.new(0, 0, -lotDepth / 2 + 3)).Position
		Build.Decor(
			folder,
			Build.CF(plaza.X, 0.15, plaza.Z, yaw),
			Build.V3(lotWidth - 2, 0.3, 6),
			Styles.Curb,
			"Pavement"
		)
	end
end

local function fillDistrict(ctx: Context, district: any): ()
	local folder = Build.Folder(ctx.Folder("Districts"), district.Id)
	local grid: Grid = {
		Origin = Geometry.Centroid(district.Polygon),
		Yaw = math.rad(district.GridAngle),
		Polygon = district.Polygon,
	}
	local minU, minV, maxU, maxV = math.huge, math.huge, -math.huge, -math.huge
	for _, p in district.Polygon do
		local l = Geometry.ToLocal(p, grid.Origin, grid.Yaw)
		minU, maxU = math.min(minU, l.X), math.max(maxU, l.X)
		minV, maxV = math.min(minV, l.Z), math.max(maxV, l.Z)
	end
	local settings = ctx.Settings

	-- Callejuelas: postes solo en las de un sentido.
	for k = math.ceil(minU / CELL), math.floor(maxU / CELL) do
		buildLanes(ctx, folder, grid, true, k * CELL, minV, maxV, true)
	end
	for k = math.ceil(minV / CELL), math.floor(maxV / CELL) do
		buildLanes(ctx, folder, grid, false, k * CELL, minU, maxU, false)
	end

	local inner = CELL - settings.LaneWidth - 2
	local half = inner / 2
	local function fits(lot: Lot): boolean
		return lotOk(ctx, grid, Geometry.Rect(toWorld(grid, lot.U, lot.V), lot.SizeU, lot.SizeV, grid.Yaw))
	end
	local function build(lot: Lot): ()
		markRect(Geometry.Rect(toWorld(grid, lot.U, lot.V), lot.SizeU, lot.SizeV, grid.Yaw))
		buildLot(ctx, folder, grid, lot)
	end
	-- Una casa de un cuarto de manzana; si no cabe entera (junto a una calle
	-- o al borde del distrito), una más estrecha empujada hacia el centro.
	local function placeQuarter(lot: Lot, cu: number, cv: number): ()
		if fits(lot) then
			build(lot)
			return
		end
		local shrunk: Lot = table.clone(lot)
		if shrunk.Kind == "Apartment" then
			shrunk.Kind = "House"
		end
		shrunk.SizeU, shrunk.SizeV = half * SHRINK, half * SHRINK
		shrunk.U = lot.U + (cu - lot.U) * (1 - SHRINK)
		shrunk.V = lot.V + (cv - lot.V) * (1 - SHRINK)
		if fits(shrunk) then
			local probe =
				toWorld(grid, shrunk.U + shrunk.FaceU * (half / 2 + 10), shrunk.V + shrunk.FaceV * (half / 2 + 10))
			if ctx.RoadClearance(probe) < 2 and ctx.Rng:Chance(0.5) then
				shrunk.Kind = "Shop"
			end
			build(shrunk)
		end
	end

	for i = math.floor(minU / CELL), math.ceil(maxU / CELL) do
		for j = math.floor(minV / CELL), math.ceil(maxV / CELL) do
			local cu, cv = (i + 0.5) * CELL, (j + 0.5) * CELL
			for _, lot in planCell(ctx, grid, district.Style, cu, cv, inner) do
				if lot.SizeU < inner then
					placeQuarter(lot, cu, cv)
				elseif fits(lot) then
					build(lot)
				else
					-- La manzana entera no cabe: se prueba con cuatro casas.
					for _, quadrant in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
						placeQuarter({
							U = cu + quadrant[1] * half / 2,
							V = cv + quadrant[2] * half / 2,
							SizeU = half,
							SizeV = half,
							FaceU = quadrant[1],
							FaceV = 0,
							Kind = "House",
						}, cu, cv)
					end
				end
			end
		end
	end
end

-- Huecos que han quedado libres: huertos, aparcamientos, cobertizos y árboles.
local FILL_STEP = 12

local function fillGaps(ctx: Context): ()
	local folder = ctx.Folder("Gaps")
	local rng = ctx.Rng
	local minPoint, maxPoint = Geometry.PolygonBounds(ctx.Map.TownBoundary)
	local z = minPoint.Z
	while z < maxPoint.Z do
		local x = minPoint.X
		while x < maxPoint.X do
			local p = { X = x + rng:Range(-3, 3), Z = z + rng:Range(-3, 3) }
			local free = ctx.InTown(p)
				and not occupied[occupancyKey(p)]
				and ctx.RoadClearance(p) > 4
				and ctx.RiverClearance(p) > 6
				and ctx.RailClearance(p) > 10
				and not ctx.IsReserved(p, 3)
				and not ctx.InHole(p)
			if free then
				local yaw = rng:Range(0, math.pi)
				local roll = rng:Next()
				if roll < 0.35 then
					Props.Tree(folder, p, rng, rng:Pick({ "Leafy", "Leafy", "Pine", "Maple", "Cherry" }))
				elseif roll < 0.55 then
					-- Huerto: tierra con surcos verdes.
					Build.Decor(
						folder,
						Build.At(p, 0.2, yaw),
						Build.V3(9, 0.4, 7),
						"#6B4F36",
						"Ground",
						{ Name = "Garden" }
					)
					for row = -1, 1 do
						Build.Decor(
							folder,
							Build.At(p, 0.2, yaw) * CFrame.new(0, 0.45, row * 2.2),
							Build.V3(8, 0.6, 0.9),
							"#5E9B3E",
							"Grass"
						)
					end
				elseif roll < 0.7 then
					Build.Decor(
						folder,
						Build.At(p, 0.12, yaw),
						Build.V3(8, 0.2, 14),
						Styles.AsphaltLane,
						"Asphalt",
						{ Name = "Parking" }
					)
					Props.Car(folder, p, Geometry.Rotate({ X = 0, Z = -1 }, yaw), rng)
				elseif roll < 0.8 then
					Build.Box(
						folder,
						Build.At(p, 3, yaw),
						Build.V3(6, 6, 5),
						rng:Pick({ "#8A7A66", "#7F8C8D", "#A39A86" }),
						"CorrodedMetal",
						{
							Name = "Shed",
						}
					)
					Build.Decor(folder, Build.At(p, 6.2, yaw), Build.V3(6.8, 0.4, 5.8), "#5A5F66", "Metal")
				elseif roll < 0.9 then
					Props.Bush(folder, p, rng)
					Props.Bush(folder, Geometry.Add(p, { X = 3, Z = 1 }), rng)
				end
				occupied[occupancyKey(p)] = true
			end
			x += FILL_STEP
		end
		z += FILL_STEP
	end
end

function Blocks.Build(ctx: Context): ()
	for _, district in ctx.Map.Districts do
		fillDistrict(ctx, district)
	end
	fillGaps(ctx)
end

return Blocks
