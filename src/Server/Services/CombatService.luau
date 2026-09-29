--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Character = require(ReplicatedStorage.Shared.Modules.Character)
local HitboxUtil = require(script.Parent.Parent.Modules.HitboxUtil)
local RateLimiter = require(script.Parent.Parent.Modules.RateLimiter)
local CombatIntentValidator = require(script.Parent.Parent.Modules.CombatIntentValidator)

type Character = Character.Character
type CharacterStateName = GameTypes.CharacterStateName
type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ComboDefinition = GameTypes.ComboDefinition
type ComboHitWindow = GameTypes.ComboHitWindow
type HitboxTarget = HitboxUtil.HitboxTarget

export type CombatService = {
	RegisterCombo: (self: CombatService, combo: ComboDefinition) -> (),
	RegisterCharacter: (self: CombatService, player: Player?, model: Model, character: Character) -> (),
	UnregisterCharacter: (self: CombatService, model: Model) -> (),
	ProcessIntent: (self: CombatService, player: Player, payload: unknown) -> ServerCombatResponse,
	Init: (self: CombatService) -> (),
	Shutdown: (self: CombatService) -> (),
}

type TaskSet = { [thread]: boolean }

type CombatServiceInternal = CombatService & {
	_combos: { [string]: ComboDefinition },
	_characters: { [Model]: Character },
	_playerModels: { [Player]: Model },
	_lastComboUse: { [Player]: { [string]: number } },
	-- Inicio de la ventana de parry del bloqueo actual (nil si el bloqueo no la concede).
	_parryWindowStarts: { [Model]: number },
	_lastParryAttempt: { [Model]: number },
	_intentLimiter: RateLimiter.RateLimiter<Player>,
	-- Todas las tareas programadas de cada modelo, para cancelarlas al desregistrarlo.
	_modelTasks: { [Model]: TaskSet },
	-- Tareas del ataque en curso (golpes + recuperación); se cancelan si se sale de Attacking.
	_attackTasks: { [Model]: { thread } },
	_stunRecoveryTasks: { [Model]: thread },
	_stateConnections: { [Model]: RBXScriptConnection },
	_regenThread: thread?,
	_connections: { RBXScriptConnection },
}

local SHUNPO_REIATSU_COST = 15
local SHUNPO_DURATION_SECONDS = 0.4
local PARRY_WINDOW_SECONDS = 0.3
-- Tiempo mínimo entre ventanas de parry: pulsar bloqueo repetidamente no
-- encadena parries; el bloqueo sigue funcionando, pero sin ventana (D-009).
local PARRY_RETRY_SECONDS = 0.8
local PARRY_STUN_SECONDS = 0.8
local POSTURE_BREAK_STUN_SECONDS = 1.5
local BLOCK_DAMAGE_MULTIPLIER = 0.25
local BLOCK_POSTURE_MULTIPLIER = 1.5

-- Tick de baja frecuencia para regeneración pasiva (ver DECISIONS.md D-008).
-- Provisional: se moverá a ResourceService cuando exista.
local REGEN_TICK_SECONDS = 0.25
local REIATSU_REGEN_PER_SECOND = 5
local POSTURE_DECAY_PER_SECOND = 10

-- Rate limit de CombatIntent por jugador: ráfaga de 10, 8 intents/s sostenidos.
local INTENT_BURST = 10
local INTENTS_PER_SECOND = 8

local CombatService: CombatServiceInternal = {} :: CombatServiceInternal
CombatService.__index = CombatService :: any

CombatService._combos = {}
CombatService._characters = {}
CombatService._playerModels = {}
CombatService._lastComboUse = {}
CombatService._parryWindowStarts = {}
CombatService._lastParryAttempt = {}
CombatService._intentLimiter = RateLimiter.new(INTENT_BURST, INTENTS_PER_SECOND)
CombatService._modelTasks = {}
CombatService._attackTasks = {}
CombatService._stunRecoveryTasks = {}
CombatService._stateConnections = {}
CombatService._regenThread = nil
CombatService._connections = {}

local function respond(status: GameTypes.ServerResponseStatus, message: string?): ServerCombatResponse
	return {
		Status = status,
		Message = message,
		AppliedDamage = nil,
		TargetUserId = nil,
	}
end

