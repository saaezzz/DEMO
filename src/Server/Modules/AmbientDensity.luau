--!strict

-- Densidad ambiental en un punto (D-041). Lógica pura: las zonas llegan como
-- datos (Server/Content/AmbientZones).

export type AmbientZone = {
	Id: string,
	DisplayName: string,
	Center: Vector3,
	-- Alcance horizontal (la altura no cuenta).
	Radius: number,
	-- Multiplicador de la regeneración de los recursos con AmbientScaling.
	Density: number,
}

local AmbientDensity = {}

-- Densidad en `position` y la zona que la da (nil = fuera de toda zona).
-- Si hay varias zonas, gana la más densa.
function AmbientDensity.At(position: Vector3, zones: { AmbientZone }, defaultDensity: number): (number, AmbientZone?)
	local best: AmbientZone? = nil
	for _, zone in zones do
		local offset = position - zone.Center
		local inside = Vector3.new(offset.X, 0, offset.Z).Magnitude <= zone.Radius
		if inside and (best == nil or zone.Density > best.Density) then
			best = zone
		end
	end
	if best == nil then
		return defaultDensity, nil
	end
	return best.Density, best
end

return AmbientDensity
