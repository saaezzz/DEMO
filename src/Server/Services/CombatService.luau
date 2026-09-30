--!strict

-- Punto de entrada del combate (D-025): registra los personajes que combaten,
-- atiende CombatIntent y gestiona la guardia (bloqueo y parry). Las acciones
-- van a AbilityService; el sprint, a MovementService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local CombatIntentValidator = require(script.Parent.Parent.Combat.CombatIntentValidator)
local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local ServerNetwork = require(script.Parent.Parent.Network.ServerNetwork)
local AbilityService = require(script.Parent.AbilityService)
local MovementService = require(script.Parent.MovementService)
local ResourceService = require(script.Parent.ResourceService)

type Character = CharacterModule.Character
type CombatAction = GameTypes.CombatAction
type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ServerResponseStatus = GameTypes.ServerResponseStatus
type CombatEntity = CombatRegistry.CombatEntity

local log = Logger.new("CombatService")

local function respond(status: ServerResponseStatus, message: string?): ServerCombatResponse
	return { Status = status, Message = message, Movement = nil, Cooldown = nil }
end

-- Idempotente: pedir el estado que ya se tiene se acepta sin cambios, de modo
-- que cliente y servidor no se desincronizan si se pierde o repite un intent.
local function processBlock(entity: CombatEntity, active: boolean): ServerCombatResponse
	local character = entity.Character
	local isBlocking = character:GetState() == "Blocking"
	if not active then
		if isBlocking then
			character:TransitionTo("Idle")
		end
		return respond("Accepted", nil)
	end
	if isBlocking then
		return respond("Accepted", nil)
	end

	local now = os.clock()
	local lastEnded = entity.LastBlockEndedAt
	if lastEnded ~= nil and now - lastEnded < CombatConfig.BlockCooldownSeconds then
		return respond("OnCooldown", nil)
	end

	if not character:TransitionTo("Blocking") then
		return respond("InvalidState", `No se puede bloquear desde {character:GetState()}`)
	end

	-- Solo se concede ventana de parry cada ParryRetrySeconds (D-009).
	local lastAttempt = entity.LastParryAttempt
	if lastAttempt == nil or now - lastAttempt >= CombatConfig.ParryRetrySeconds then
		entity.ParryWindowStart = now
		entity.LastParryAttempt = now
	end
	return respond("Accepted", nil)
end

-- El intent llega ya validado y saneado por ServerNetwork (rate limit + esquema).
local function processIntent(player: Player, intent: CombatIntent): ServerCombatResponse
	local entity = CombatRegistry.GetAlive(player)
	if entity == nil then
		return respond("Rejected", "Personaje no disponible")
	end

	local action: CombatAction = intent.Action
	if action == "Block" then
		return processBlock(entity, intent.Active == true)
	elseif action == "Sprint" then
		MovementService:SetSprint(entity, intent.Active == true)
		return respond("Accepted", nil)
	end
	return AbilityService:ActivateAction(entity, action)
end

local function watchCharacter(entity: CombatEntity): ()
	local character = entity.Character
	-- Character:Destroy() desconecta estas señales.
	character:OnStateChanged(function(oldState, newState)
		if oldState == "Blocking" or oldState == "Parrying" then
			entity.ParryWindowStart = nil
			entity.LastBlockEndedAt = os.clock()
		end
		-- Salir del estado de la habilidad (aturdido, muerto...) la cancela.
		local action = entity.Action
		if action ~= nil and action.Ability.State ~= newState then
			AbilityService:CancelAction(entity)
		end
	end)
	character.ResourceChanged:Connect(function(resourceId: string, newValue: number, oldValue: number)
		if newValue < oldValue then
			ResourceService:NoteSpent(entity, resourceId)
		end
	end)
end

local CombatService = {
	Name = "CombatService",
}

function CombatService:Start(): ()
	ServerNetwork:HandleFunction("CombatIntent", CombatIntentValidator.Validate, processIntent)
end

-- Jugadores (con player) y NPCs (sin player). El modelo debe tener Humanoid y HumanoidRootPart.
function CombatService:RegisterCharacter(player: Player?, model: Model, character: Character): ()
	local entity = CombatRegistry.Create(model, character, player)
	if entity == nil then
		log:Warn("%s no tiene Humanoid o HumanoidRootPart; no se registra", model:GetFullName())
		return
	end
	CombatRegistry.Add(entity)
	watchCharacter(entity)
end

function CombatService:UnregisterCharacter(model: Model): ()
	CombatRegistry.Remove(model)
end

function CombatService:GetEntity(model: Model): CombatEntity?
	return CombatRegistry.Get(model)
end

-- Para NPCs: guardia con las mismas reglas que un jugador.
function CombatService:SetBlocking(model: Model, active: boolean): ServerCombatResponse
	local entity = CombatRegistry.Get(model)
	if entity == nil or not entity.Character:IsAlive() then
		return respond("Rejected", "Personaje no disponible")
	end
	return processBlock(entity, active)
end

function CombatService:IsAbilityReady(model: Model, abilityId: string): boolean
	local entity = CombatRegistry.Get(model)
	return entity ~= nil and AbilityService:IsReady(entity, abilityId)
end

-- Para NPCs: ejecuta una habilidad concreta con las mismas reglas que un jugador.
function CombatService:ActivateAbility(model: Model, abilityId: string): ServerCombatResponse
	local entity = CombatRegistry.Get(model)
	if entity == nil or not entity.Character:IsAlive() then
		return respond("Rejected", "Personaje no disponible")
	end
	return AbilityService:Activate(entity, abilityId)
end

return CombatService
