--!strict

-- Persistencia de los datos del jugador con ProfileStore (D-004, D-018) y
-- replicación de esos datos solo a su dueño (D-005).
--
-- Los servicios leen con GetData y modifican con SetValue, que replica el
-- cambio al cliente. No se debe mutar la tabla devuelta por GetData
-- directamente: el cambio se guardaría pero el cliente no se enteraría.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)
local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore) :: any
local DataSchema = require(script.Parent.Parent.Data.DataSchema)
local Migrator = require(script.Parent.Parent.Data.Migrator)
local ServerNetwork = require(script.Parent.Parent.Network.ServerNetwork)

type PlayerData = PlayerDataTypes.PlayerData
type PlayerDataKey = PlayerDataTypes.PlayerDataKey
type PlayerDataMessage = PlayerDataTypes.PlayerDataMessage

-- Subconjunto de la API de ProfileStore que usa este servicio.
type Profile = {
	Data: { [string]: any },
	OnSessionEnd: { Connect: (self: any, callback: () -> ()) -> any },
	AddUserId: (self: Profile, userId: number) -> (),
	Reconcile: (self: Profile) -> (),
	EndSession: (self: Profile) -> (),
}

local STORE_NAME = "PlayerData"

local KICK_LOAD_FAILED = "No se pudieron cargar tus datos. Vuelve a intentarlo en unos minutos."
local KICK_OUTDATED_SERVER = "Este servidor usa una versión antigua del juego. Únete a otro servidor."
local KICK_SESSION_MOVED = "Tu partida se ha abierto en otro servidor."

local log = Logger.new("DataService")
local store: any = nil
local profiles: { [Player]: Profile } = {}

local function profileKey(player: Player): string
	return `Player_{player.UserId}`
end

local function isInGame(player: Player): boolean
	return player.Parent == Players
end

-- Sustituye el contenido de la tabla del perfil sin cambiar su referencia
-- (ProfileStore guarda esa tabla concreta).
local function replaceContents(target: { [string]: any }, source: { [string]: any }): ()
	table.clear(target)
	for key, value in source do
		target[key] = value
	end
end

local function sendToOwner(player: Player, message: PlayerDataMessage): ()
	ServerNetwork:FireClient("PlayerData", player, message)
end

local DataService = {
	Name = "DataService",
	-- (player, data) cuando el perfil del jugador está cargado y listo.
	ProfileLoaded = Signal.new() :: Signal.Signal<Player, PlayerData>,
}

local function loadProfile(player: Player): ()
	local profile: Profile? = store:StartSessionAsync(profileKey(player), {
		Cancel = function()
			return not isInGame(player)
		end,
	})
	if profile == nil then
		if isInGame(player) then
			log:Warn("No se pudo abrir la sesión de %s", player.Name)
			player:Kick(KICK_LOAD_FAILED)
		end
		return
	end

	profile:AddUserId(player.UserId)

	local result = Migrator.Migrate(profile.Data, DataSchema.VERSION, DataSchema.MIGRATIONS)
	if not result.Ok then
		-- Los datos no se han modificado: cerrar la sesión los guarda tal cual.
		log:Error("Perfil de %s no cargado (%s): %s", player.Name, tostring(result.Error), tostring(result.Message))
		profile:EndSession()
		player:Kick(if result.Error == "FutureVersion" then KICK_OUTDATED_SERVER else KICK_LOAD_FAILED)
		return
	end
	if result.Data ~= nil then
		replaceContents(profile.Data, result.Data)
		log:Info("Perfil de %s migrado a la versión %d", player.Name, DataSchema.VERSION)
	end
	profile:Reconcile()

	local activeProfile: Profile = profile
	profile.OnSessionEnd:Connect(function()
		-- Si sigue registrado, la sesión no la cerramos nosotros sino otro
		-- servidor que la ha tomado: este servidor ya no puede guardar.
		if profiles[player] == activeProfile then
			profiles[player] = nil
			if isInGame(player) then
				player:Kick(KICK_SESSION_MOVED)
			end
		end
	end)

	if not isInGame(player) then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	local data = profile.Data :: PlayerData
	sendToOwner(player, { Snapshot = data, Key = nil, Value = nil })
	log:Debug("Perfil de %s cargado", player.Name)
	DataService.ProfileLoaded:Fire(player, data)
end

local function releaseProfile(player: Player): ()
	local profile: Profile? = profiles[player]
	if profile ~= nil then
		profiles[player] = nil
		profile:EndSession()
	end
end

function DataService:Init(): ()
	store = ProfileStore.New(STORE_NAME, DataSchema.createTemplate())

	ProfileStore.OnError:Connect(function(message, storeName, key)
		log:Warn("ProfileStore (%s/%s): %s", tostring(storeName), tostring(key), tostring(message))
	end)
	ProfileStore.OnCriticalToggle:Connect(function(isCritical)
		if isCritical then
			log:Error("DataStore en estado crítico: los guardados están fallando")
		else
			log:Info("DataStore recuperado del estado crítico")
		end
	end)
end

function DataService:Start(): ()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadProfile, player)
	end)
	Players.PlayerRemoving:Connect(releaseProfile)

	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end
end

function DataService:IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- Datos del jugador (solo lectura; usar SetValue para modificar). nil si su
-- perfil no está cargado.
function DataService:GetData(player: Player): PlayerData?
	local profile: Profile? = profiles[player]
	return if profile ~= nil then profile.Data :: PlayerData else nil
end

-- Modifica una clave de primer nivel y replica el cambio al dueño. Devuelve
-- false si el perfil no está cargado.
function DataService:SetValue(player: Player, key: PlayerDataKey, value: any): boolean
	local profile: Profile? = profiles[player]
	if profile == nil then
		return false
	end
	profile.Data[key] = value
	sendToOwner(player, { Snapshot = nil, Key = key, Value = value })
	return true
end

return DataService
