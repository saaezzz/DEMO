--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local HitboxUtil = require(script.Parent.Parent.Modules.HitboxUtil)
local RateLimiter = require(script.Parent.Parent.Modules.RateLimiter)
local CombatIntentValidator = require(script.Parent.Parent.Modules.CombatIntentValidator)

type Character = CharacterModule.Character
type CharacterStateName = GameTypes.CharacterStateName
type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ServerResponseStatus = GameTypes.ServerResponseStatus
type ComboDefinition = GameTypes.ComboDefinition
type ComboHitWindow = GameTypes.ComboHitWindow
type HitboxTarget = HitboxUtil.HitboxTarget

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

-- Tick de baja frecuencia para regeneración pasiva (D-008).
-- Provisional: se moverá a ResourceService cuando exista.
local REGEN_TICK_SECONDS = 0.25
local REIATSU_REGEN_PER_SECOND = 5
local POSTURE_DECAY_PER_SECOND = 10

-- Rate limit de CombatIntent por jugador: ráfaga de 10, 8 intents/s sostenidos.
local INTENT_BURST = 10
local INTENTS_PER_SECOND = 8

type TaskSet = { [thread]: boolean }

local combos: { [string]: ComboDefinition } = {}
local characters: { [Model]: Character } = {}
local playerModels: { [Player]: Model } = {}
-- Por jugador (no por modelo) para que morir no reinicie los cooldowns.
local lastComboUse: { [Player]: { [string]: number } } = {}
-- Inicio de la ventana de parry del bloqueo actual (sin entrada si el bloqueo no la concede).
local parryWindowStarts: { [Model]: number } = {}
local lastParryAttempt: { [Model]: number } = {}
-- Todas las tareas programadas de cada modelo, para cancelarlas al desregistrarlo.
local modelTasks: { [Model]: TaskSet } = {}
-- Tareas del ataque en curso (golpes + recuperación); se cancelan al salir de Attacking.
local attackTasks: { [Model]: { thread } } = {}
local stunRecoveryTasks: { [Model]: thread } = {}
local stateConnections: { [Model]: RBXScriptConnection } = {}
local intentLimiter = RateLimiter.new(INTENT_BURST, INTENTS_PER_SECOND)
local regenThread: thread? = nil
local connections: { RBXScriptConnection } = {}

local function respond(status: ServerResponseStatus, message: string?): ServerCombatResponse
	return {
		Status = status,
		Message = message,
	}
end

local function getComboDuration(combo: ComboDefinition): number
	local duration = 0
	for _, hit in combo.Hits do
		duration = math.max(duration, hit.EndTime)
	end
	return duration
end

local function getOrCreateTaskSet(model: Model): TaskSet
	local taskSet: TaskSet? = modelTasks[model]
	if taskSet ~= nil then
		return taskSet
	end
	local newTaskSet: TaskSet = {}
	modelTasks[model] = newTaskSet
	return newTaskSet
end

local function getOrCreateCooldowns(player: Player): { [string]: number }
	local cooldowns: { [string]: number }? = lastComboUse[player]
	if cooldowns ~= nil then
		return cooldowns
	end
	local newCooldowns: { [string]: number } = {}
	lastComboUse[player] = newCooldowns
	return newCooldowns
end

-- Programa una tarea asociada a un modelo. La tarea se elimina de su conjunto
-- al ejecutarse, de modo que las listas no crecen indefinidamente.
local function scheduleFor(model: Model, delaySeconds: number, callback: () -> ()): thread
	local tasks = getOrCreateTaskSet(model)

	local thread: thread
	thread = task.delay(delaySeconds, function()
		tasks[thread] = nil
		callback()
	end)
	tasks[thread] = true

	return thread
end

-- Solo se cancelan hilos suspendidos: un hilo puede provocar su propia
-- cancelación (p. ej. un golpe que recibe parry cancela el ataque en curso).
local function cancelTask(model: Model, thread: thread): ()
	local taskSet: TaskSet? = modelTasks[model]
	if taskSet ~= nil then
		taskSet[thread] = nil
	end
	if coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
end

local function cancelAllTasks(model: Model): ()
	local taskSet: TaskSet? = modelTasks[model]
	if taskSet == nil then
		return
	end
	modelTasks[model] = nil
	for thread in taskSet do
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
end

