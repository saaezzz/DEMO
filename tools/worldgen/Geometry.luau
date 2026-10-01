--!strict

-- Geometría 2D en el plano del suelo (X, Z). Puntos como tablas { X, Z }.

local PathLogic = require("../../src/Shared/Modules/PathLogic")

export type Point = { X: number, Z: number }

-- Rectángulo girado: centro, medio tamaño y giro (radianes, alrededor de Y).
export type Rect = {
	Center: Point,
	HalfX: number,
	HalfZ: number,
	Yaw: number,
}

local Geometry = {}

function Geometry.Point(x: number, z: number): Point
	return { X = x, Z = z }
end

function Geometry.Add(a: Point, b: Point): Point
	return { X = a.X + b.X, Z = a.Z + b.Z }
end

function Geometry.Sub(a: Point, b: Point): Point
	return { X = a.X - b.X, Z = a.Z - b.Z }
end

function Geometry.Scale(a: Point, k: number): Point
	return { X = a.X * k, Z = a.Z * k }
end

function Geometry.Length(a: Point): number
	return math.sqrt(a.X * a.X + a.Z * a.Z)
end

function Geometry.Distance(a: Point, b: Point): number
	return Geometry.Length(Geometry.Sub(a, b))
end

function Geometry.Unit(a: Point): Point
	local length = Geometry.Length(a)
	if length < 1e-9 then
		return { X = 0, Z = 0 }
	end
	return { X = a.X / length, Z = a.Z / length }
end

function Geometry.Lerp(a: Point, b: Point, t: number): Point
	return { X = a.X + (b.X - a.X) * t, Z = a.Z + (b.Z - a.Z) * t }
end

-- Normal a la izquierda de una dirección (girando 90° en el plano).
function Geometry.Normal(direction: Point): Point
	return { X = direction.Z, Z = -direction.X }
end

-- Giro (radianes) que hace que el eje +Z local de una pieza apunte a `direction`.
function Geometry.YawForBack(direction: Point): number
	return math.atan2(direction.X, direction.Z)
end

-- Giro que hace que la pieza "mire" (-Z local) hacia `direction`.
function Geometry.YawForLook(direction: Point): number
	return math.atan2(-direction.X, -direction.Z)
end

-- Punto local (x, z) de una pieza girada `yaw` en coordenadas del mundo.
function Geometry.Rotate(local_: Point, yaw: number): Point
	local cos, sin = math.cos(yaw), math.sin(yaw)
	return { X = local_.X * cos + local_.Z * sin, Z = -local_.X * sin + local_.Z * cos }
end

function Geometry.ToLocal(world: Point, origin: Point, yaw: number): Point
	return Geometry.Rotate(Geometry.Sub(world, origin), -yaw)
end

function Geometry.ToWorld(local_: Point, origin: Point, yaw: number): Point
	return Geometry.Add(origin, Geometry.Rotate(local_, yaw))
end

function Geometry.DistanceToSegment(p: Point, a: Point, b: Point): number
	local ab = Geometry.Sub(b, a)
	local lengthSq = ab.X * ab.X + ab.Z * ab.Z
	if lengthSq < 1e-9 then
		return Geometry.Distance(p, a)
	end
	local t = math.clamp(((p.X - a.X) * ab.X + (p.Z - a.Z) * ab.Z) / lengthSq, 0, 1)
	return Geometry.Distance(p, { X = a.X + ab.X * t, Z = a.Z + ab.Z * t })
end

