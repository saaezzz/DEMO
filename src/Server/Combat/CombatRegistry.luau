--!strict

-- Personajes que participan en el combate (jugadores y NPCs) y el estado de
-- combate de cada uno (D-025). Es el punto común de los servicios de combate:
-- lo rellena CombatService y lo leen AbilityService, DamageService,
-- ResourceService y MovementService, sin depender unos de otros.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local Modifiers = require(script.Parent.Modifiers)
local TaskScheduler = require(script.Parent.TaskScheduler)

type AbilityDefinition = AbilityTypes.AbilityDefinition
type Character = CharacterModule.Character
type TaskScheduler = TaskScheduler.TaskScheduler

export type ActiveAction = {
	Ability: AbilityDefinition,
	StartedAt: number,
}

export type CombatEntity = {
	Model: Model,
	Character: Character,
	-- nil para NPCs.
	Player: Player?,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Scheduler: TaskScheduler,

	-- Inicio de la ventana de parry del bloqueo actual (nil si no la concede).
	ParryWindowStart: number?,
	LastParryAttempt: number?,
	-- Fin del último bloqueo (para BlockCooldownSeconds).
	LastBlockEndedAt: number?,
	-- Habilidad en curso.
	Action: ActiveAction?,
	-- Fin del aturdimiento actual.
	StunEndsAt: number?,
	-- Último gasto de cada recurso, para el retardo de regeneración.
	LastSpent: { [string]: number },
	SprintRequested: boolean,
	-- Potenciadores activos (D-040).
	Modifiers: Modifiers.ModifierSet,
}

local entities: { [Model]: CombatEntity } = {}
local playerModels: { [Player]: Model } = {}

local CombatRegistry = {}

function CombatRegistry.Create(model: Model, character: Character, player: Player?): CombatEntity?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or rootPart == nil or not rootPart:IsA("BasePart") then
		return nil
	end
	return {
		Model = model,
		Character = character,
		Player = player,
		Humanoid = humanoid,
		RootPart = rootPart,
		Scheduler = TaskScheduler.new(),
		ParryWindowStart = nil,
		LastParryAttempt = nil,
		LastBlockEndedAt = nil,
		Action = nil,
		StunEndsAt = nil,
		LastSpent = {},
		SprintRequested = false,
		Modifiers = {},
	}
end

function CombatRegistry.Add(entity: CombatEntity): ()
	entities[entity.Model] = entity
	local player = entity.Player
	if player ~= nil then
		playerModels[player] = entity.Model
	end
end

function CombatRegistry.Remove(model: Model): CombatEntity?
	local entity: CombatEntity? = entities[model]
	if entity == nil then
		return nil
	end
	entities[model] = nil
	local player = entity.Player
	if player ~= nil and playerModels[player] == model then
		playerModels[player] = nil
	end
	entity.Scheduler:Destroy()
	return entity
end

function CombatRegistry.Get(model: Model): CombatEntity?
	return entities[model]
end

-- Entidad del personaje actual del jugador, solo si está vivo.
function CombatRegistry.GetAlive(player: Player): CombatEntity?
	local model: Model? = playerModels[player]
	local entity: CombatEntity? = if model ~= nil then entities[model] else nil
	if entity == nil or not entity.Character:IsAlive() then
		return nil
	end
	return entity
end

function CombatRegistry.GetAll(): { [Model]: CombatEntity }
	return entities
end

-- PvE (constitución §2): los jugadores no se dañan entre sí, ni los NPCs entre ellos.
function CombatRegistry.AreHostile(a: CombatEntity, b: CombatEntity): boolean
	return (a.Player == nil) ~= (b.Player == nil)
end

return CombatRegistry
