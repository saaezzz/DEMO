local Validator = require(game:GetService("ServerScriptService").Server.Combat.CombatIntentValidator)

local function isValid(payload)
	local ok = Validator.Validate(payload)
	return ok
end

return {
	["acepta intents válidos"] = function()
		for _, action in { "LightAttack", "HeavyAttack", "Block", "Dodge", "Dash", "Sprint" } do
			expect(isValid({ Action = action })).toBe(true)
		end
	end,

	["devuelve una copia saneada, no la tabla del cliente"] = function()
		local payload = { Action = "Block", Active = true }
		local _, intent = Validator.Validate(payload)
		expect(intent == payload).toBe(false)
		expect(intent).toEqual({ Action = "Block", Active = true })
	end,

	["rechaza payloads que no son tablas"] = function()
		expect(isValid(nil)).toBe(false)
		expect(isValid(5)).toBe(false)
		expect(isValid("LightAttack")).toBe(false)
	end,

	["rechaza acciones desconocidas o mal tipadas"] = function()
		expect(isValid({ Action = "Nuke" })).toBe(false)
		expect(isValid({ Action = "Slash1" })).toBe(false)
		expect(isValid({ Action = 1 })).toBe(false)
		expect(isValid({})).toBe(false)
	end,

	["rechaza campos no permitidos"] = function()
		expect(isValid({ Action = "LightAttack", Damage = 9999 })).toBe(false)
		expect(isValid({ Action = "LightAttack", AbilityId = "HeavySlash" })).toBe(false)
		expect(isValid({ [1] = "LightAttack" })).toBe(false)
	end,

	["rechaza payloads demasiado grandes"] = function()
		local payload = { Action = "LightAttack" }
		for index = 1, 100 do
			payload[index] = index
		end
		local ok, reason = Validator.Validate(payload)
		expect(ok).toBe(false)
		expect(reason).toBeTruthy()
	end,

	["valida Active como booleano opcional"] = function()
		expect(isValid({ Action = "Block", Active = true })).toBe(true)
		expect(isValid({ Action = "Sprint", Active = false })).toBe(true)
		expect(isValid({ Action = "Block", Active = "yes" })).toBe(false)
	end,
}
