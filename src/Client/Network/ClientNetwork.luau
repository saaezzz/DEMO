--!strict

-- Capa de red del cliente (D-016). Los remotes los crea el servidor al
-- arrancar; las llamadas esperan a que existan.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local RemoteDefinitions = require(ReplicatedStorage.Shared.Network.RemoteDefinitions)

type RemoteName = RemoteDefinitions.RemoteName

local REMOTES_FOLDER_NAME = "Remotes"

local log = Logger.new("ClientNetwork")

local function getRemote(name: RemoteName): Instance
	return ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME):WaitForChild(name)
end

local ClientNetwork = {}

-- Devuelve la respuesta del servidor, o nil si la petición fue rechazada
-- (rate limit, payload inválido, error del handler) o falló la comunicación.
function ClientNetwork.Invoke(name: RemoteName, payload: any): any
	local remote = getRemote(name) :: RemoteFunction
	local ok, result = pcall(function()
		return remote:InvokeServer(payload)
	end)
	if not ok then
		log:Warn("%s: fallo de comunicación: %s", name, tostring(result))
		return nil
	end
	return result
end

function ClientNetwork.Fire(name: RemoteName, payload: any): ()
	local remote = getRemote(name) :: RemoteEvent
	remote:FireServer(payload)
end

function ClientNetwork.OnEvent(name: RemoteName, handler: (payload: any) -> ()): RBXScriptConnection
	local remote = getRemote(name) :: RemoteEvent
	return remote.OnClientEvent:Connect(handler)
end

return ClientNetwork
