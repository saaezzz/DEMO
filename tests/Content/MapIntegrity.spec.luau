-- Integridad de los datos del mapa activo (D-043): lo que el juego coloca
-- sobre él (anchors) cae dentro del pueblo, fuera de los ríos y de las
-- calles, y los lugares no se pisan entre sí.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local World = require(ReplicatedStorage.Shared.Content.World)
local WorldMap = require(ReplicatedStorage.Shared.Modules.WorldMap)
local PathLogic = require(ReplicatedStorage.Shared.Modules.PathLogic)
local EnemySpawns = require(ServerScriptService.Server.Content.EnemySpawns)
local TrainingDummies = require(ServerScriptService.Server.Content.TrainingDummies)
local AmbientZones = require(ServerScriptService.Server.Content.AmbientZones)

local ROAD_WIDTH = { Arterial = 24, Street = 16 }
-- Tipos de lugar que sabe construir tools/worldgen/Landmarks.
local KNOWN_KINDS = {
	TrainingShop = true,
	Clinic = true,
	House = true,
	Dojo = true,
	SmallApartment = true,
	Ruins = true,
	HighSchool = true,
	School = true,
	Hospital = true,
	Station = true,
	Mall = true,
	Supermarket = true,
	ShopStreet = true,
	Shrine = true,
	RacecourseRuins = true,
}

local function distanceToSegment(p, a, b)
	local abx, abz = b.X - a.X, b.Z - a.Z
	local lengthSq = abx * abx + abz * abz
	local t = if lengthSq > 0 then math.clamp(((p.X - a.X) * abx + (p.Z - a.Z) * abz) / lengthSq, 0, 1) else 0
	local dx, dz = p.X - (a.X + abx * t), p.Z - (a.Z + abz * t)
	return math.sqrt(dx * dx + dz * dz)
end

local function distanceToPolyline(p, points, closed)
	local best = math.huge
	for i = 1, #points - 1 do
		best = math.min(best, distanceToSegment(p, points[i], points[i + 1]))
	end
	if closed then
		best = math.min(best, distanceToSegment(p, points[#points], points[1]))
	end
	return best
end

local function inPolygon(p, polygon)
	local inside = false
	local j = #polygon
	for i = 1, #polygon do
		local a, b = polygon[i], polygon[j]
		if (a.Z > p.Z) ~= (b.Z > p.Z) and p.X < (b.X - a.X) * (p.Z - a.Z) / (b.Z - a.Z) + a.X then
			inside = not inside
		end
		j = i
	end
	return inside
end

local function riverClearance(p)
	local best = math.huge
	for _, river in World.Rivers do
		local half = river.WaterWidth / 2 + river.FloodWidth + river.BankWidth
		best = math.min(best, distanceToPolyline(p, PathLogic.Smooth(river.Points, 10)) - half)
	end
	return best
end

local function roadClearance(p)
	local best = math.huge
	for _, road in World.Roads do
		best = math.min(best, distanceToPolyline(p, road.Points, road.Closed) - ROAD_WIDTH[road.Kind] / 2)
	end
	return best
end

-- ¿Está p dentro del rectángulo (girado) de un lugar?
local function inRect(entry, p, margin)
	local yaw = math.rad(entry.Rotation)
	local dx, dz = p.X - entry.Position.X, p.Z - entry.Position.Z
	local lx = dx * math.cos(yaw) - dz * math.sin(yaw)
	local lz = dx * math.sin(yaw) + dz * math.cos(yaw)
	return math.abs(lx) <= entry.Size.X / 2 + margin and math.abs(lz) <= entry.Size.Z / 2 + margin
end

local function corners(entry)
	local yaw = math.rad(entry.Rotation)
	local result = {}
	for _, sign in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 }, { 0, 0 } } do
		local lx, lz = sign[1] * entry.Size.X / 2, sign[2] * entry.Size.Z / 2
		table.insert(result, {
			X = entry.Position.X + lx * math.cos(yaw) + lz * math.sin(yaw),
			Z = entry.Position.Z - lx * math.sin(yaw) + lz * math.cos(yaw),
		})
	end
	return result
end

return {
	["los anchors del mapa están dentro del pueblo y fuera de ríos y calles"] = function()
		for name, anchor in World.Anchors do
			local p = { X = anchor.X, Z = anchor.Z }
			if not inPolygon(p, World.TownBoundary) then
				error(`anchor {name}: fuera del pueblo`)
			end
			if riverClearance(p) < 0 then
				error(`anchor {name}: dentro de un río`)
			end
			if anchor.Y >= 0 and roadClearance(p) < 0 then
				error(`anchor {name}: encima de una calle`)
			end
		end
	end,

	["los lugares y parques tienen un tipo conocido y no pisan ríos ni calles"] = function()
		local entries = {}
		for _, landmark in World.Landmarks do
			if not KNOWN_KINDS[landmark.Kind] then
				error(`lugar {landmark.Id}: tipo sin constructor "{landmark.Kind}"`)
			end
			table.insert(entries, landmark)
		end
		for _, park in World.Parks do
			table.insert(entries, park)
		end
		for _, entry in entries do
			for _, p in corners(entry) do
				if riverClearance(p) < 0 then
					error(`{entry.Id}: la parcela entra en un río`)
				end
				-- La estación se cruza con la vía y las calles de acceso a propósito.
				if entry.Kind ~= "Station" and roadClearance(p) < 0 then
					error(`{entry.Id}: la parcela pisa una calle`)
				end
			end
		end
	end,

	["los lugares y parques no se solapan"] = function()
		local entries = {}
		for _, landmark in World.Landmarks do
			table.insert(entries, landmark)
		end
		for _, park in World.Parks do
			table.insert(entries, park)
		end
		for i, a in entries do
			for j, b in entries do
				if i < j then
					for _, p in corners(b) do
						if inRect(a, p, -1) then
							error(`{a.Id} y {b.Id} se solapan`)
						end
					end
				end
			end
		end
	end,

	["la galería subterránea queda en línea con la entrada del túnel"] = function()
		local underground = World.Underground
		local shop
		for _, landmark in World.Landmarks do
			if landmark.Id == underground.Landmark then
				shop = landmark
			end
		end
		expect(shop ~= nil).toBe(true)
		expect(shop.Rotation).toBe(0)
		expect(math.abs(underground.Center.X - (shop.Position.X - 24)) < 0.01).toBe(true)
		expect(underground.Center.Z - underground.Size / 2 > shop.Position.Z + shop.Size.Z / 2).toBe(true)
		expect(underground.FloorY < underground.CeilingY).toBe(true)
		expect(underground.CeilingY < -24).toBe(true)
	end,

	["enemigos, muñecos y zonas usan puntos del mapa"] = function()
		for _, spawn in EnemySpawns do
			local p = { X = spawn.Position.X, Z = spawn.Position.Z }
			expect(inPolygon(p, World.TownBoundary)).toBe(true)
		end
		local ground = WorldMap.Anchor("TrainingGround")
		for _, dummy in TrainingDummies do
			expect(math.abs(dummy.Position.Y - ground.Y) < 10).toBe(true)
		end
		for _, zone in AmbientZones.Zones do
			expect(inPolygon({ X = zone.Center.X, Z = zone.Center.Z }, World.TownBoundary)).toBe(true)
		end
	end,

	["WorldMap.Anchor falla con un anchor inexistente"] = function()
		expect(WorldMap.HasAnchor("Spawn")).toBe(true)
		expect(pcall(WorldMap.Anchor, "NoExiste")).toBe(false)
	end,
}
