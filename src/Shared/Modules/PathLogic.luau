--!strict

-- Caminos en el plano del suelo (D-043): suavizar una polilínea y recorrerla.
-- Lógica pura y sin require: la usan el generador del mapa (Lune) y el
-- cliente (el tren sigue la vía con ella).

export type Point = { X: number, Z: number }

local PathLogic = {}

local function distance(a: Point, b: Point): number
	local dx, dz = b.X - a.X, b.Z - a.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- Curva suave (Catmull-Rom) que pasa por todos los puntos, en tramos de
-- unos `step` studs.
function PathLogic.Smooth(points: { Point }, step: number): { Point }
	if #points < 3 then
		return table.clone(points)
	end
	local result: { Point } = {}
	for i = 1, #points - 1 do
		local p0 = points[math.max(i - 1, 1)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[math.min(i + 2, #points)]
		local count = math.max(1, math.ceil(distance(p1, p2) / step))
		for k = 0, count - 1 do
			local t = k / count
			local t2, t3 = t * t, t * t * t
			local function axis(v0: number, v1: number, v2: number, v3: number): number
				return 0.5
					* (
						(2 * v1)
						+ (-v0 + v2) * t
						+ (2 * v0 - 5 * v1 + 4 * v2 - v3) * t2
						+ (-v0 + 3 * v1 - 3 * v2 + v3) * t3
					)
			end
			table.insert(result, { X = axis(p0.X, p1.X, p2.X, p3.X), Z = axis(p0.Z, p1.Z, p2.Z, p3.Z) })
		end
	end
	table.insert(result, points[#points])
	return result
end

function PathLogic.Length(points: { Point }): number
	local total = 0
	for i = 1, #points - 1 do
		total += distance(points[i], points[i + 1])
	end
	return total
end

-- Punto a `travelled` studs del inicio y dirección (unitaria) del tramo.
-- Fuera de rango se queda en el extremo.
function PathLogic.PointAt(points: { Point }, travelled: number): (Point, Point)
	local remaining = math.max(travelled, 0)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = distance(a, b)
		if remaining <= length or i == #points - 1 then
			local t = if length > 0 then math.min(remaining / length, 1) else 0
			local direction = if length > 0
				then { X = (b.X - a.X) / length, Z = (b.Z - a.Z) / length }
				else { X = 1, Z = 0 }
			return { X = a.X + (b.X - a.X) * t, Z = a.Z + (b.Z - a.Z) * t }, direction
		end
		remaining -= length
	end
	return points[1], { X = 1, Z = 0 }
end

-- Distancia sobre el camino del punto más cercano a `p`.
function PathLogic.ProjectDistance(points: { Point }, p: Point): number
	local best, bestAlong, travelled = math.huge, 0, 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = distance(a, b)
		if length > 0 then
			local t = math.clamp(((p.X - a.X) * (b.X - a.X) + (p.Z - a.Z) * (b.Z - a.Z)) / (length * length), 0, 1)
			local q = { X = a.X + (b.X - a.X) * t, Z = a.Z + (b.Z - a.Z) * t }
			local d = distance(p, q)
			if d < best then
				best, bestAlong = d, travelled + length * t
			end
		end
		travelled += length
	end
	return bestAlong
end

return PathLogic