local function getComboDuration(combo: ComboDefinition): number
	local duration = 0
	for _, hit in ipairs(combo.Hits) do
		if hit.EndTime > duration then
			duration = hit.EndTime
		end
	end
	return duration
end

-- Programa una tarea asociada a un modelo. La tarea se elimina de su conjunto
-- al ejecutarse, de modo que las listas no crecen indefinidamente.
local function scheduleFor(self: CombatServiceInternal, model: Model, delaySeconds: number, callback: () -> ()): thread
	local taskSet = self._modelTasks[model]
	if taskSet == nil then
		taskSet = {}
		self._modelTasks[model] = taskSet
	end

	local thread: thread
	thread = task.delay(delaySeconds, function()
		taskSet[thread] = nil
		callback()
	end)
	taskSet[thread] = true

	return thread
end

-- Solo se cancelan hilos suspendidos: un hilo puede provocar su propia
-- cancelación (p. ej. un golpe que recibe parry cancela el ataque en curso).
local function cancelTask(self: CombatServiceInternal, model: Model, thread: thread): ()
	local taskSet = self._modelTasks[model]
	if taskSet ~= nil then
		taskSet[thread] = nil
	end
	if coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
end

local function cancelAllTasks(self: CombatServiceInternal, model: Model): ()
	local taskSet = self._modelTasks[model]
	if taskSet == nil then
		return
	end
	for thread in pairs(taskSet) do
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
	self._modelTasks[model] = nil
end

local function cancelAttack(self: CombatServiceInternal, model: Model): ()
	local attackTasks = self._attackTasks[model]
	if attackTasks == nil then
		return
	end
	self._attackTasks[model] = nil
	for _, thread in ipairs(attackTasks) do
		cancelTask(self, model, thread)
	end
end

local function applyStun(self: CombatServiceInternal, model: Model, character: Character, duration: number): ()
	if character:GetState() ~= "Stunned" then
		local ok = character:TransitionTo("Stunned")
		if not ok then
			return
		end
	end

	-- Un nuevo aturdimiento reinicia la duración en lugar de acumular salidas.
	local previousRecovery = self._stunRecoveryTasks[model]
	if previousRecovery ~= nil then
		cancelTask(self, model, previousRecovery)
	end

	self._stunRecoveryTasks[model] = scheduleFor(self, model, duration, function()
		self._stunRecoveryTasks[model] = nil
		if character:GetState() == "Stunned" then
			character:TransitionTo("Idle")
		end
	end)
end

local function onCharacterStateChanged(
	self: CombatServiceInternal,
	model: Model,
	oldState: CharacterStateName,
	_newState: CharacterStateName
): ()
	if oldState == "Attacking" then
		cancelAttack(self, model)
	elseif oldState == "Blocking" then
		self._parryWindowStarts[model] = nil
	end
end

function CombatService:RegisterCombo(combo: ComboDefinition): ()
	local self = (self :: any) :: CombatServiceInternal
	self._combos[combo.Id] = combo
end

function CombatService:RegisterCharacter(player: Player?, model: Model, character: Character): ()
	local self = (self :: any) :: CombatServiceInternal
	self._characters[model] = character

	self._stateConnections[model] = character:OnStateChanged(function(oldState, newState)
		onCharacterStateChanged(self, model, oldState, newState)
	end)

	if player ~= nil then
		self._playerModels[player] = model
		self._lastComboUse[player] = self._lastComboUse[player] or {}
	end
end

function CombatService:UnregisterCharacter(model: Model): ()
	local self = (self :: any) :: CombatServiceInternal

	cancelAllTasks(self, model)
	self._attackTasks[model] = nil
	self._stunRecoveryTasks[model] = nil

	local stateConnection = self._stateConnections[model]
	if stateConnection ~= nil then
		stateConnection:Disconnect()
		self._stateConnections[model] = nil
	end

	self._characters[model] = nil
	self._parryWindowStarts[model] = nil
	self._lastParryAttempt[model] = nil

	for player, playerModel in pairs(self._playerModels) do
		if playerModel == model then
			self._playerModels[player] = nil
			self._lastComboUse[player] = nil
		end
	end
end

