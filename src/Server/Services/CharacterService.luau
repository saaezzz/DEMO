--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataTypes = require(ReplicatedStorage.Shared.Types.DataTypes)
local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)

local CombatService = require(script.Parent.CombatService)

type Character = CharacterModule.Character

local CHARACTER_PARTS_TIMEOUT_SECONDS = 5

type CharacterRecord = {
	Model: Model,
	Character: Character,
	Connections: { RBXScriptConnection },
}

local records: { [Player]: CharacterRecord } = {}
local characterAddedConnections: { [Player]: RBXScriptConnection } = {}
local connections: { RBXScriptConnection } = {}

-- Libera el personaje activo del jugador: desconecta, lo quita del combate y lo destruye.
local function releaseCharacter(player: Player): ()
	local record: CharacterRecord? = records[player]
	if record == nil then
		return
	end
	records[player] = nil

	for _, connection in record.Connections do
		connection:Disconnect()
	end
	CombatService:UnregisterCharacter(record.Model)
	record.Character:Destroy()
end

local function onCharacterAdded(player: Player, model: Model): ()
	local humanoid = model:WaitForChild("Humanoid", CHARACTER_PARTS_TIMEOUT_SECONDS) :: Humanoid?
	local rootPart = model:WaitForChild("HumanoidRootPart", CHARACTER_PARTS_TIMEOUT_SECONDS)
	if humanoid == nil or rootPart == nil then
		return
	end

	-- Durante la espera el jugador pudo salir o reaparecer con otro modelo.
	if player.Parent == nil or player.Character ~= model then
		return
	end

	releaseCharacter(player)

	-- La vida autoritativa vive en Character; el Humanoid solo la refleja.
	local character = CharacterModule.new(table.clone(DataTypes.DEFAULT_PROFILE_DATA.Attributes))
	humanoid.MaxHealth = character:GetMaxHealth()
	humanoid.Health = character:GetHealth()

	local record: CharacterRecord = {
		Model = model,
		Character = character,
		Connections = {},
	}
	records[player] = record

	table.insert(
		record.Connections,
		character.HealthChanged:Connect(function(newHealth: number)
			humanoid.Health = math.clamp(newHealth, 0, humanoid.MaxHealth)
		end)
	)

	-- Muertes ajenas al combate (p. ej. caer al vacío) también matan al Character.
	table.insert(
		record.Connections,
		humanoid.Died:Connect(function()
			character:TakeDamage(character:GetHealth())
		end)
	)

	table.insert(
		record.Connections,
		model.AncestryChanged:Connect(function(_, parent)
			local current: CharacterRecord? = records[player]
			if parent == nil and current ~= nil and current.Model == model then
				releaseCharacter(player)
			end
		end)
	)

	CombatService:RegisterCharacter(player, model, character)
end

local function onPlayerAdded(player: Player): ()
	characterAddedConnections[player] = player.CharacterAdded:Connect(function(model)
		onCharacterAdded(player, model)
	end)

	local existingModel = player.Character
	if existingModel ~= nil then
		task.spawn(onCharacterAdded, player, existingModel)
	end
end

local function onPlayerRemoving(player: Player): ()
	local characterAddedConnection: RBXScriptConnection? = characterAddedConnections[player]
	if characterAddedConnection ~= nil then
		characterAddedConnection:Disconnect()
		characterAddedConnections[player] = nil
	end

	releaseCharacter(player)
end

local CharacterService = {}

function CharacterService:GetCharacter(player: Player): Character?
	local record: CharacterRecord? = records[player]
	return if record ~= nil then record.Character else nil
end

function CharacterService:Init(): ()
	table.insert(connections, Players.PlayerAdded:Connect(onPlayerAdded))
	table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function CharacterService:Shutdown(): ()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	for player in characterAddedConnections do
		onPlayerRemoving(player)
	end
end

return CharacterService
