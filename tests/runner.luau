--!strict

-- Ejecuta los tests *.spec.luau con Lune (D-006).
--   lune run tests/runner            -- todos
--   lune run tests/runner Signal     -- solo specs cuyo nombre contenga "Signal"
--
-- Cada spec devuelve una tabla { ["descripción"] = function() ... end }.
-- Cada archivo spec recibe un entorno nuevo (módulos recién cargados).

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local RobloxEnvironment = require("./lib/RobloxEnvironment")
local expect = require("./lib/expect")

local TESTS_DIR = "tests"
local SOURCEMAP_PATH = "sourcemap.json"

local function generateSourcemap(): ()
	local result = process.exec(
		"rojo",
		{ "sourcemap", "default.project.json", "--include-non-scripts", "--output", SOURCEMAP_PATH }
	)
	if not result.ok then
		error("No se pudo generar el sourcemap con Rojo:\n" .. result.stderr, 0)
	end
end

local function findSpecs(directory: string, results: { string }): { string }
	for _, entry in fs.readDir(directory) do
		local path = directory .. "/" .. entry
		if fs.isDir(path) then
			findSpecs(path, results)
		elseif string.sub(entry, -10) == ".spec.luau" then
			table.insert(results, path)
		end
	end
	table.sort(results)
	return results
end

local function sortedKeys(tests: { [string]: () -> () }): { string }
	local names = {}
	for name in tests do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

generateSourcemap()
local sourcemap = serde.decode("json", fs.readFile(SOURCEMAP_PATH))
local filter = process.args[1]

local passed, failed = 0, 0
local failures: { string } = {}

for _, specPath in findSpecs(TESTS_DIR, {}) do
	if filter == nil or string.find(specPath, filter, 1, true) then
		local environment = RobloxEnvironment.new(sourcemap)
		local loaded, tests = pcall(environment.loadFile, specPath, { expect = expect })

		if not loaded then
			failed += 1
			table.insert(failures, `{specPath}\n    error al cargar: {tests}`)
			print(`✗ {specPath} (no se pudo cargar)`)
		else
			print(specPath)
			for _, name in sortedKeys(tests) do
				local ok, err = pcall(tests[name])
				if ok then
					passed += 1
					print(`  ✓ {name}`)
				else
					failed += 1
					table.insert(failures, `{specPath} › {name}\n    {err}`)
					print(`  ✗ {name}`)
				end
			end
		end
	end
end

print(`\n{passed} pasados, {failed} fallidos`)
if failed > 0 then
	print("\nFallos:")
	for _, failure in failures do
		print("- " .. failure)
	end
	process.exit(1)
end
