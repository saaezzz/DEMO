local Logger = require(game:GetService("ReplicatedStorage").Shared.Utils.Logger)

local function capture()
	local lines = {}
	Logger.SetSink(function(level, message)
		table.insert(lines, { level, message })
	end)
	return lines
end

return {
	["formatea nivel, ámbito y mensaje"] = function()
		local lines = capture()
		Logger.SetLevel("Debug")

		Logger.new("Combat"):Info("Combo %s registrado", "BasicSlash")

		expect(lines).toEqual({ { "Info", "[Info][Combat] Combo BasicSlash registrado" } })
	end,

	["filtra por debajo del nivel mínimo"] = function()
		local lines = capture()
		Logger.SetLevel("Warn")
		local log = Logger.new("Test")

		log:Debug("a")
		log:Info("b")
		log:Warn("c")
		log:Error("d")

		expect(#lines).toBe(2)
		expect(lines[1][1]).toBe("Warn")
		expect(lines[2][1]).toBe("Error")
	end,

	["sin argumentos no aplica formato (admite %)"] = function()
		local lines = capture()
		Logger.SetLevel("Info")

		Logger.new("Test"):Info("100% listo")

		expect(lines[1][2]).toBe("[Info][Test] 100% listo")
	end,

	["GetLevel devuelve el nivel actual"] = function()
		Logger.SetLevel("Error")
		expect(Logger.GetLevel()).toBe("Error")
	end,
}
