--!strict

-- Contenido: dónde aparecen los enemigos en Karakura (D-043). Las posiciones
-- salen de los puntos con nombre del mapa (WorldMap), así que se mueven con él.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.Shared.Types.EnemyTypes)
local WorldMap = require(ReplicatedStorage.Shared.Modules.WorldMap)

type EnemySpawn = EnemyTypes.EnemySpawn

local EnemySpawns: { EnemySpawn } = {
	-- Parque Tsubakidai.
	{
		Enemy = "WeakHollow",
		Position = WorldMap.Anchor("TsubakidaiPark", Vector3.new(0, 4, 0)),
		Count = 4,
		Radius = 22,
		RespawnSeconds = 12,
	},
	-- Patio de las ruinas del Hospital Matsukura.
	{
		Enemy = "StandardHollow",
		Position = WorldMap.Anchor("MatsukuraRuins", Vector3.new(0, 4, 0)),
		Count = 2,
		Radius = 10,
		RespawnSeconds = 20,
	},
	-- Explanada de los restos del edificio de carreras.
	{
		Enemy = "EliteHollow",
		Position = WorldMap.Anchor("RacecourseRuins", Vector3.new(0, 4, 0)),
		Count = 1,
		Radius = 0,
		RespawnSeconds = 45,
	},
	-- Jefe: la orilla del río Karasu.
	{
		Enemy = "GreatHollow",
		Position = WorldMap.Anchor("KarasuRiverside", Vector3.new(0, 6, 0)),
		Count = 1,
		Radius = 0,
		RespawnSeconds = 90,
	},
}

return EnemySpawns
