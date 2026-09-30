--!strict

-- Contenido: dónde aparecen los enemigos (zona de caza de prueba, M3).
-- Al norte del punto de aparición; los muñecos quedan en medio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.Shared.Types.EnemyTypes)

type EnemySpawn = EnemyTypes.EnemySpawn

local EnemySpawns: { EnemySpawn } = {
	{ Enemy = "WeakHollow", Position = Vector3.new(-25, 4, -90), Count = 4, Radius = 14, RespawnSeconds = 12 },
	{ Enemy = "StandardHollow", Position = Vector3.new(25, 4, -110), Count = 2, Radius = 10, RespawnSeconds = 20 },
	{ Enemy = "EliteHollow", Position = Vector3.new(0, 4, -160), Count = 1, Radius = 0, RespawnSeconds = 45 },
	-- Arena del jefe, al fondo de la zona.
	{ Enemy = "GreatHollow", Position = Vector3.new(0, 6, -240), Count = 1, Radius = 0, RespawnSeconds = 90 },
}

return EnemySpawns
