--!strict

-- Copia local de los datos del propio jugador, replicada por el servidor
-- (D-005). Solo lectura: cualquier cambio se pide al servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)

local ClientNetwork = require(script.Parent.Parent.Network.ClientNetwork)

type PlayerData = PlayerDataTypes.PlayerData
type PlayerDataKey = PlayerDataTypes.PlayerDataKey
type PlayerDataMessage = PlayerDataTypes.PlayerDataMessage

local log = Logger.new("PlayerDataController")
local data: PlayerData? = nil

local PlayerDataController = {
	Name = "PlayerDataController",
	-- (data) al recibir la copia completa.
	Loaded = Signal.new() :: Signal.Signal<PlayerData>,
	-- (clave, nuevoValor) al cambiar una clave de primer nivel.
	Changed = Signal.new() :: Signal.Signal<PlayerDataKey, any>,
}

local function onMessage(message: PlayerDataMessage): ()
	local snapshot = message.Snapshot
	if snapshot ~= nil then
		data = snapshot
		log:Debug("Datos recibidos (versión %d)", snapshot.DataVersion)
		PlayerDataController.Loaded:Fire(snapshot)
		return
	end

	local key: PlayerDataKey? = message.Key
	local current = data
	if key == nil or current == nil then
		return
	end
	(current :: any)[key] = message.Value
	PlayerDataController.Changed:Fire(key, message.Value)
end

function PlayerDataController:Start(): ()
	ClientNetwork.OnEvent("PlayerData", onMessage)
end

-- nil hasta recibir los datos del servidor.
function PlayerDataController:GetData(): PlayerData?
	return data
end

return PlayerDataController
