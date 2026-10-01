--!strict

-- Generador del mapa (D-043). Construye un modelo por cada mapa de
-- src/Shared/Content/Maps y lo guarda en world/<Mapa>.rbxm, que Rojo
-- sincroniza como Workspace.Map. También deja una vista cenital en
-- world/<Mapa>_preview.png.
--
--   lune run tools/worldgen            (todos los mapas)
--   lune run tools/worldgen <Mapa>     (solo uno)
--
-- La semilla está en los datos: con los mismos datos sale el mismo mapa.
-- Los mapas son datos puros (sin require), así que se cargan directamente.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Backdrop = require("@self/Backdrop")
local Blocks = require("@self/Blocks")
local Build = require("@self/Build")
local Context = require("@self/Context")
local Ground = require("@self/Ground")
local Landmarks = require("@self/Landmarks")
local Parks = require("@self/Parks")
local Preview = require("@self/Preview")
local Props = require("@self/Props")
local Rail = require("@self/Rail")
local Rivers = require("@self/Rivers")
local Roads = require("@self/Roads")

local OUTPUT_DIRECTORY = "world"
local MAPS_DIRECTORY = "src/Shared/Content/Maps"

local function generate(map: any): ()
	local startedAt = os.clock()
	Build.Stats.Parts, Build.Stats.Lights, Build.Stats.Guis, Build.Stats.Beams = 0, 0, 0, 0
	local ctx = Context.new(map)

	-- Orden: primero lo que ocupa sitio (huecos, suelo, ríos, calles, vía,
	-- lugares y parques) y después el relleno, que evita todo lo anterior.
	Landmarks.Prepare(ctx)
	Ground.Build(ctx)
	Rivers.Build(ctx)
	local junctions = Roads.Build(ctx)
	Rail.Build(ctx)
	Landmarks.Build(ctx)
	Parks.Build(ctx)
	Blocks.Build(ctx)
	Props.Streets(ctx, junctions)
	Backdrop.Build(ctx)

	fs.writeDir(OUTPUT_DIRECTORY)
	fs.writeFile(`{OUTPUT_DIRECTORY}/{map.Name}.rbxm`, roblox.serializeModel({ ctx.Root }))
	local minPoint, maxPoint = Ground.Bounds(ctx)
	Preview.Write(
		ctx.Root,
		`{OUTPUT_DIRECTORY}/{map.Name}_preview.png`,
		minPoint.X,
		minPoint.Z,
		maxPoint.X,
		maxPoint.Z,
		0.45
	)

	print(
		string.format(
			"%s: %d piezas, %d luces, %d letreros, %d cables, %d cruces (%.1f s)",
			map.Name,
			Build.Stats.Parts,
			Build.Stats.Lights,
			Build.Stats.Guis,
			Build.Stats.Beams,
			#junctions,
			os.clock() - startedAt
		)
	)
	for _, warning in ctx.Warnings do
		print("AVISO: " .. warning)
	end
	if #ctx.Warnings > 0 then
		process.exit(1)
	end
end

local only = process.args[1]
for _, file in fs.readDir(MAPS_DIRECTORY) do
	local name = string.match(file, "^(.+)%.luau$")
	if name ~= nil and (only == nil or only == name) then
		generate(luau.load(fs.readFile(`{MAPS_DIRECTORY}/{file}`), { debugName = file })())
	end
end
