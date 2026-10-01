--!strict

-- Contenido: zonas con distinta densidad de Reishi ambiental (capa IP, §32,
-- D-041). Los recursos con AmbientScaling (Content/Resources) se regeneran
-- más rápido dentro (Density > 1) o más lento (Density < 1). Fuera de toda
-- zona se usa DefaultDensity. Si hay zonas solapadas, gana la más densa.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldMap = require(ReplicatedStorage.Shared.Modules.WorldMap)
local AmbientDensity = require(script.Parent.Parent.Modules.AmbientDensity)

type AmbientZone = AmbientDensity.AmbientZone

-- Karakura atrae almas y Hollows: donde más se concentran, más Reishi hay.
local Zones: { AmbientZone } = {
	{
		Id = "TsubakidaiPark",
		DisplayName = "Parque Tsubakidai",
		Center = WorldMap.Anchor("TsubakidaiPark"),
		Radius = 75,
		Density = 1.5,
	},
	{
		Id = "MatsukuraRuins",
		DisplayName = "Ruinas del Hospital Matsukura",
		Center = WorldMap.Anchor("MatsukuraRuins"),
		Radius = 60,
		Density = 1.6,
	},
	{
		Id = "RacecourseRuins",
		DisplayName = "Restos del edificio de carreras",
		Center = WorldMap.Anchor("RacecourseRuins"),
		Radius = 80,
		Density = 1.6,
	},
	{
		Id = "KarasuRiverside",
		DisplayName = "Orilla del Karasu",
		Center = WorldMap.Anchor("KarasuRiverside"),
		Radius = 75,
		Density = 2,
	},
	{
		Id = "TrainingGround",
		DisplayName = "Galería subterránea",
		Center = WorldMap.Anchor("TrainingGround"),
		Radius = 130,
		Density = 1.3,
	},
}

return {
	DefaultDensity = 1,
	Zones = Zones,
}
