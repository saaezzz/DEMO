--!strict

-- Capa de red del servidor (D-016). Crea los remotes de RemoteDefinitions y
-- obliga a registrar cada handler con un validador de Schema; RemoteGuard
-- aplica rate limit, validación y protección de errores.
--
-- Uso (en el Start de un servicio):
--   ServerNetwork:HandleFunction("CombatIntent", validate, function(player, intent) ... end)

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
	assert(limiter ~= nil, `[ServerNetwork] remote no definido: {name}`)
	return limiter
end

local function claimHandler(name: RemoteName, kind: RemoteKind): ()
	local definition = RemoteDefinitions[name]
	assert(definition ~= nil, `[ServerNetwork] remote no definido: {name}`)
	assert(definition.Kind == kind, `[ServerNetwork] {name} es de tipo {definition.Kind}, no {kind}`)
	assert(not handled[name], `[ServerNetwork] {name} ya tiene handler`)
	handled[name] = true
end

local function getRemoteEvent(name: RemoteName): RemoteEvent
	local remote: RemoteEvent? = remoteEvents[name]
	assert(remote ~= nil, `[ServerNetwork] {name} no es un RemoteEvent`)
	return remote
end

local ServerNetwork = {
	Name = "ServerNetwork",
}

function ServerNetwork:Init(): ()
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	assert(existing == nil, "[ServerNetwork] ReplicatedStorage.Remotes ya existe; los remotes se crean por código")

	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER_NAME

	for name, definition in RemoteDefinitions do
		limiters[name] = RateLimiter.new(definition.Burst, definition.PerSecond)

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
		else
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
			remoteEvents[name] = remote
		end
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
	claimHandler(name, "Event")
	local guarded = RemoteGuard.wrap(name, getLimiter(name), validate, handler, log)
	getRemoteEvent(name).OnServerEvent:Connect(guarded)
end

function ServerNetwork:FireClient(name: RemoteName, player: Player, payload: any): ()
	getRemoteEvent(name):FireClient(player, payload)
end

function ServerNetwork:FireAllClients(name: RemoteName, payload: any): ()
	getRemoteEvent(name):FireAllClients(payload)
end

return ServerNetwork
