--!strict

-- Ciclo de vida del personaje de cada jugador (D-018): se crea cuando su
-- perfil está cargado, refleja la vida autoritativa en el Humanoid y
-- reaparece tras morir. Players.CharacterAutoLoads está desactivado: solo
-- este servicio genera personajes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local CharacterConfig = require(ReplicatedStorage.Shared.Config.CharacterConfig)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)

type Character = CharacterModule.Character
type CharacterAttributes = GameTypes.CharacterAttributes
type ResourcePool = GameTypes.ResourcePool
type PlayerData = PlayerDataTypes.PlayerData

local CHARACTER_PARTS_TIMEOUT_SECONDS = 5

type CharacterRecord = {
	Model: Model,
	Character: Character,
	-- Conexiones a eventos de Roblox (Humanoid/modelo) de este personaje.
	Connections: { RBXScriptConnection },
}

local log = Logger.new("CharacterService")
local records: { [Player]: CharacterRecord } = {}
local characterAddedConnections: { [Player]: RBXScriptConnection } = {}

local function isInGame(player: Player): boolean
	return player.Parent == Players
end

-- Atributos a partir del perfil: raza y nivel guardados, valores base de
-- CharacterConfig y recursos iniciales de la raza.
local function buildAttributes(player: Player, data: PlayerData): CharacterAttributes
	local raceId = data.Race
	local race = Races.Definitions[raceId]
	if race == nil then
		-- El contenido pudo cambiar desde que se guardó el perfil.
		log:Warn("Raza desconocida '%s' en el perfil de %s; se usa la raza por defecto", raceId, player.Name)
		raceId = Races.Default
		race = Races.Definitions[raceId]
	end

	local resources: { [string]: ResourcePool } = {}
	for _, resourceId in race.Resources do
		local definition = Resources[resourceId]
		assert(definition ~= nil, `[CharacterService] recurso desconocido: {resourceId}`)
		resources[resourceId] = { Current = definition.DefaultMax, Max = definition.DefaultMax }
	end

	return {
		Race = raceId,
		Level = data.Level,
		MaxHealth = CharacterConfig.BaseMaxHealth,
		MaxPosture = CharacterConfig.MaxPosture,
		Resources = resources,
	}
end

-- LoadCharacterAsync cede y puede fallar: se lanza en su propia tarea para no ceder
-- dentro de handlers de Signal (D-013).
local function spawnCharacter(player: Player): ()
	if not (isInGame(player) and DataService:IsLoaded(player)) then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			player:LoadCharacterAsync()
		end)
		if not ok then
			log:Warn("No se pudo cargar el personaje de %s: %s", player.Name, tostring(err))
		end
	end)
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
	if not isInGame(player) or player.Character ~= model then
		return
	end

	local data = DataService:GetData(player)
	if data == nil then
		return
	end

	releaseCharacter(player)

	-- La vida autoritativa vive en Character; el Humanoid solo la refleja.
	local character = CharacterModule.new(buildAttributes(player, data))
	humanoid.MaxHealth = character:GetMaxHealth()
	humanoid.Health = character:GetHealth()

	local record: CharacterRecord = {
		Model = model,
		Character = character,
		Connections = {},
	}
	records[player] = record

	-- Character:Destroy() desconecta sus propias señales; no hace falta guardarlas.
	character.HealthChanged:Connect(function(newHealth: number)
		humanoid.Health = math.clamp(newHealth, 0, humanoid.MaxHealth)
	end)
	character.Died:Connect(function()
		task.delay(CharacterConfig.RespawnSeconds, function()
			-- Solo si no ha aparecido ya otro personaje entretanto.
			if player.Character == model or player.Character == nil then
				spawnCharacter(player)
			end
		end)
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
	DataService.ProfileLoaded:Connect(function(player)
		spawnCharacter(player)
	end)

	-- Jugadores que ya estaban (o cuyo perfil cargó antes de este Start).
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		if player.Character == nil then
			spawnCharacter(player)
		end
	end
end

function CharacterService:GetCharacter(player: Player): Character?
	local record: CharacterRecord? = records[player]
	return if record ~= nil then record.Character else nil
end

return CharacterService
