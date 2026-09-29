--!strict

-- Emula lo mínimo del modelo de instancias de Roblox para ejecutar módulos del
-- proyecto con Lune (D-006). El árbol se reconstruye desde sourcemap.json
-- (generado por Rojo), así que `script.Parent`, `game:GetService(...)` y
-- `require(instancia)` funcionan igual que en Studio para módulos de lógica.
--
-- No emula comportamiento del motor (física, Humanoid, Players...): los
-- módulos que lo necesiten se prueban en Studio.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

export type SourcemapNode = {
	name: string,
	className: string,
	filePaths: { string }?,
	children: { SourcemapNode }?,
}

type Node = {
	Name: string,
	ClassName: string,
	FilePath: string?,
	Parent: Node?,
	Children: { Node },
}

export type Environment = {
	game: any,
	require: (target: any) -> any,
	-- Carga un archivo fuera del árbol (p. ej. un spec) con este entorno.
	loadFile: (path: string, extraGlobals: { [string]: any }?) -> any,
}

local SCRIPT_EXTENSIONS = { ".luau", ".lua" }

local function findScriptPath(filePaths: { string }?): string?
	if filePaths == nil then
		return nil
	end
	for _, path in filePaths do
		for _, extension in SCRIPT_EXTENSIONS do
			if string.sub(path, -#extension) == extension then
				return path
			end
		end
	end
	return nil
end

local function buildTree(source: SourcemapNode, parent: Node?): Node
	local node: Node = {
		Name = source.name,
		ClassName = source.className,
		FilePath = findScriptPath(source.filePaths),
		Parent = parent,
		Children = {},
	}
	for _, child in source.children or {} do
		table.insert(node.Children, buildTree(child, node))
	end
	return node
end

local function findChild(node: Node, name: string): Node?
	for _, child in node.Children do
		if child.Name == name then
			return child
		end
	end
	return nil
end

local function getFullName(node: Node): string
	local parts = {}
	local current: Node? = node
	while current ~= nil and current.ClassName ~= "DataModel" do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

local RobloxEnvironment = {}

function RobloxEnvironment.new(sourcemap: SourcemapNode): Environment
	local root = buildTree(sourcemap, nil)
	local proxies: { [Node]: any } = {}
	local nodesByProxy: { [any]: Node } = {}
	local moduleCache: { [Node]: any } = {}
	local loading: { [Node]: boolean } = {}

	local environment: Environment

	local function proxyOf(node: Node): any
		local existing = proxies[node]
		if existing ~= nil then
			return existing
		end

		local methods = {
			FindFirstChild = function(_, name: string)
				local child = findChild(node, name)
				return if child ~= nil then proxyOf(child) else nil
			end,
			-- El árbol es estático: si no existe ahora no aparecerá después.
			WaitForChild = function(_, name: string)
				local child = findChild(node, name)
				if child == nil then
					error(`WaitForChild: {name} no existe en {getFullName(node)}`, 2)
				end
				return proxyOf(child)
			end,
			GetChildren = function(_)
				local result = {}
				for _, child in node.Children do
					table.insert(result, proxyOf(child))
				end
				return result
			end,
			IsA = function(_, className: string)
				return node.ClassName == className
			end,
			GetFullName = function(_)
				return getFullName(node)
			end,
			GetService = function(_, serviceName: string)
				local service = findChild(node, serviceName)
				if service == nil then
					-- Servicio sin contenido en el proyecto (Players, RunService...):
					-- se crea vacío para que requerirlo no falle.
					service = {
						Name = serviceName,
						ClassName = serviceName,
						Parent = node,
						Children = {},
					}
					table.insert(node.Children, service :: Node)
				end
				return proxyOf(service :: Node)
			end,
		}

		local proxy = setmetatable({}, {
			__index = function(_, key: string)
				if key == "Name" then
					return node.Name
				elseif key == "ClassName" then
					return node.ClassName
				elseif key == "Parent" then
					return if node.Parent ~= nil then proxyOf(node.Parent) else nil
				end
				local method = methods[key]
				if method ~= nil then
					return method
				end
				local child = findChild(node, key)
				if child == nil then
					error(`{key} is not a valid member of {getFullName(node)}`, 2)
				end
				return proxyOf(child)
			end,
			__tostring = function()
				return node.Name
			end,
		})

		proxies[node] = proxy
		nodesByProxy[proxy] = node
		return proxy
	end

	local function makeGlobals(scriptNode: Node?, extraGlobals: { [string]: any }?): { [string]: any }
		local globals: { [string]: any } = {
			script = if scriptNode ~= nil then proxyOf(scriptNode) else nil,
			game = proxyOf(root),
			require = environment.require,
			task = task,
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
		}
		for key, value in extraGlobals or {} do
			globals[key] = value
		end
		return globals
	end

	local function runChunk(path: string, globals: { [string]: any }): any
		local source = fs.readFile(path)
		local chunk = luau.load(source, {
			debugName = path,
			environment = globals,
		})
		return chunk()
	end

	environment = {
		game = proxyOf(root),

		require = function(target: any): any
			local node = nodesByProxy[target]
			if node == nil then
				error("require: se esperaba una instancia del proyecto", 2)
			end
			if moduleCache[node] ~= nil then
				return moduleCache[node]
			end
			if node.ClassName ~= "ModuleScript" or node.FilePath == nil then
				error(`require: {getFullName(node)} no es un ModuleScript`, 2)
			end
			if loading[node] then
				error(`require: dependencia circular en {getFullName(node)}`, 2)
			end

			loading[node] = true
			local result = runChunk(node.FilePath, makeGlobals(node, nil))
			loading[node] = nil

			if result == nil then
				error(`require: {getFullName(node)} no devolvió ningún valor`, 2)
			end
			moduleCache[node] = result
			return result
		end,

		loadFile = function(path: string, extraGlobals: { [string]: any }?): any
			return runChunk(path, makeGlobals(nil, extraGlobals))
		end,
	}

	return environment
end

return RobloxEnvironment
