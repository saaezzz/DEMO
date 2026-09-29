local Migrator = require(game:GetService("ServerScriptService").Server.Data.Migrator)

local MIGRATIONS = {
	[0] = function(data)
		data.Gold = data.Gold or 0
	end,
	[1] = function(data)
		data.Currency = data.Gold
		data.Gold = nil
	end,
}

return {
	["datos en la versión actual no se migran"] = function()
		local result = Migrator.Migrate({ DataVersion = 2, Currency = 5 }, 2, MIGRATIONS)
		expect(result.Ok).toBe(true)
		expect(result.Data).toBeNil()
	end,

	["aplica las migraciones en orden y actualiza DataVersion"] = function()
		local result = Migrator.Migrate({ DataVersion = 0, Gold = 7 }, 2, MIGRATIONS)
		expect(result.Ok).toBe(true)
		expect(result.Data).toEqual({ DataVersion = 2, Currency = 7 })
	end,

	["datos sin DataVersion se tratan como versión 0"] = function()
		local result = Migrator.Migrate({ Gold = 3 }, 2, MIGRATIONS)
		expect(result.Ok).toBe(true)
		expect(result.Data.Currency).toBe(3)
		expect(result.Data.DataVersion).toBe(2)
	end,

	["nunca modifica los datos originales"] = function()
		local original = { DataVersion = 0, Gold = 7, Nested = { A = 1 } }
		local result = Migrator.Migrate(original, 2, MIGRATIONS)
		expect(original).toEqual({ DataVersion = 0, Gold = 7, Nested = { A = 1 } })
		expect(result.Data.Nested == original.Nested).toBe(false)
	end,

	["rechaza datos de una versión futura sin tocarlos"] = function()
		local original = { DataVersion = 5, Currency = 1 }
		local result = Migrator.Migrate(original, 2, MIGRATIONS)
		expect(result.Ok).toBe(false)
		expect(result.Error).toBe("FutureVersion")
		expect(original.DataVersion).toBe(5)
	end,

	["rechaza DataVersion inválido"] = function()
		for _, version in { "1", -1, 1.5 } do
			local result = Migrator.Migrate({ DataVersion = version }, 2, MIGRATIONS)
			expect(result.Ok).toBe(false)
			expect(result.Error).toBe("InvalidVersion")
		end
	end,

	["falla si falta una migración intermedia"] = function()
		local result = Migrator.Migrate({ DataVersion = 0 }, 3, MIGRATIONS)
		expect(result.Ok).toBe(false)
		expect(result.Error).toBe("MissingMigration")
	end,

	["un error en una migración no deja datos a medio migrar"] = function()
		local original = { DataVersion = 0 }
		local result = Migrator.Migrate(original, 1, {
			[0] = function(data)
				data.Partial = true
				error("rota")
			end,
		})
		expect(result.Ok).toBe(false)
		expect(result.Error).toBe("MigrationError")
		expect(result.Data).toBeNil()
		expect(original.Partial).toBeNil()
	end,
}
