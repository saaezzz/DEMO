--!strict

-- Contenido: zonas con distinta densidad de Reishi ambiental (capa IP, §32,
-- D-041). Los recursos con AmbientScaling (Content/Resources) se regeneran
-- más rápido dentro (Density > 1) o más lento (Density < 1). Fuera de toda
-- zona se usa DefaultDensity. Si hay zonas solapadas, gana la más densa.

local AmbientDensity = require(script.Parent.Parent.Modules.AmbientDensity)

type AmbientZone = AmbientDensity.AmbientZone

local Zones: { AmbientZone } = {
	-- Donde se concentran los Hollows, el aire está cargado de Reishi.
	{
		Id = "HuntingGrounds",
		DisplayName = "Coto de caza",
		Center = Vector3.new(0, 4, -125),
		Radius = 65,
		Density = 1.5,
	},
	{
		Id = "GreatHollowLair",
		DisplayName = "Guarida del Gran Hollow",
		Center = Vector3.new(0, 6, -240),
		Radius = 40,
		Density = 2,
	},
}

return {
	DefaultDensity = 1,
	Zones = Zones,
}
