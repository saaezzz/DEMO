-- Constitución §4: el framework de juego no contiene referencias a la IP.
-- Todo nombre propio de BLEACH debe vivir en carpetas Content (datos
-- sustituibles). Este test recorre el código fuera de Content y falla si
-- encuentra alguno de estos términos (en código o en comentarios).

local fs = require("@lune/fs")

local SOURCE_ROOT = "src"

-- Ampliar estas listas al añadir contenido nuevo.
-- Términos sin ambigüedad: se buscan sin distinguir mayúsculas.
local IP_TERMS = {
	"bleach",
	"shinigami",
	"hollow",
	"quincy",
	"fullbring",
	"visored",
	"reiatsu",
	"reiryoku",
	"reishi",
	"shunpo",
	"hirenkyaku",
	"zanpakuto",
	"shikai",
	"bankai",
	"kido",
	"bakudo",
	"getsuga",
	"ichigo",
	"gotei",
	"karakura",
	"vollst",
	"blut",
	"schrift",
}

-- Términos que también son palabras comunes en español (arrancar, cero,
-- sonido, hierro...): solo cuentan con mayúscula inicial, como nombre propio.
local CASE_SENSITIVE_IP_TERMS = {
	"Arrancar",
	"Cero",
	"Sonido",
	"Hierro",
	"Hado",
	"Resurrecci",
}

local function isContentPath(path)
	return string.find(path, "/Content/", 1, true) ~= nil
end

local function collectSources(directory, results)
	for _, entry in fs.readDir(directory) do
		local path = directory .. "/" .. entry
		if fs.isDir(path) then
			collectSources(path, results)
		elseif string.sub(entry, -5) == ".luau" and not isContentPath(path) then
			table.insert(results, path)
		end
	end
	return results
end

-- Coincidencia al inicio de palabra, contando camelCase ("processShunpo"),
-- pero no dentro de otra palabra: "hado" no debe saltar con "sombreado".
-- `searchIn` es el texto donde se busca (quizá en minúsculas) y `original`
-- la línea tal cual, para detectar mayúsculas de camelCase.
local function findAtWordStart(searchIn, original, term)
	local start = 1
	while true do
		local first, last = string.find(searchIn, term, start, true)
		if first == nil then
			return false
		end
		local before = if first > 1 then string.sub(original, first - 1, first - 1) else ""
		local firstChar = string.sub(original, first, first)
		if not string.match(before, "%a") or string.match(firstChar, "%u") then
			return true
		end
		start = last + 1
	end
end

local function findTerm(line)
	local lowered = string.lower(line)
	for _, term in IP_TERMS do
		if findAtWordStart(lowered, line, term) then
			return term
		end
	end
	for _, term in CASE_SENSITIVE_IP_TERMS do
		if findAtWordStart(line, line, term) then
			return term
		end
	end
	return nil
end

return {
	["el código fuera de Content no menciona términos de la IP"] = function()
		local violations = {}
		for _, path in collectSources(SOURCE_ROOT, {}) do
			local lineNumber = 0
			for line in string.gmatch(fs.readFile(path) .. "\n", "(.-)\r?\n") do
				lineNumber += 1
				local term = findTerm(line)
				if term ~= nil then
					table.insert(violations, `{path}:{lineNumber} ("{term}")`)
				end
			end
		end
		if #violations > 0 then
			error("Referencias a la IP fuera de Content:\n      " .. table.concat(violations, "\n      "))
		end
	end,

	["el detector encuentra términos y respeta los límites de palabra"] = function()
		expect(findTerm("local cost = Reiatsu")).toBe("reiatsu")
		expect(findTerm("-- sombreado de pixeles")).toBeNil()
		expect(findTerm("ShinigamiKit")).toBe("shinigami")
		expect(findTerm("local function processShunpo()")).toBe("shunpo")
		expect(findTerm("SHUNPO_COST = 1")).toBe("shunpo")
		expect(findTerm("-- al arrancar el servidor")).toBeNil()
		expect(findTerm("local damage = 0 -- cero")).toBeNil()
		expect(findTerm("Cero = { Damage = 10 }")).toBe("Cero")
	end,
}
