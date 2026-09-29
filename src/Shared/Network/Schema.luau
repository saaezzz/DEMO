--!strict

-- Validadores declarativos para payloads de red (D-016). Luau puro.
--
--   local validate = Schema.record({
--       Type = Schema.literal({ "Attack", "Block" }),
--       ComboId = Schema.optional(Schema.string(64)),
--   })
--   local ok, result = validate(payload) -- result = copia saneada o mensaje de error
--
-- Reglas: los strings exigen longitud máxima, los números deben ser finitos y
-- estar en rango, y los records rechazan claves desconocidas (lo que también
-- limita el tamaño del payload).

-- Devuelve (true, valorSaneado) o (false, mensajeDeError).
export type Validator = (value: unknown) -> (boolean, any)

local Schema = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

function Schema.string(maxLength: number, minLength: number?): Validator
	local minimum = minLength or 1
	return function(value)
		if typeof(value) ~= "string" then
			return false, "se esperaba string"
		end
		if #value < minimum or #value > maxLength then
			return false, `longitud fuera de rango [{minimum}, {maxLength}]`
		end
		return true, value
	end
end

function Schema.number(min: number, max: number, integer: boolean?): Validator
	return function(value)
		if typeof(value) ~= "number" or not isFinite(value) then
			return false, "se esperaba un número finito"
		end
		if value < min or value > max then
			return false, `número fuera de rango [{min}, {max}]`
		end
		if integer and value % 1 ~= 0 then
			return false, "se esperaba un entero"
		end
		return true, value
	end
end

function Schema.boolean(): Validator
	return function(value)
		if typeof(value) ~= "boolean" then
			return false, "se esperaba boolean"
		end
		return true, value
	end
end

-- Uno de un conjunto cerrado de strings.
function Schema.literal(values: { string }): Validator
	local allowed: { [string]: boolean } = {}
	for _, allowedValue in values do
		allowed[allowedValue] = true
	end
	return function(value)
		if typeof(value) ~= "string" or not allowed[value] then
			return false, "valor no permitido"
		end
		return true, value
	end
end

function Schema.optional(inner: Validator): Validator
	return function(value)
		if value == nil then
			return true, nil
		end
		return inner(value)
	end
end

-- Tabla con un conjunto cerrado de campos string. Devuelve una tabla nueva:
-- el servidor nunca usa la tabla recibida del cliente.
function Schema.record(fields: { [string]: Validator }): Validator
	local fieldCount = 0
	for _ in fields do
		fieldCount += 1
	end

	return function(value)
		if typeof(value) ~= "table" then
			return false, "se esperaba una tabla"
		end
		local raw = value :: { [unknown]: unknown }

		local keyCount = 0
		for key in raw do
			keyCount += 1
			if keyCount > fieldCount then
				return false, "demasiados campos"
			end
			if typeof(key) ~= "string" or fields[key] == nil then
				return false, `campo no permitido: {tostring(key)}`
			end
		end

		local result: { [string]: any } = {}
		for name, validate in fields do
			local ok, fieldResult = validate(raw[name])
			if not ok then
				return false, `{name}: {fieldResult}`
			end
			result[name] = fieldResult
		end
		return true, result
	end
end

return Schema
