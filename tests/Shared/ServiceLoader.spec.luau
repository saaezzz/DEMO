local ServiceLoader = require(game:GetService("ReplicatedStorage").Shared.Utils.ServiceLoader)

local function recordingService(name, log, options)
	local service = { Name = name }
	if not (options and options.noInit) then
		function service:Init()
			table.insert(log, name .. ":Init")
		end
	end
	function service:Start()
		table.insert(log, name .. ":Start")
	end
	return service
end

return {
	["ejecuta todos los Init en orden antes de cualquier Start"] = function()
		local log = {}
		ServiceLoader.Run({ recordingService("A", log), recordingService("B", log) })
		expect(log).toEqual({ "A:Init", "B:Init", "A:Start", "B:Start" })
	end,

	["Init y Start son opcionales"] = function()
		local log = {}
		ServiceLoader.Run({ recordingService("A", log, { noInit = true }), { Name = "Empty" } })
		expect(log).toEqual({ "A:Start" })
	end,

	["pasa el propio servicio como self"] = function()
		local received
		local service = { Name = "Self" }
		function service:Init()
			received = self
		end
		ServiceLoader.Run({ service })
		expect(received).toBe(service)
	end,

	["un fallo indica servicio y fase y detiene el arranque"] = function()
		local log = {}
		local broken = { Name = "Broken" }
		function broken:Init()
			error("sin datos")
		end

		expect(function()
			ServiceLoader.Run({ broken, recordingService("After", log) })
		end).toThrow("Broken:Init falló")
		expect(#log).toBe(0)
	end,

	["rechaza servicios duplicados"] = function()
		expect(function()
			ServiceLoader.Run({ { Name = "Dup" }, { Name = "Dup" } })
		end).toThrow("servicio duplicado: Dup")
	end,

	["rechaza servicios sin Name"] = function()
		expect(function()
			ServiceLoader.Run({ {} })
		end).toThrow("no tiene Name")
	end,
}
