--!strict

-- Migración de datos persistentes por versiones (constitución §59, D-018).
-- Luau puro. Nunca modifica los datos recibidos: migra una copia y la
-- devuelve, de modo que un fallo a mitad no deja datos a medio migrar.

export type Migration = (data: { [string]: any }) -> ()
-- migrations[n] transforma datos de la versión n a la n + 1.
export type MigrationTable = { [number]: Migration }

export type MigrationResult = {
	Ok: boolean,
	-- Copia migrada; nil si ya estaba en la versión actual o si falló.
	Data: { [string]: any }?,
	-- "FutureVersion", "InvalidVersion", "MissingMigration" o "MigrationError".
	Error: string?,
	Message: string?,
}

local function deepCopy<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value :: any do
		copy[deepCopy(key)] = deepCopy(child)
	end
	return copy :: any
end

local Migrator = {}

-- Datos sin DataVersion se consideran versión 0 (anteriores al versionado).
function Migrator.GetVersion(data: { [string]: any }): number?
	local version = data.DataVersion
	if version == nil then
		return 0
	end
	if typeof(version) ~= "number" or version < 0 or version % 1 ~= 0 then
		return nil
	end
	return version
end

function Migrator.Migrate(data: { [string]: any }, targetVersion: number, migrations: MigrationTable): MigrationResult
	local version = Migrator.GetVersion(data)
	if version == nil then
		return { Ok = false, Error = "InvalidVersion", Message = `DataVersion inválido: {tostring(data.DataVersion)}` }
	end

	-- Datos guardados por una versión más nueva del juego (p. ej. tras un
	-- rollback del servidor): no se tocan para no perder información.
	if version > targetVersion then
		return {
			Ok = false,
			Error = "FutureVersion",
			Message = `datos en versión {version}, servidor en {targetVersion}`,
		}
	end

	if version == targetVersion then
		return { Ok = true }
	end

	local migrated = deepCopy(data)
	while version < targetVersion do
		local migration = migrations[version]
		if migration == nil then
			return { Ok = false, Error = "MissingMigration", Message = `falta la migración {version} -> {version + 1}` }
		end

		local ok, err = pcall(function()
			migration(migrated)
		end)
		if not ok then
			return {
				Ok = false,
				Error = "MigrationError",
				Message = `migración {version} -> {version + 1}: {tostring(err)}`,
			}
		end

		version += 1
		migrated.DataVersion = version
	end

	return { Ok = true, Data = migrated }
end

return Migrator