local function resolveHit(
	self: CombatServiceInternal,
	attackerModel: Model,
	target: HitboxTarget,
	hit: ComboHitWindow
): ()
	local defenderCharacter = self._characters[target.Model]
	if defenderCharacter == nil or not defenderCharacter:IsAlive() then
		return
	end

	local damage = hit.BaseDamage
	local postureDamage = hit.PostureDamage

	if defenderCharacter:GetState() == "Blocking" then
		local blockStart = self._parryWindowStarts[target.Model]

		if blockStart ~= nil and (os.clock() - blockStart) <= PARRY_WINDOW_SECONDS then
			local attackerCharacter = self._characters[attackerModel]
			if attackerCharacter ~= nil and attackerCharacter:GetState() == "Attacking" then
				applyStun(self, attackerModel, attackerCharacter, PARRY_STUN_SECONDS)
			end
			return
		end

		damage *= BLOCK_DAMAGE_MULTIPLIER
		postureDamage *= BLOCK_POSTURE_MULTIPLIER
	end

	defenderCharacter:TakeDamage(damage)
	defenderCharacter:ApplyPostureDamage(postureDamage)

	if defenderCharacter:IsAlive() and defenderCharacter:GetPosture() >= defenderCharacter:GetMaxPosture() then
		defenderCharacter:ResetPosture()
		applyStun(self, target.Model, defenderCharacter, POSTURE_BREAK_STUN_SECONDS)
	end
end

local function scheduleCombo(
	self: CombatServiceInternal,
	attackerModel: Model,
	attackerCharacter: Character,
	combo: ComboDefinition
): ()
	local ignoreList: { Instance } = { attackerModel }
	local overlapParams = HitboxUtil.BuildOverlapParams(ignoreList)
	local attackTasks: { thread } = {}

	for _, hit in ipairs(combo.Hits) do
		table.insert(
			attackTasks,
			scheduleFor(self, attackerModel, hit.StartTime, function()
				if not attackerCharacter:IsAlive() or attackerCharacter:GetState() ~= "Attacking" then
					return
				end

				local rootPart = attackerModel.PrimaryPart
				if rootPart == nil then
					return
				end

				local targets = HitboxUtil.FindTargets(hit.Hitbox, rootPart.CFrame, overlapParams)
				for _, target in ipairs(targets) do
					resolveHit(self, attackerModel, target, hit)
				end
			end)
		)
	end

	local duration = getComboDuration(combo)
	table.insert(
		attackTasks,
		scheduleFor(self, attackerModel, duration, function()
			-- Se vacía antes de la transición para que cancelAttack no toque este hilo.
			self._attackTasks[attackerModel] = nil
			if attackerCharacter:GetState() == "Attacking" then
				attackerCharacter:TransitionTo("Idle")
			end
		end)
	)

	self._attackTasks[attackerModel] = attackTasks
end

-- Devuelve el personaje del jugador solo si está registrado y vivo.
local function getActiveCharacter(self: CombatServiceInternal, player: Player): (Model?, Character?)
	local model = self._playerModels[player]
	if model == nil then
		return nil, nil
	end

	local character = self._characters[model]
	if character == nil or not character:IsAlive() then
		return nil, nil
	end

	return model, character
end

local function processAttack(self: CombatServiceInternal, player: Player, intent: CombatIntent): ServerCombatResponse
	local model, character = getActiveCharacter(self, player)
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no disponible")
	end

	if intent.ComboId == nil then
		return respond("Rejected", "Combo no especificado")
	end

	local combo = self._combos[intent.ComboId]
	if combo == nil then
		return respond("Rejected", "Combo inexistente")
	end

	if not character:CanTransitionTo("Attacking") then
		return respond("InvalidState", string.format("No se puede atacar desde %s", character:GetState()))
	end

	local playerCooldowns = self._lastComboUse[player]
	if playerCooldowns == nil then
		playerCooldowns = {}
		self._lastComboUse[player] = playerCooldowns
	end

	local lastUse = playerCooldowns[combo.Id]
	local now = os.clock()
	if lastUse ~= nil and (now - lastUse) < combo.CooldownSeconds then
		return respond("OnCooldown", nil)
	end

	if combo.ReiatsuCost > 0 and not character:SpendReiatsu(combo.ReiatsuCost) then
		return respond("InsufficientResource", "Reiatsu insuficiente")
	end

	local ok = character:TransitionTo("Attacking")
	if not ok then
		return respond("InvalidState", "Transición a Attacking bloqueada")
	end

	playerCooldowns[combo.Id] = now
	scheduleCombo(self, model, character, combo)

	return respond("Accepted", nil)
