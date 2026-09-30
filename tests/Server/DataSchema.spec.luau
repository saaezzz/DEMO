local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataSchema = require(ServerScriptService.Server.Data.DataSchema)
local Migrator = require(ServerScriptService.Server.Data.Migrator)
local Races = require(ReplicatedStorage.Shared.Content.Races)

return {
	["la plantilla está en la versión actual"] = function()
		expect(DataSchema.createTemplate().DataVersion).toBe(DataSchema.VERSION)
	end,

	["la plantilla usa una raza existente"] = function()
		expect(Races.Definitions[DataSchema.createTemplate().Race] ~= nil).toBe(true)
	end,

	["cada llamada devuelve una plantilla independiente"] = function()
		local first = DataSchema.createTemplate()
		local second = DataSchema.createTemplate()
		first.Settings.MusicVolume = 0
		expect(second.Settings.MusicVolume).toBe(0.5)
	end,

	["hay migración para cada versión anterior"] = function()
		for version = 0, DataSchema.VERSION - 1 do
			if DataSchema.MIGRATIONS[version] == nil then
				error(`falta la migración {version} -> {version + 1}`)
			end
		end
	end,

	["un perfil sin versión migra a la versión actual"] = function()
		local result = Migrator.Migrate({}, DataSchema.VERSION, DataSchema.MIGRATIONS)
		expect(result.Ok).toBe(true)
		expect(result.Data.DataVersion).toBe(DataSchema.VERSION)
	end,

	["la plantilla solo contiene datos que DataStore puede guardar"] = function()
		local function check(value, path)
			local valueType = typeof(value)
			if valueType == "table" then
				for key, child in value do
					if typeof(key) ~= "string" and typeof(key) ~= "number" then
						error(`{path}: clave no serializable`)
					end
					check(child, `{path}.{tostring(key)}`)
				end
			elseif valueType ~= "string" and valueType ~= "number" and valueType ~= "boolean" then
				error(`{path}: tipo no serializable ({valueType})`)
			end
		end
		check(DataSchema.createTemplate(), "Template")
	end,

	["v1 -> v2 añade misiones sin tocar el resto"] = function()
		local v1 = { DataVersion = 1, Race = "Human", Level = 7, Experience = 30, Currency = 5 }
		local result = Migrator.Migrate(v1, 2, DataSchema.MIGRATIONS)
		expect(result.Ok).toBe(true)
		expect(result.Data.DataVersion).toBe(2)
		expect(result.Data.Level).toBe(7)
		expect(result.Data.Experience).toBe(30)
		expect(result.Data.Quests).toEqual({ Active = {}, Completed = {} })
		-- Migra una copia: el original no cambia.
		expect(v1.Quests).toBeNil()
	end,

	["v1 -> v2 respeta misiones ya existentes"] = function()
		local quests = { Active = { { Id = "Q", Progress = { 1 } } }, Completed = {} }
		local result = Migrator.Migrate({ DataVersion = 1, Quests = quests }, 2, DataSchema.MIGRATIONS)
		expect(result.Data.Quests).toEqual(quests)
	end,
}
