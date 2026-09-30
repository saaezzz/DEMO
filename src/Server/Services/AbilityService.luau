--!strict

-- Framework de habilidades (§17, D-025). Toda acción de combate es una
-- AbilityDefinition de Content/Abilities y pasa por el mismo camino:
-- requisitos de estado → cooldown → coste → estado de acción → golpes
-- programados → vuelta a Idle. Una habilidad nueva solo necesita datos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local Abilities = require(script.Parent.Parent.Content.Abilities)
local Movesets = require(script.Parent.Parent.Content.Movesets)
local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local ComboChain = require(script.Parent.Parent.Combat.ComboChain)
local Cooldowns = require(script.Parent.Parent.Combat.Cooldowns)
local DamageService = require(script.Parent.Parent.Combat.DamageService)
local HitboxService = require(script.Parent.Parent.Combat.HitboxService)

type AbilityDefinition = AbilityTypes.AbilityDefinition
type AbilityHit = AbilityTypes.AbilityHit
type CombatAction = GameTypes.CombatAction
type ResourceCost = GameTypes.ResourceCost
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ServerResponseStatus = GameTypes.ServerResponseStatus
type MovementSpec = GameTypes.MovementSpec
type CombatEntity = CombatRegistry.CombatEntity
type ActiveAction = CombatRegistry.ActiveAction
type ChainProgress = ComboChain.ChainProgress

local ACTION_GROUP = "Action"
local DEFAULT_MOVESET = "Default"

local log = Logger.new("AbilityService")
local abilities: { [string]: AbilityDefinition } = {}
local cooldowns = Cooldowns.new()
-- Progreso de la cadena M1 por dueño (jugador o modelo de NPC).
local chains: { [any]: ChainProgress } = {}

local function respond(status: ServerResponseStatus, message: string?, movement: MovementSpec?): ServerCombatResponse
	return { Status = status, Message = message, Movement = movement }
end

local function getOwner(entity: CombatEntity): any
	return entity.Player or entity.Model
end

-- Cobra el coste completo o nada. Sin coste, siempre tiene éxito.
local function trySpendCost(entity: CombatEntity, cost: ResourceCost?): (boolean, string?)
	if cost == nil or cost.Amount <= 0 then
		return true, nil
	end
	if entity.Character:SpendResource(cost.Resource, cost.Amount) then
		return true, nil
	end
	local definition = Resources[cost.Resource]
	local displayName = if definition ~= nil then definition.DisplayName else cost.Resource
	return false, `{displayName} insuficiente`
end

local function isAirborne(entity: CombatEntity): boolean
	return entity.Humanoid.FloorMaterial == Enum.Material.Air
end

local function markAction(entity: CombatEntity, ability: AbilityDefinition): ()
	local model = entity.Model
	local sequence = model:GetAttribute(ReplicatedAttributes.ACTION_SEQ)
	model:SetAttribute(ReplicatedAttributes.ACTION_ANIMATION, ability.Animation)
	model:SetAttribute(ReplicatedAttributes.ACTION_SEQ, (if typeof(sequence) == "number" then sequence else 0) + 1)
end

-- Golpes y fin de la habilidad. Cada tarea comprueba que la acción sigue
-- siendo la misma: si se canceló (aturdimiento, esquiva...) no hace nada.
local function scheduleAction(entity: CombatEntity, action: ActiveAction): ()
	local ability = action.Ability
	local hits: { AbilityHit } = ability.Hits or {}
	for _, hit in hits do
		entity.Scheduler:Schedule(ACTION_GROUP, hit.StartTime, function()
			if entity.Action ~= action then
				return
			end
			for _, target in HitboxService.FindTargets(entity, hit.Hitbox) do
				DamageService.ApplyHit(entity, target, hit)
			end
		end)
	end

	entity.Scheduler:Schedule(ACTION_GROUP, ability.Duration, function()
		if entity.Action ~= action then
			return
		end
		-- Se vacía antes de la transición para que no cuente como cancelación.
		entity.Action = nil
		if entity.Character:GetState() == ability.State then
			entity.Character:TransitionTo("Idle")
		end
	end)
end

local AbilityService = {
	Name = "AbilityService",
}

function AbilityService:Init(): ()
	for _, ability in Abilities do
		assert(abilities[ability.Id] == nil, `[AbilityService] habilidad duplicada: {ability.Id}`)
		abilities[ability.Id] = ability
	end
	log:Debug("%d habilidades cargadas", #Abilities)
end

function AbilityService:Start(): ()
	Players.PlayerRemoving:Connect(function(player)
		cooldowns:Clear(player)
		chains[player] = nil
	end)
end

function AbilityService:Get(abilityId: string): AbilityDefinition?
	return abilities[abilityId]
end

-- Corta la habilidad en curso (golpes pendientes incluidos). No cambia el estado.
function AbilityService:CancelAction(entity: CombatEntity): ()
	entity.Scheduler:CancelGroup(ACTION_GROUP)
	entity.Action = nil
end

function AbilityService:Activate(entity: CombatEntity, abilityId: string): ServerCombatResponse
	local ability = abilities[abilityId]
	if ability == nil then
		return respond("Rejected", "Habilidad inexistente")
	end

	local character = entity.Character
	local meets, reason = character:MeetsRequirements(ability.Requirements)
	if not meets then
		return respond("InvalidState", reason)
	end
	if not character:CanTransitionTo(ability.State) then
		return respond("InvalidState", `No se puede pasar a {ability.State} desde {character:GetState()}`)
	end
	local movement = ability.Movement
	if movement ~= nil and not movement.AllowAir and isAirborne(entity) then
		return respond("InvalidState", "No se puede en el aire")
	end

	local owner = getOwner(entity)
	if not cooldowns:IsReady(owner, ability.Id) then
		return respond("OnCooldown", nil)
	end
	local paid, costError = trySpendCost(entity, ability.Cost)
	if not paid then
		return respond("InsufficientResource", costError)
	end

	-- Una habilidad que cancela a otra (esquivar durante un ataque) corta sus golpes.
	self:CancelAction(entity)
	cooldowns:Start(owner, ability.Id, ability.Cooldown)

	local action: ActiveAction = { Ability = ability, StartedAt = os.clock() }
	entity.Action = action
	markAction(entity, ability)
	character:TransitionTo(ability.State)
	scheduleAction(entity, action)

	return respond("Accepted", nil, movement)
end

-- Resuelve la acción de input con el moveset del personaje. El cliente nunca
-- elige la habilidad (D-025).
function AbilityService:ActivateAction(entity: CombatEntity, action: CombatAction): ServerCombatResponse
	local moveset = Movesets[DEFAULT_MOVESET]

	if action == "LightAttack" then
		local owner = getOwner(entity)
		local chain = moveset.LightAttack
		local now = os.clock()
		local index = ComboChain.NextIndex(chains[owner], #chain, now, CombatConfig.ComboWindowSeconds)
		local response = self:Activate(entity, chain[index])
		if response.Status == "Accepted" then
			chains[owner] = { Index = index, EndsAt = now + abilities[chain[index]].Duration }
		end
		return response
	end

	local abilityId: string? = if action == "HeavyAttack"
		then moveset.HeavyAttack
		elseif action == "Dodge" then moveset.Dodge
		elseif action == "Dash" then moveset.Dash
		else nil
	if abilityId == nil then
		return respond("Rejected", "Acción sin habilidad asignada")
	end
	return self:Activate(entity, abilityId)
end

return AbilityService