end

local function processBlock(self: CombatServiceInternal, player: Player, _intent: CombatIntent): ServerCombatResponse
	local model, character = getActiveCharacter(self, player)
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no disponible")
	end

	if character:GetState() == "Blocking" then
		local ok = character:TransitionTo("Idle")
		return respond(ok and "Accepted" or "InvalidState", nil)
	end

	if not character:CanTransitionTo("Blocking") then
		return respond("InvalidState", string.format("No se puede bloquear desde %s", character:GetState()))
	end

	character:TransitionTo("Blocking")

	local now = os.clock()
	local lastParryAttempt = self._lastParryAttempt[model]
	if lastParryAttempt == nil or (now - lastParryAttempt) >= PARRY_RETRY_SECONDS then
		self._parryWindowStarts[model] = now
		self._lastParryAttempt[model] = now
	end

	return respond("Accepted", nil)
end

local function processShunpo(self: CombatServiceInternal, player: Player, _intent: CombatIntent): ServerCombatResponse
	local model, character = getActiveCharacter(self, player)
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no disponible")
	end

	if not character:CanTransitionTo("Shunpo") then
		return respond("InvalidState", string.format("No se puede usar Shunpo desde %s", character:GetState()))
	end

	if not character:SpendReiatsu(SHUNPO_REIATSU_COST) then
		return respond("InsufficientResource", "Reiatsu insuficiente")
	end

	character:TransitionTo("Shunpo")

	scheduleFor(self, model, SHUNPO_DURATION_SECONDS, function()
		if character:GetState() == "Shunpo" then
			character:TransitionTo("Idle")
		end
	end)

	return respond("Accepted", nil)
end

local function regenerate(self: CombatServiceInternal, deltaSeconds: number): ()
	for _, character in pairs(self._characters) do
		if character:IsAlive() then
			if character:GetReiatsu() < character:GetMaxReiatsu() then
				character:RestoreReiatsu(REIATSU_REGEN_PER_SECOND * deltaSeconds)
			end

			local state = character:GetState()
			if character:GetPosture() > 0 and state ~= "Blocking" and state ~= "Stunned" then
				character:RecoverPosture(POSTURE_DECAY_PER_SECOND * deltaSeconds)
			end
		end
	end
end

function CombatService:ProcessIntent(player: Player, payload: unknown): ServerCombatResponse
	local self = (self :: any) :: CombatServiceInternal

	if not self._intentLimiter:Consume(player) then
		return respond("Rejected", "Demasiadas peticiones")
	end

	local intent, validationError = CombatIntentValidator.Validate(payload)
	if intent == nil then
		return respond("Rejected", validationError)
	end

	if intent.Type == "Attack" then
		return processAttack(self, player, intent)
	elseif intent.Type == "Block" then
		return processBlock(self, player, intent)
	elseif intent.Type == "Shunpo" then
		return processShunpo(self, player, intent)
	else
		return respond("Rejected", "Sistema de habilidades pendiente")
	end
end

function CombatService:Init(): ()
	local self = (self :: any) :: CombatServiceInternal

	if self._regenThread ~= nil then
		return
	end

	table.insert(
		self._connections,
		Players.PlayerRemoving:Connect(function(player)
			self._intentLimiter:Remove(player)
		end)
	)

	self._regenThread = task.spawn(function()
		while true do
			local deltaSeconds = task.wait(REGEN_TICK_SECONDS)
			regenerate(self, deltaSeconds)
		end
	end)
end

function CombatService:Shutdown(): ()
	local self = (self :: any) :: CombatServiceInternal

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._regenThread ~= nil then
		task.cancel(self._regenThread)
		self._regenThread = nil
	end

	for model in pairs(self._characters) do
		self:UnregisterCharacter(model)
	end

	table.clear(self._combos)
	table.clear(self._characters)
	table.clear(self._playerModels)
	table.clear(self._lastComboUse)
	table.clear(self._parryWindowStarts)
	table.clear(self._lastParryAttempt)
	self._intentLimiter:Clear()
	table.clear(self._modelTasks)
	table.clear(self._attackTasks)
	table.clear(self._stunRecoveryTasks)
	table.clear(self._stateConnections)
end

return (CombatService :: any) :: CombatService
