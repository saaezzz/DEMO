--!strict

-- Capa de red del servidor (D-016). Crea los remotes de RemoteDefinitions y
-- obliga a registrar cada handler con un validador de Schema; RemoteGuard
-- aplica rate limit, validación y protección de errores.
--
-- Uso (en el Start de un servicio):
--   ServerNetwork:HandleFunction("CombatIntent", validate, function(player, intent) ... end)
--   ServerNetwork:FireClient("PlayerData", player, payload)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local Schema = require(ReplicatedStorage.Shared.Network.Schema)
local RemoteDefinitions = require(ReplicatedStorage.Shared.Network.RemoteDefinitions)
local RateLimiter = require(script.Parent.Parent.Modules.RateLimiter)
local RemoteGuard = require(script.Parent.RemoteGuard)

type RemoteName = RemoteDefinitions.RemoteName
type RemoteKind = RemoteDefinitions.RemoteKind
type Validator = Schema.Validator
type RateLimiter = RateLimiter.RateLimiter

local REMOTES_FOLDER_NAME = "Remotes"

local log = Logger.new("ServerNetwork")
local remoteFunctions: { [string]: RemoteFunction } = {}
local remoteEvents: { [string]: RemoteEvent } = {}
local limiters: { [string]: RateLimiter } = {}
local handled: { [string]: boolean } = {}

local function getLimiter(name: RemoteName): RateLimiter
	local limiter: RateLimiter? = limiters[name]
	assert(limiter ~= nil, `[ServerNetwork] {name} no tiene rate limit`)
	return limiter
end

local function claimHandler(name: RemoteName, kind: RemoteKind): ()
	local definition = RemoteDefinitions[name]
	assert(definition ~= nil, `[ServerNetwork] remote no definido: {name}`)
	assert(definition.Kind == kind, `[ServerNetwork] {name} es de tipo {definition.Kind}, no {kind}`)
	assert(not handled[name], `[ServerNetwork] {name} ya tiene handler`)
	handled[name] = true
end

local function getRemoteEvent(name: RemoteName, kind: RemoteKind): RemoteEvent
	local definition = RemoteDefinitions[name]
	assert(definition ~= nil and definition.Kind == kind, `[ServerNetwork] {name} no es de tipo {kind}`)
	return remoteEvents[name]
end

local function createRemote(name: string, definition: RemoteDefinitions.RemoteDefinition, folder: Folder): ()
	local rateLimit = definition.RateLimit
	if definition.Kind ~= "ToClientEvent" then
		assert(rateLimit ~= nil, `[ServerNetwork] {name} lo inicia el cliente y necesita RateLimit`)
		limiters[name] = RateLimiter.new(rateLimit.Burst, rateLimit.PerSecond)
	end

	if definition.Kind == "Function" then
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		-- Hasta que un servicio registre su handler, responder nil en vez
		-- de dejar al cliente esperando indefinidamente.
		remote.OnServerInvoke = function()
			return nil
		end
		remote.Parent = folder
		remoteFunctions[name] = remote
		return
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	if definition.Kind == "ToClientEvent" then
		-- El cliente no debe emitir en este remote: se descarta lo que envíe
		-- para que no se acumule en la cola de eventos sin listener.
		remote.OnServerEvent:Connect(function(player)
			log:Debug("%s: %s emitió en un remote solo de servidor", name, player.Name)
		end)
	end
	remote.Parent = folder
	remoteEvents[name] = remote
end

local ServerNetwork = {
	Name = "ServerNetwork",
}

function ServerNetwork:Init(): ()
	-- Los remotes solo se crean por código. Una carpeta previa es un resto del lugar
	-- (p. ej. de cuando se declaraban en default.project.json): se sustituye.
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing ~= nil then
		log:Warn("ReplicatedStorage.Remotes ya existía en el lugar; se sustituye (bórrala en Studio)")
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER_NAME
	for name, definition in RemoteDefinitions do
		createRemote(name, definition, folder)
	end
	folder.Parent = ReplicatedStorage
end

function ServerNetwork:Start(): ()
	Players.PlayerRemoving:Connect(function(player)
		for _, limiter in limiters do
			limiter:Remove(player)
		end
	end)
end

-- El valor devuelto por handler se envía al cliente; si la petición se rechaza
-- o el handler falla, el cliente recibe nil.
function ServerNetwork:HandleFunction(
	name: RemoteName,
	validate: Validator,
	handler: (player: Player, payload: any) -> any
): ()
	claimHandler(name, "Function")
	local guarded = RemoteGuard.wrap(name, getLimiter(name), validate, handler, log)
	remoteFunctions[name].OnServerInvoke = guarded
end

function ServerNetwork:HandleEvent(
	name: RemoteName,
	validate: Validator,
	handler: (player: Player, payload: any) -> ()
): ()
	claimHandler(name, "ToServerEvent")
	local guarded = RemoteGuard.wrap(name, getLimiter(name), validate, handler, log)
	remoteEvents[name].OnServerEvent:Connect(guarded)
end

function ServerNetwork:FireClient(name: RemoteName, player: Player, payload: any): ()
	getRemoteEvent(name, "ToClientEvent"):FireClient(player, payload)
end

function ServerNetwork:FireAllClients(name: RemoteName, payload: any): ()
	getRemoteEvent(name, "ToClientEvent"):FireAllClients(payload)
end

return ServerNetwork
