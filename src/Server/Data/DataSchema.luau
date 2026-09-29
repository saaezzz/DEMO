--!strict

-- Versión, plantilla y migraciones del perfil del jugador (D-018).
--
-- Al cambiar el esquema:
--   1. Incrementa VERSION.
--   2. Añade MIGRATIONS[versión anterior] que transforme los datos antiguos.
--   3. Actualiza createTemplate() y PlayerDataTypes.
--   4. Añade un test en tests/Server/DataSchema.spec.luau.
-- Nunca borres datos antiguos sin migrarlos (§59).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Migrator = require(script.Parent.Migrator)

type PlayerData = PlayerDataTypes.PlayerData

local DataSchema = {}

DataSchema.VERSION = 1

-- Perfil de un jugador nuevo. ProfileStore también la usa para rellenar las
-- claves que falten (Reconcile) después de migrar.
function DataSchema.createTemplate(): PlayerData
	return {
		DataVersion = DataSchema.VERSION,
		Race = Races.Default,
		Level = 1,
		Experience = 0,
		Currency = 0,
		Inventory = {},
		Settings = {
			MusicVolume = 0.5,
			SfxVolume = 0.5,
			CameraShake = true,
		},
	}
end

DataSchema.MIGRATIONS = {
	-- 0 -> 1: perfiles anteriores al versionado. No existen perfiles guardados
	-- antes de v1; Reconcile completa las claves que falten.
	[0] = function(_data) end,
} :: Migrator.MigrationTable

return DataSchema
