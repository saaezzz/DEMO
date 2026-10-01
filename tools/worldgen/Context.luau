--!strict

-- Estado compartido del generador: el mapa, la semilla, las carpetas del
-- modelo y lo que ocupa cada cosa (ríos, carreteras, vía, parcelas
-- reservadas) para que los constructores no se pisen.

local Build = require("./Build")
local Geometry = require("./Geometry")
local Rng = require("./Rng")

type Point = Geometry.Point
type Rect = Geometry.Rect

-- Medidas comunes (studs). El suelo está en Y = 0.
local Settings = {
	GroundTop = 0,
	GroundBottom = -24,
	RoadTop = 0.3,
	LaneTop = 0.2,
	SidewalkTop = 0.55,
	SidewalkWidth = 4,
	RoadWidth = { Arterial = 24, Street = 16 },
	LaneWidth = 8,
	-- Cauces: talud de hierba hasta BankBottom, llanura y agua.
	BankBottom = -9,
	WaterTop = -10,
	ChannelBottom = -22,
	RailClearance = 9,
	CellSize = 40,
}

export type RiverInfo = {
	Id: string,
	Points: { Point },
	Half: number,
	WaterHalf: number,
	FloodHalf: number,
}

export type RoadInfo = {
	Id: string,
	Kind: string,
	Points: { Point },
	Closed: boolean,
	Width: number,
	-- Medio ancho con aceras.
	Half: number,
}

type IndexedSegment = {
	A: Point,
	B: Point,
	Half: number,
	Owner: string,
}

-- Índice espacial de segmentos: cada celda guarda los segmentos cercanos.
type SegmentIndex = {
	Cells: { [string]: { IndexedSegment } },
	CellSize: number,
}

local function cellKey(ix: number, iz: number): string
	return ix .. ":" .. iz
end

local function newIndex(cellSize: number): SegmentIndex
	return { Cells = {}, CellSize = cellSize }
end

local function indexInsert(index: SegmentIndex, segment: IndexedSegment, reach: number): ()
	local size = index.CellSize
	local minX = math.floor((math.min(segment.A.X, segment.B.X) - reach) / size)
	local maxX = math.floor((math.max(segment.A.X, segment.B.X) + reach) / size)
	local minZ = math.floor((math.min(segment.A.Z, segment.B.Z) - reach) / size)
	local maxZ = math.floor((math.max(segment.A.Z, segment.B.Z) + reach) / size)
	for ix = minX, maxX do
		for iz = minZ, maxZ do
			local key = cellKey(ix, iz)
			local list = index.Cells[key]
			if list == nil then
				list = {}
				index.Cells[key] = list
			end
			table.insert(list, segment)
		end
	end
end

-- Menor (distancia - medio ancho) a los segmentos cercanos; `huge` si no hay.
local function indexClearance(index: SegmentIndex, p: Point, ignoreOwner: string?): (number, string?)
	local list = index.Cells[cellKey(math.floor(p.X / index.CellSize), math.floor(p.Z / index.CellSize))]
	if list == nil then
		return math.huge, nil
	end
	local best, owner = math.huge, nil
	for _, segment in list do
		if segment.Owner ~= ignoreOwner then
			local clearance = Geometry.DistanceToSegment(p, segment.A, segment.B) - segment.Half
			if clearance < best then
				best, owner = clearance, segment.Owner
			end
		end
	end
	return best, owner
end

export type Context = {
	Map: any,
	Rng: Rng.Rng,
	Settings: typeof(Settings),
	Root: any,
	Folders: { [string]: any },
	Rivers: { RiverInfo },
	Roads: { RoadInfo },
	Rail: { Point },
	Reserved: { Rect },
	Holes: { Rect },
	Warnings: { string },
	-- Consultas (valores > 0 = libre por ese margen).
	RiverClearance: (p: Point) -> number,
	RoadClearance: (p: Point, ignoreRoad: string?) -> (number, string?),
	RailClearance: (p: Point) -> number,
	ShoreZ: (x: number) -> number,
	IsSea: (p: Point, margin: number?) -> boolean,
	IsReserved: (p: Point, margin: number?) -> boolean,
	InHole: (p: Point) -> boolean,
	InTown: (p: Point) -> boolean,
	Warn: (message: string) -> (),
	Folder: (name: string) -> any,
}

