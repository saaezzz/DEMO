local DropLogic = require(game:GetService("ServerScriptService").Server.Modules.DropLogic)

local function fixedRandom(rolls, amount)
	local index = 0
	return {
		Chance = function()
			index += 1
			return rolls[index]
		end,
		Between = function(min, _max)
			return amount or min
		end,
	}
end

local DROPS = {
	{ Item = "A", Chance = 0.5, Min = 1, Max = 3 },
	{ Item = "B", Chance = 0.1, Min = 1, Max = 1 },
}

return {
	["cae lo que supera la tirada de probabilidad"] = function()
		local result = DropLogic.Roll(DROPS, fixedRandom({ 0.2, 0.5 }, 2))
		expect(result).toEqual({ { Item = "A", Quantity = 2 } })
	end,

	["sin suerte no cae nada"] = function()
		expect(DropLogic.Roll(DROPS, fixedRandom({ 0.9, 0.9 }))).toEqual({})
	end,

	["cada entrada se tira por separado"] = function()
		local result = DropLogic.Roll(DROPS, fixedRandom({ 0, 0 }))
		expect(#result).toBe(2)
	end,
}
