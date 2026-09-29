local Validator = require(game:GetService("ServerScriptService").Server.Modules.CombatIntentValidator)

local function isValid(payload)
	local ok = Validator.Validate(payload)
	return ok
end

return {
	["acepta intents válidos"] = function()
		expect(isValid({ Type = "Attack", ComboId = "BasicSlash" })).toBe(true)
		expect(isValid({ Type = "Block" })).toBe(true)
		expect(isValid({ Type = "Dash" })).toBe(true)
		expect(isValid({ Type = "Shunpo" })).toBe(false)
	end,

	["devuelve una copia saneada, no la tabla del cliente"] = function()
		local payload = { Type = "Attack", ComboId = "BasicSlash" }
		local _, intent = Validator.Validate(payload)
		expect(intent == payload).toBe(false)
		expect(intent).toEqual({ Type = "Attack", ComboId = "BasicSlash" })
	end,

	["rechaza payloads que no son tablas"] = function()
		expect(isValid(nil)).toBe(false)
		expect(isValid(5)).toBe(false)
		expect(isValid("Attack")).toBe(false)
	end,

	["rechaza tipos desconocidos o mal tipados"] = function()
		expect(isValid({ Type = "Nuke" })).toBe(false)
		expect(isValid({ Type = 1 })).toBe(false)
		expect(isValid({})).toBe(false)
	end,

	["rechaza campos no permitidos"] = function()
		expect(isValid({ Type = "Attack", Damage = 9999 })).toBe(false)
		expect(isValid({ [1] = "Attack" })).toBe(false)
	end,

	["rechaza payloads demasiado grandes"] = function()
		local payload = { Type = "Attack" }
		for index = 1, 100 do
			payload[index] = index
		end
		local ok, reason = Validator.Validate(payload)
		expect(ok).toBe(false)
		expect(reason).toBeTruthy()
	end,

	["valida ComboId"] = function()
		expect(isValid({ Type = "Attack", ComboId = 5 })).toBe(false)
		expect(isValid({ Type = "Attack", ComboId = "" })).toBe(false)
		expect(isValid({ Type = "Attack", ComboId = string.rep("a", 65) })).toBe(false)
		expect(isValid({ Type = "Attack", ComboId = string.rep("a", 64) })).toBe(true)
	end,
}