local Context = {}

Context.Settings = Settings

function Context.new(map: any): Context
	local root = Build.Folder(nil, "Map")

	local rivers: { RiverInfo } = {}
	local riverIndex = newIndex(Settings.CellSize)
	for _, river in map.Rivers do
		local info: RiverInfo = {
			Id = river.Id,
			Points = Geometry.Smooth(river.Points, 10),
			WaterHalf = river.WaterWidth / 2,
			FloodHalf = river.WaterWidth / 2 + river.FloodWidth,
			Half = river.WaterWidth / 2 + river.FloodWidth + river.BankWidth,
		}
		table.insert(rivers, info)
		for _, pair in Geometry.Segments(info.Points) do
			indexInsert(riverIndex, { A = pair[1], B = pair[2], Half = info.Half, Owner = info.Id }, info.Half + 40)
		end
	end

	local roads: { RoadInfo } = {}
	local roadIndex = newIndex(Settings.CellSize)
	for _, road in map.Roads do
		local width = Settings.RoadWidth[road.Kind]
		local info: RoadInfo = {
			Id = road.Id,
			Kind = road.Kind,
			Points = road.Points,
			Closed = road.Closed == true,
			Width = width,
			Half = width / 2 + Settings.SidewalkWidth,
		}
		table.insert(roads, info)
		for _, pair in Geometry.Segments(info.Points, info.Closed) do
			indexInsert(roadIndex, { A = pair[1], B = pair[2], Half = info.Half, Owner = info.Id }, info.Half + 40)
		end
	end

	local rail = Geometry.Smooth(map.Railway, 8)
	local railIndex = newIndex(Settings.CellSize)
	for _, pair in Geometry.Segments(rail) do
		indexInsert(railIndex, { A = pair[1], B = pair[2], Half = 0, Owner = "Rail" }, 40)
	end

	local reserved: { Rect } = {}
	local function reserve(entry: any): ()
		table.insert(reserved, Geometry.Rect(entry.Position, entry.Size.X, entry.Size.Z, math.rad(entry.Rotation)))
	end
	for _, landmark in map.Landmarks do
		reserve(landmark)
	end
	for _, park in map.Parks do
		reserve(park)
	end

	local ctx: Context
	ctx = {
		Map = map,
		Rng = Rng.new(map.Seed),
		Settings = Settings,
		Root = root,
		Folders = {},
		Rivers = rivers,
		Roads = roads,
		Rail = rail,
		Reserved = reserved,
		Holes = {},
		Warnings = {},
		RiverClearance = function(p: Point): number
			return (indexClearance(riverIndex, p))
		end,
		RoadClearance = function(p: Point, ignoreRoad: string?): (number, string?)
			return indexClearance(roadIndex, p, ignoreRoad)
		end,
		RailClearance = function(p: Point): number
			return (indexClearance(railIndex, p))
		end,
		ShoreZ = function(x: number): number
			local shore = map.Shoreline
			if x <= shore[1].X then
				return shore[1].Z
			end
			for i = 1, #shore - 1 do
				local a, b = shore[i], shore[i + 1]
				if x <= b.X then
					return a.Z + (b.Z - a.Z) * (x - a.X) / (b.X - a.X)
				end
			end
			return shore[#shore].Z
		end,
		IsSea = function(p: Point, margin: number?): boolean
			return p.Z > ctx.ShoreZ(p.X) - (margin or 0)
		end,
		IsReserved = function(p: Point, margin: number?): boolean
			for _, rect in reserved do
				if Geometry.RectContains(rect, p, margin) then
					return true
				end
			end
			return false
		end,
		InHole = function(p: Point): boolean
			for _, rect in ctx.Holes do
				if Geometry.RectContains(rect, p) then
					return true
				end
			end
			return false
		end,
		InTown = function(p: Point): boolean
			return Geometry.PointInPolygon(p, map.TownBoundary)
		end,
		Warn = function(message: string): ()
			table.insert(ctx.Warnings, message)
		end,
		Folder = function(name: string): any
			local folder = ctx.Folders[name]
			if folder == nil then
				folder = Build.Folder(root, name)
				ctx.Folders[name] = folder
			end
			return folder
		end,
	}
	return ctx
end

return Context
