--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ServerScriptService.Server.Packages.ProfileService)
local ReplicaService = require(ServerScriptService.Server.Packages.ReplicaService)

local DataTypes = require(ReplicatedStorage.Shared.Types.DataTypes)

type PlayerProfileData = DataTypes.PlayerProfileData
type ReplicatedPlayerData = DataTypes.ReplicatedPlayerData

-- Tipos mínimos de ProfileService/ReplicaService necesarios para tipar este módulo
-- sin depender de definiciones `any` sueltas por el archivo.
type Profile = {
	Data: PlayerProfileData,
	IsActive: (self: Profile) -> boolean,
	Reconcile: (self: Profile) -> (),
	Release: (self: Profile) -> (),
	ListenToRelease: (self: Profile, callback: () -> ()) -> RBXScriptConnection,
}

type ProfileStore = {
	LoadProfileAsync: (self: ProfileStore, key: string, notReleasedHandler: string?) -> Profile?,
}

type Replica = {
	Data: ReplicatedPlayerData,
	SetValue: (self: Replica, path: { string }, value: any) -> (),
	Destroy: (self: Replica) -> (),
}

export type PlayerDataLoadedCallback = (player: Player, profile: Profile) -> ()

export type DataService = {
	PlayerDataLoaded: RBXScriptSignal,

	GetProfile: (self: DataService, player: Player) -> Profile?,
	GetReplica: (self: DataService, player: Player) -> Replica?,
	OnPlayerDataLoaded: (self: DataService, callback: PlayerDataLoadedCallback) -> RBXScriptConnection,
	Init: (self: DataService) -> (),
	Shutdown: (self: DataService) -> (),
}

type DataServiceInternal = DataService & {
	_profileStore: ProfileStore,
	_profiles: { [Player]: Profile },
	_replicas: { [Player]: Replica },
	_playerDataLoadedEvent: BindableEvent,
	_connections: { RBXScriptConnection },
	_initialized: boolean,
}

local PROFILE_STORE_NAME = "PlayerData_Alpha"
local NOT_RELEASED_HANDLER = "ForceLoad"

local DataService: DataServiceInternal = {} :: DataServiceInternal
DataService.__index = DataService :: any

local playerDataLoadedEvent = Instance.new("BindableEvent")

DataService.PlayerDataLoaded = playerDataLoadedEvent.Event
DataService._profileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, DataTypes.DEFAULT_PROFILE_DATA)
DataService._profiles = {}
DataService._replicas = {}
DataService._playerDataLoadedEvent = playerDataLoadedEvent
DataService._connections = {}
DataService._initialized = false

local function buildReplicatedData(profile: Profile): ReplicatedPlayerData
	return {
		Attributes = profile.Data.Attributes,
		Experience = profile.Data.Experience,
		Currency = profile.Data.Currency,
		Inventory = profile.Data.Inventory,
		Settings = profile.Data.Settings,
	}
end

local function onPlayerAdded(player: Player)
	local profile = DataService._profileStore:LoadProfileAsync(
		"Player_" .. tostring(player.UserId),
		NOT_RELEASED_HANDLER
	)

	if profile == nil then
		player:Kick("No se pudieron cargar tus datos. Vuelve a intentarlo.")
		return
	end

	local activeProfile = profile :: Profile
	activeProfile:Reconcile()

	activeProfile:ListenToRelease(function()
		DataService._profiles[player] = nil

		local replica = DataService._replicas[player]
		if replica ~= nil then
			replica:Destroy()
			DataService._replicas[player] = nil
		end

		player:Kick("Tu sesión de datos se liberó en otro servidor.")
	end)

	if not player:IsDescendantOf(Players) then
		activeProfile:Release()
		return
	end

	DataService._profiles[player] = activeProfile

	local replica = ReplicaService.NewReplica({
		ClassToken = ReplicaService.NewClassToken("PlayerData"),
		Data = buildReplicatedData(activeProfile),
		Replication = "All",
	}) :: Replica

	DataService._replicas[player] = replica
	DataService._playerDataLoadedEvent:Fire(player, activeProfile)
end

local function onPlayerRemoving(player: Player)
	local profile = DataService._profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

function DataService:GetProfile(player: Player): Profile?
	return self._profiles[player]
end

function DataService:GetReplica(player: Player): Replica?
	return self._replicas[player]
end

function DataService:OnPlayerDataLoaded(callback: PlayerDataLoadedCallback): RBXScriptConnection
	local connection = self.PlayerDataLoaded:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function DataService:Init(): ()
	if self._initialized then
		return
	end
	self._initialized = true

	table.insert(self._connections, Players.PlayerAdded:Connect(onPlayerAdded))
	table.insert(self._connections, Players.PlayerRemoving:Connect(onPlayerRemoving))

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
end

function DataService:Shutdown(): ()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	for player, profile in pairs(self._profiles) do
		profile:Release()
		self._profiles[player] = nil
	end

	for player, replica in pairs(self._replicas) do
		replica:Destroy()
		self._replicas[player] = nil
	end

	self._playerDataLoadedEvent:Destroy()
	self._initialized = false
end

return (DataService :: any) :: DataService
