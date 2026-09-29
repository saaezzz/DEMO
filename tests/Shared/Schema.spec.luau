local Schema = require(game:GetService("ReplicatedStorage").Shared.Network.Schema)

local function check(validator, value)
	local ok = validator(value)
	return ok
end

return {
	["string: tipo y longitud"] = function()
		local validate = Schema.string(5)
		expect(check(validate, "abc")).toBe(true)
		expect(check(validate, "")).toBe(false)
		expect(check(validate, "abcdef")).toBe(false)
		expect(check(validate, 3)).toBe(false)
		expect(check(Schema.string(5, 0), "")).toBe(true)
	end,

	["number: finito, rango y entero"] = function()
		local validate = Schema.number(0, 10)
		expect(check(validate, 5.5)).toBe(true)
		expect(check(validate, -1)).toBe(false)
		expect(check(validate, 11)).toBe(false)
		expect(check(validate, 0 / 0)).toBe(false)
		expect(check(validate, math.huge)).toBe(false)
		expect(check(validate, "5")).toBe(false)
		expect(check(Schema.number(0, 10, true), 2.5)).toBe(false)
		expect(check(Schema.number(0, 10, true), 2)).toBe(true)
	end,

	["boolean"] = function()
		expect(check(Schema.boolean(), false)).toBe(true)
		expect(check(Schema.boolean(), nil)).toBe(false)
		expect(check(Schema.boolean(), 0)).toBe(false)
	end,

	["literal: solo valores del conjunto"] = function()
		local validate = Schema.literal({ "A", "B" })
		expect(check(validate, "A")).toBe(true)
		expect(check(validate, "C")).toBe(false)
		expect(check(validate, nil)).toBe(false)
	end,

	["optional acepta nil y valida el resto"] = function()
		local validate = Schema.optional(Schema.string(3))
		expect(check(validate, nil)).toBe(true)
		expect(check(validate, "ab")).toBe(true)
		expect(check(validate, "abcd")).toBe(false)
	end,

	["record: valida campos y devuelve una tabla nueva"] = function()
		local validate = Schema.record({
			Name = Schema.string(10),
			Count = Schema.optional(Schema.number(0, 5, true)),
		})
		local payload = { Name = "x", Count = 2 }
		local ok, result = validate(payload)
		expect(ok).toBe(true)
		expect(result == payload).toBe(false)
		expect(result).toEqual({ Name = "x", Count = 2 })
	end,

	["record: rechaza campos desconocidos, claves no string y exceso de campos"] = function()
		local validate = Schema.record({ Name = Schema.string(10) })
		expect(check(validate, { Name = "x", Extra = 1 })).toBe(false)
		expect(check(validate, { [1] = "x" })).toBe(false)
		expect(check(validate, { Name = "x", [1] = 1, [2] = 2 })).toBe(false)
		expect(check(validate, "x")).toBe(false)
	end,

	["record: el error indica el campo"] = function()
		local validate = Schema.record({ Name = Schema.string(10) })
		local ok, reason = validate({ Name = 5 })
		expect(ok).toBe(false)
		expect(string.find(reason, "Name", 1, true) ~= nil).toBe(true)
	end,
}
