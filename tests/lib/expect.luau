--!strict

-- Aserciones mínimas estilo Jest:  expect(valor).toBe(esperado)

local function format(value: any): string
	if typeof(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if typeof(a) ~= "table" or typeof(b) ~= "table" then
		return false
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function fail(message: string): never
	error(message, 3)
end

local function expect(actual: any)
	local assertions = {}

	function assertions.toBe(expected: any): ()
		if actual ~= expected then
			fail(`se esperaba {format(expected)}, se obtuvo {format(actual)}`)
		end
	end

	function assertions.toEqual(expected: any): ()
		if not deepEqual(actual, expected) then
			fail(`se esperaba una tabla igual a {format(expected)}, se obtuvo {format(actual)}`)
		end
	end

	function assertions.toBeNil(): ()
		if actual ~= nil then
			fail(`se esperaba nil, se obtuvo {format(actual)}`)
		end
	end

	function assertions.toBeTruthy(): ()
		if not actual then
			fail(`se esperaba un valor verdadero, se obtuvo {format(actual)}`)
		end
	end

	function assertions.toBeFalsy(): ()
		if actual then
			fail(`se esperaba un valor falso, se obtuvo {format(actual)}`)
		end
	end

	function assertions.toBeCloseTo(expected: number, epsilon: number?): ()
		if typeof(actual) ~= "number" or math.abs(actual - expected) > (epsilon or 1e-6) then
			fail(`se esperaba ~{format(expected)}, se obtuvo {format(actual)}`)
		end
	end

	-- actual debe ser una función; pattern (opcional) se busca en el mensaje de error.
	function assertions.toThrow(pattern: string?): ()
		local ok, err = pcall(actual)
		if ok then
			fail("se esperaba que la función lanzara un error")
		end
		if pattern ~= nil and not string.find(tostring(err), pattern, 1, true) then
			fail(`el error {format(tostring(err))} no contiene {format(pattern)}`)
		end
	end

	return assertions
end

return expect
