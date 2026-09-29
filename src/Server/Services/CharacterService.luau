--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local CharacterConfig = require(ReplicatedStorage.Shared.Config.CharacterConfig)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)

local CombatService = require(script.Parent.CombatService)

type Character = CharacterModule.Character
type CharacterAttributes = GameTypes.CharacterAttributes
type ResourcePool = GameTypes.ResourcePool

local CHARACTER_PARTS_TIMEOUT_SECONDS = 5

type CharacterRecord = {
	Model: Model,
	Character: Character,
	-- Conexiones a eventos de Roblox (Humanoid/modelo) de este personaje.
	Connections: { RBXScriptConnection },
}

local records: { [Player]: CharacterRecord } = {}
local characterAddedConnections: { [Player]: RBXScriptConnection } = {}

-- Atributos iniciales: valores base de CharacterConfig y recursos de la raza.
-- Provisional hasta DataService v1 (tarea 8): todos empiezan con la raza por defecto.
local function buildAttributes(raceId: string): CharacterAttributes
	local race = Races.Definitions[raceId]
	assert(race ~= nil, `[CharacterService] raza desconocida: {raceId}`)

	local resources: { [string]: ResourcePool } = {}
	for _, resourceId in race.Resources do
		local definition = Resources[resourceId]
		assert(definition ~= nil, `[CharacterService] recurso desconocido: {resourceId}`)
		resources[resourceId] = { Current = definition.DefaultMax, Max = definition.DefaultMax }
	end

	return {
		Race = raceId,
		Level = 1,
		MaxHealth = CharacterConfig.BaseMaxHealth,
		MaxPosture = CharacterConfig.MaxPosture,
		Resources = resources,
	}
end

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
	local character = CharacterModule.new(buildAttributes(Races.Default))
	humanoid.MaxHealth = character:GetMaxHealth()
	humanoid.Health = character:GetHealth()

	local record: CharacterRecord = {
		Model = model,
		Character = character,
		Connections = {},
	}
	records[player] = record

	-- Character:Destroy() desconecta sus propias señales; no hace falta guardarla.
	character.HealthChanged:Connect(function(newHealth: number)
		humanoid.Health = math.clamp(newHealth, 0, humanoid.MaxHealth)
	end)

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

local CharacterService = {
	Name = "CharacterService",
}

function CharacterService:Start(): ()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function CharacterService:GetCharacter(player: Player): Character?
	local record: CharacterRecord? = records[player]
	return if record ~= nil then record.Character else nil
end

return CharacterService