function Geometry.DistanceToPolyline(p: Point, points: { Point }, closed: boolean?): number
	local best = math.huge
	for i = 1, #points - 1 do
		best = math.min(best, Geometry.DistanceToSegment(p, points[i], points[i + 1]))
	end
	if closed and #points > 2 then
		best = math.min(best, Geometry.DistanceToSegment(p, points[#points], points[1]))
	end
	return best
end

function Geometry.PointInPolygon(p: Point, polygon: { Point }): boolean
	local inside = false
	local j = #polygon
	for i = 1, #polygon do
		local a, b = polygon[i], polygon[j]
		if (a.Z > p.Z) ~= (b.Z > p.Z) then
			local x = (b.X - a.X) * (p.Z - a.Z) / (b.Z - a.Z) + a.X
			if p.X < x then
				inside = not inside
			end
		end
		j = i
	end
	return inside
end

-- Intersección de los segmentos ab y cd: (punto, t en ab) o nil.
function Geometry.SegmentIntersection(a: Point, b: Point, c: Point, d: Point): (Point?, number?)
	local r = Geometry.Sub(b, a)
	local s = Geometry.Sub(d, c)
	local denominator = r.X * s.Z - r.Z * s.X
	if math.abs(denominator) < 1e-9 then
		return nil, nil
	end
	local ca = Geometry.Sub(c, a)
	local t = (ca.X * s.Z - ca.Z * s.X) / denominator
	local u = (ca.X * r.Z - ca.Z * r.X) / denominator
	if t < 0 or t > 1 or u < 0 or u > 1 then
		return nil, nil
	end
	return Geometry.Lerp(a, b, t), t
end

-- Segmentos de una polilínea (cerrada o no) como pares de puntos.
function Geometry.Segments(points: { Point }, closed: boolean?): { { Point } }
	local result: { { Point } } = {}
	for i = 1, #points - 1 do
		table.insert(result, { points[i], points[i + 1] })
	end
	if closed and #points > 2 then
		table.insert(result, { points[#points], points[1] })
	end
	return result
end

-- Curva suave (Catmull-Rom) que pasa por los puntos, con tramos de ~`step` studs.
Geometry.Smooth = PathLogic.Smooth

export type Sample = {
	Position: Point,
	Direction: Point,
	-- Distancia recorrida desde el inicio.
	Distance: number,
}

-- Puntos cada `spacing` studs a lo largo de la polilínea, con su dirección.
function Geometry.SampleEvery(points: { Point }, spacing: number, offset: number?): { Sample }
	local result: { Sample } = {}
	local travelled = 0
	local nextAt = offset or spacing / 2
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = Geometry.Distance(a, b)
		local direction = Geometry.Unit(Geometry.Sub(b, a))
		while nextAt <= travelled + length do
			local t = (nextAt - travelled) / length
			table.insert(result, {
				Position = Geometry.Lerp(a, b, t),
				Direction = direction,
				Distance = nextAt,
			})
			nextAt += spacing
		end
		travelled += length
	end
	return result
end

function Geometry.PolylineLength(points: { Point }): number
	local total = 0
	for i = 1, #points - 1 do
		total += Geometry.Distance(points[i], points[i + 1])
	end
	return total
end

-- Punto y dirección más cercanos de la polilínea a `p`.
function Geometry.ClosestOnPolyline(p: Point, points: { Point }): (Point, Point)
	local bestPoint, bestDirection, bestDistance = points[1], { X = 1, Z = 0 }, math.huge
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local ab = Geometry.Sub(b, a)
		local lengthSq = ab.X * ab.X + ab.Z * ab.Z
		if lengthSq > 1e-9 then
			local t = math.clamp(((p.X - a.X) * ab.X + (p.Z - a.Z) * ab.Z) / lengthSq, 0, 1)
			local q = { X = a.X + ab.X * t, Z = a.Z + ab.Z * t }
			local distance = Geometry.Distance(p, q)
			if distance < bestDistance then
				bestPoint, bestDirection, bestDistance = q, Geometry.Unit(ab), distance
			end
		end
	end
	return bestPoint, bestDirection
end

function Geometry.Rect(center: Point, sizeX: number, sizeZ: number, yaw: number): Rect
	return { Center = center, HalfX = sizeX / 2, HalfZ = sizeZ / 2, Yaw = yaw }
end

function Geometry.RectContains(rect: Rect, p: Point, margin: number?): boolean
	local localPoint = Geometry.ToLocal(p, rect.Center, rect.Yaw)
	local m = margin or 0
	return math.abs(localPoint.X) <= rect.HalfX + m and math.abs(localPoint.Z) <= rect.HalfZ + m
end

function Geometry.RectCorners(rect: Rect): { Point }
	local corners: { Point } = {}
	for _, sign in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
		table.insert(
			corners,
			Geometry.ToWorld({ X = sign[1] * rect.HalfX, Z = sign[2] * rect.HalfZ }, rect.Center, rect.Yaw)
		)
	end
	return corners
end

-- Puntos de control de un rectángulo: esquinas, centro y mitades de los lados.
function Geometry.RectSamples(rect: Rect): { Point }
	local samples: { Point } = {}
	for _, sx in { -1, 0, 1 } do
		for _, sz in { -1, 0, 1 } do
			table.insert(samples, Geometry.ToWorld({ X = sx * rect.HalfX, Z = sz * rect.HalfZ }, rect.Center, rect.Yaw))
		end
	end
	return samples
end

function Geometry.PolygonBounds(polygon: { Point }): (Point, Point)
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, p in polygon do
		minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
		minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
	end
	return { X = minX, Z = minZ }, { X = maxX, Z = maxZ }
end

function Geometry.Centroid(polygon: { Point }): Point
	local sx, sz = 0, 0
	for _, p in polygon do
		sx += p.X
		sz += p.Z
	end
	return { X = sx / #polygon, Z = sz / #polygon }
end

-- Área con signo (positiva si los puntos van en sentido antihorario visto desde arriba).
function Geometry.SignedArea(polygon: { Point }): number
	local area = 0
	local j = #polygon
	for i = 1, #polygon do
		area += (polygon[j].X * polygon[i].Z) - (polygon[i].X * polygon[j].Z)
		j = i
	end
	return area / 2
end

local function offsetWithSign(polygon: { Point }, distance: number, orientation: number): { Point }
	local result: { Point } = {}
	local count = #polygon
	for i = 1, count do
		local previous = polygon[(i - 2) % count + 1]
		local current = polygon[i]
		local nextPoint = polygon[i % count + 1]
		local n1 = Geometry.Normal(Geometry.Unit(Geometry.Sub(current, previous)))
		local n2 = Geometry.Normal(Geometry.Unit(Geometry.Sub(nextPoint, current)))
		local bisector = Geometry.Unit(Geometry.Add(n1, n2))
		local cosHalf = math.max(0.35, bisector.X * n1.X + bisector.Z * n1.Z)
		table.insert(result, Geometry.Add(current, Geometry.Scale(bisector, orientation * distance / cosHalf)))
	end
	return result
end

-- Polígono desplazado `distance` studs hacia fuera (vértices en inglete).
function Geometry.OffsetPolygon(polygon: { Point }, distance: number): { Point }
	local grown = offsetWithSign(polygon, distance, 1)
	if math.abs(Geometry.SignedArea(grown)) >= math.abs(Geometry.SignedArea(polygon)) then
		return grown
	end
	return offsetWithSign(polygon, distance, -1)
end

return Geometry
