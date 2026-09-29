--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTypes = require(ReplicatedStorage.Shared.Types.DataTypes)
local CharacterClass = require(ReplicatedStorage.Shared.Modules.Character)

local CombatService = require(script.Parent.CombatService)

type Character = CharacterClass.Character

export type CharacterService = {
	GetCharacter: (self: CharacterService, player: Player) -> Character?,
	Init: (self: CharacterService) -> (),
	Shutdown: (self: CharacterService) -> (),
}

type CharacterServiceInternal = CharacterService & {
	_characters: { [Player]: Character },
	_connections: { RBXScriptConnection },
}

local CharacterService: CharacterServiceInternal = {} :: CharacterServiceInternal
CharacterService.__index = CharacterService :: any

CharacterService._characters = {}
CharacterService._connections = {}

local function copyAttributes(): DataTypes.PlayerProfileData
	local defaults = DataTypes.DEFAULT_PROFILE_DATA
	return {
		Attributes = {
			Health = defaults.Attributes.Health,
			MaxHealth = defaults.Attributes.MaxHealth,
			Reiatsu = defaults.Attributes.Reiatsu,
			MaxReiatsu = defaults.Attributes.MaxReiatsu,
			Posture = defaults.Attributes.Posture,
			MaxPosture = defaults.Attributes.MaxPosture,
			Race = defaults.Attributes.Race,
			Level = defaults.Attributes.Level,
		},
		Experience = defaults.Experience,
		Currency = defaults.Currency,
		Inventory = {},
		Settings = {
			MusicVolume = defaults.Settings.MusicVolume,
			SfxVolume = defaults.Settings.SfxVolume,
			CameraShake = defaults.Settings.CameraShake,
		},
	}
end

local function onCharacterAdded(self: CharacterServiceInternal, player: Player, model: Model)
	local humanoid = model:WaitForChild("Humanoid", 5) :: Humanoid?
	local rootPart = model:WaitForChild("HumanoidRootPart", 5) :: BasePart?

	if humanoid == nil or rootPart == nil then
		return
	end

	if not player:IsDescendantOf(Players) then
		return
	end

	local profileData = copyAttributes()
	local character = CharacterClass.new(player.UserId, profileData.Attributes)

	self._characters[player] = character
	CombatService:RegisterCharacter(player, model, character)

	humanoid.MaxHealth = character:GetMaxHealth()
	humanoid.Health = character:GetHealth()

	local healthChangedConnection = character.HealthChanged:Connect(function(newHealth: number)
		humanoid.Health = math.clamp(newHealth, 0, humanoid.MaxHealth)
	end)
	table.insert(self._connections, healthChangedConnection)

	local diedConnection = character.Died:Connect(function()
		if humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
	table.insert(self._connections, diedConnection)

	local ancestryConnection = model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			CombatService:UnregisterCharacter(model)
			local activeCharacter = self._characters[player]
			if activeCharacter == character then
				character:Destroy()
				self._characters[player] = nil
			end
		end
	end)
	table.insert(self._connections, ancestryConnection)
end

local function onPlayerAdded(self: CharacterServiceInternal, player: Player)
	local characterAddedConnection = player.CharacterAdded:Connect(function(model)
		onCharacterAdded(self, player, model)
	end)
	table.insert(self._connections, characterAddedConnection)

	if player.Character ~= nil then
		onCharacterAdded(self, player, player.Character)
	end
end

local function onPlayerRemoving(self: CharacterServiceInternal, player: Player)
	local character = self._characters[player]
	if character ~= nil then
		character:Destroy()
		self._characters[player] = nil
	end
end

function CharacterService:GetCharacter(player: Player): Character?
	local self = (self :: any) :: CharacterServiceInternal
	return self._characters[player]
end

function CharacterService:Init(): ()
	local self = (self :: any) :: CharacterServiceInternal

	table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
		onPlayerAdded(self, player)
	end))
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		onPlayerRemoving(self, player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(self, player)
	end
end

function CharacterService:Shutdown(): ()
	local self = (self :: any) :: CharacterServiceInternal

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	for player, character in pairs(self._characters) do
		character:Destroy()
		self._characters[player] = nil
	end
end

return (CharacterService :: any) :: CharacterService