local function cancelAttack(model: Model): ()
	local tasks: { thread }? = attackTasks[model]
	if tasks == nil then
		return
	end
	attackTasks[model] = nil
	for _, thread in tasks do
		cancelTask(model, thread)
	end
end

local function applyStun(model: Model, character: Character, duration: number): ()
	if character:GetState() ~= "Stunned" then
		local ok = character:TransitionTo("Stunned")
		if not ok then
			return
		end
	end

	-- Un nuevo aturdimiento reinicia la duración en lugar de acumular salidas.
	local previousRecovery: thread? = stunRecoveryTasks[model]
	if previousRecovery ~= nil then
		cancelTask(model, previousRecovery)
	end

	stunRecoveryTasks[model] = scheduleFor(model, duration, function()
		stunRecoveryTasks[model] = nil
		if character:GetState() == "Stunned" then
			character:TransitionTo("Idle")
		end
	end)
end

local function onCharacterStateChanged(model: Model, oldState: CharacterStateName): ()
	if oldState == "Attacking" then
		cancelAttack(model)
	elseif oldState == "Blocking" then
		parryWindowStarts[model] = nil
	end
end

local function unregisterCharacter(model: Model): ()
	cancelAllTasks(model)
	attackTasks[model] = nil
	stunRecoveryTasks[model] = nil

	local stateConnection: RBXScriptConnection? = stateConnections[model]
	if stateConnection ~= nil then
		stateConnection:Disconnect()
		stateConnections[model] = nil
	end

	characters[model] = nil
	parryWindowStarts[model] = nil
	lastParryAttempt[model] = nil

	for player, playerModel in playerModels do
		if playerModel == model then
			playerModels[player] = nil
		end
	end
end

local function resolveHit(attackerModel: Model, target: HitboxTarget, hit: ComboHitWindow): ()
	local defender: Character? = characters[target.Model]
	if defender == nil or not defender:IsAlive() then
		return
	end

	local damage = hit.BaseDamage
	local postureDamage = hit.PostureDamage

	if defender:GetState() == "Blocking" then
		local parryWindowStart: number? = parryWindowStarts[target.Model]
		if parryWindowStart ~= nil and (os.clock() - parryWindowStart) <= PARRY_WINDOW_SECONDS then
			local attacker: Character? = characters[attackerModel]
			if attacker ~= nil and attacker:GetState() == "Attacking" then
				applyStun(attackerModel, attacker, PARRY_STUN_SECONDS)
			end
			return
		end

		damage *= BLOCK_DAMAGE_MULTIPLIER
		postureDamage *= BLOCK_POSTURE_MULTIPLIER
	end

	defender:TakeDamage(damage)
	defender:ApplyPostureDamage(postureDamage)

	if defender:IsAlive() and defender:GetPosture() >= defender:GetMaxPosture() then
		defender:ResetPosture()
		applyStun(target.Model, defender, POSTURE_BREAK_STUN_SECONDS)
	end
end

local function scheduleCombo(attackerModel: Model, attacker: Character, combo: ComboDefinition): ()
	local overlapParams = HitboxUtil.BuildOverlapParams({ attackerModel })
	local tasks: { thread } = {}

	for _, hit in combo.Hits do
		table.insert(
			tasks,
			scheduleFor(attackerModel, hit.StartTime, function()
				if not attacker:IsAlive() or attacker:GetState() ~= "Attacking" then
					return
				end

				local rootPart = attackerModel.PrimaryPart
				if rootPart == nil then
					return
				end

				for _, target in HitboxUtil.FindTargets(hit.Hitbox, rootPart.CFrame, overlapParams) do
					resolveHit(attackerModel, target, hit)
				end
			end)
		)
	end

	table.insert(
		tasks,
		scheduleFor(attackerModel, getComboDuration(combo), function()
			-- Se vacía antes de la transición para que cancelAttack no toque este hilo.
			attackTasks[attackerModel] = nil
			if attacker:GetState() == "Attacking" then
				attacker:TransitionTo("Idle")
			end
		end)
	)

	attackTasks[attackerModel] = tasks
end

-- Devuelve el personaje del jugador solo si está registrado y vivo.
local function getActiveCharacter(player: Player): (Model?, Character?)
	local model: Model? = playerModels[player]
	if model == nil then
		return nil, nil
	end

	local character: Character? = characters[model]
	if character == nil or not character:IsAlive() then
		return nil, nil
	end

	return model, character
end

local function processAttack(player: Player, intent: CombatIntent): ServerCombatResponse
	local model, character = getActiveCharacter(player)
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no disponible")
	end

	local comboId = intent.ComboId
	if comboId == nil then
		return respond("Rejected", "Combo no especificado")
	end

	local combo: ComboDefinition? = combos[comboId]
	if combo == nil then
		return respond("Rejected", "Combo inexistente")
	end

	if not character:CanTransitionTo("Attacking") then
		return respond("InvalidState", string.format("No se puede atacar desde %s", character:GetState()))
	end

	local cooldowns = getOrCreateCooldowns(player)
	local now = os.clock()
	local lastUse: number? = cooldowns[combo.Id]
	if lastUse ~= nil and (now - lastUse) < combo.CooldownSeconds then
		return respond("OnCooldown", nil)
	end

	if combo.ReiatsuCost > 0 and not character:SpendReiatsu(combo.ReiatsuCost) then
		return respond("InsufficientResource", "Reiatsu insuficiente")
	end

	if not character:TransitionTo("Attacking") then
		return respond("InvalidState", "Transición a Attacking bloqueada")
	end

	cooldowns[combo.Id] = now
	scheduleCombo(model, character, combo)

	return respond("Accepted", nil)
end

local function processBlock(player: Player): ServerCombatResponse
	local model, character = getActiveCharacter(player)
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no disponible")
	end

	if character:GetState() == "Blocking" then
		local ok = character:TransitionTo("Idle")
		return respond(if ok then "Accepted" else "InvalidState", nil)
	end

	if not character:TransitionTo("Blocking") then
		return respond("InvalidState", string.format("No se puede bloquear desde %s", character:GetState()))
	end

	local now = os.clock()
	local lastAttempt: number? = lastParryAttempt[model]
	if lastAttempt == nil or (now - lastAttempt) >= PARRY_RETRY_SECONDS then
		parryWindowStarts[model] = now
		lastParryAttempt[model] = now
	end

	return respond("Accepted", nil)
end

local function processShunpo(player: Player): ServerCombatResponse
	local model, character = getActiveCharacter(player)
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

	scheduleFor(model, SHUNPO_DURATION_SECONDS, function()
		if character:GetState() == "Shunpo" then
			character:TransitionTo("Idle")
		end
	end)

	return respond("Accepted", nil)
end

local function regenerate(deltaSeconds: number): ()
	for _, character in characters do
		if character:IsAlive() then
			character:RestoreReiatsu(REIATSU_REGEN_PER_SECOND * deltaSeconds)

			local state = character:GetState()
			if state ~= "Blocking" and state ~= "Stunned" then
				character:RecoverPosture(POSTURE_DECAY_PER_SECOND * deltaSeconds)
			end
		end
	end
end

local function onPlayerRemoving(player: Player): ()
	intentLimiter:Remove(player)
	lastComboUse[player] = nil
end

local CombatService = {}

function CombatService:RegisterCombo(combo: ComboDefinition): ()
	combos[combo.Id] = combo
end

function CombatService:RegisterCharacter(player: Player?, model: Model, character: Character): ()
	characters[model] = character

	stateConnections[model] = character:OnStateChanged(function(oldState)
		onCharacterStateChanged(model, oldState)
	end)

	if player ~= nil then
		playerModels[player] = model
	end
end

function CombatService:UnregisterCharacter(model: Model): ()
	unregisterCharacter(model)
end

function CombatService:ProcessIntent(player: Player, payload: unknown): ServerCombatResponse
	if not intentLimiter:Consume(player) then
		return respond("Rejected", "Demasiadas peticiones")
	end

	local intent, validationError = CombatIntentValidator.Validate(payload)
	if intent == nil then
		return respond("Rejected", validationError)
	end

	if intent.Type == "Attack" then
		return processAttack(player, intent)
	elseif intent.Type == "Block" then
		return processBlock(player)
	else
		return processShunpo(player)
	end
end

function CombatService:Init(): ()
	if regenThread ~= nil then
		return
	end

	table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))

	regenThread = task.spawn(function()
		while true do
			regenerate(task.wait(REGEN_TICK_SECONDS))
		end
	end)
end

function CombatService:Shutdown(): ()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	if regenThread ~= nil then
		task.cancel(regenThread)
		regenThread = nil
	end

	for model in characters do
		unregisterCharacter(model)
	end

	table.clear(combos)
	table.clear(lastComboUse)
	intentLimiter:Clear()
end

return CombatService
