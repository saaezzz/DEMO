--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Character = require(ReplicatedStorage.Shared.Modules.Character)
local HitboxUtil = require(script.Parent.Parent.Modules.HitboxUtil)

type Character = Character.Character
type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ComboDefinition = GameTypes.ComboDefinition
type ComboHitWindow = GameTypes.ComboHitWindow
type HitboxTarget = HitboxUtil.HitboxTarget

export type CombatService = {
	RegisterCombo: (self: CombatService, combo: ComboDefinition) -> (),
	RegisterCharacter: (self: CombatService, player: Player?, model: Model, character: Character) -> (),
	UnregisterCharacter: (self: CombatService, model: Model) -> (),
	ProcessIntent: (self: CombatService, player: Player, intent: CombatIntent) -> ServerCombatResponse,
	Init: (self: CombatService) -> (),
	Shutdown: (self: CombatService) -> (),
}

type CombatServiceInternal = CombatService & {
	_combos: { [string]: ComboDefinition },
	_characters: { [Model]: Character },
	_playerModels: { [Player]: Model },
	_lastComboUse: { [Player]: { [string]: number } },
	_blockStartTimes: { [Model]: number },
	_pendingTasks: { thread },
	_connections: { RBXScriptConnection },
}

local SHUNPO_REIATSU_COST = 15
local SHUNPO_DURATION_SECONDS = 0.4
local PARRY_WINDOW_SECONDS = 0.3
local BLOCK_DAMAGE_MULTIPLIER = 0.25
local BLOCK_POSTURE_MULTIPLIER = 1.5

local CombatService: CombatServiceInternal = {} :: CombatServiceInternal
CombatService.__index = CombatService :: any

CombatService._combos = {}
CombatService._characters = {}
CombatService._playerModels = {}
CombatService._lastComboUse = {}
CombatService._blockStartTimes = {}
CombatService._pendingTasks = {}
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

function CombatService:RegisterCombo(combo: ComboDefinition): ()
	self._combos[combo.Id] = combo
end

function CombatService:RegisterCharacter(player: Player?, model: Model, character: Character): ()
	self._characters[model] = character

	if player ~= nil then
		self._playerModels[player] = model
		self._lastComboUse[player] = self._lastComboUse[player] or {}
	end
end

function CombatService:UnregisterCharacter(model: Model): ()
	self._characters[model] = nil
	self._blockStartTimes[model] = nil

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
		local blockStart = self._blockStartTimes[target.Model]

		if blockStart ~= nil and (os.clock() - blockStart) <= PARRY_WINDOW_SECONDS then
			local attackerCharacter = self._characters[attackerModel]
			if attackerCharacter ~= nil and attackerCharacter:GetState() == "Attacking" then
				attackerCharacter:TransitionTo("Stunned")
			end
			return
		end

		damage *= BLOCK_DAMAGE_MULTIPLIER
		postureDamage *= BLOCK_POSTURE_MULTIPLIER
	end

	defenderCharacter:TakeDamage(damage)
	defenderCharacter:ApplyPostureDamage(postureDamage)
end

local function scheduleCombo(self: CombatServiceInternal, attackerModel: Model, combo: ComboDefinition): ()
	local ignoreList: { Instance } = { attackerModel }
	local overlapParams = HitboxUtil.BuildOverlapParams(ignoreList)

	for _, hit in ipairs(combo.Hits) do
		local thread = task.delay(hit.StartTime, function()
			local rootPart = attackerModel.PrimaryPart
			if rootPart == nil then
				return
			end

			local targets = HitboxUtil.FindTargets(hit.Hitbox, rootPart.CFrame, overlapParams)
			for _, target in ipairs(targets) do
				resolveHit(self, attackerModel, target, hit)
			end
		end)
		table.insert(self._pendingTasks, thread)
	end

	local duration = getComboDuration(combo)
	local recoveryThread = task.delay(duration, function()
		local attackerCharacter = self._characters[attackerModel]
		if attackerCharacter ~= nil and attackerCharacter:GetState() == "Attacking" then
			attackerCharacter:TransitionTo("Idle")
		end
	end)
	table.insert(self._pendingTasks, recoveryThread)
end

local function processAttack(self: CombatServiceInternal, player: Player, intent: CombatIntent): ServerCombatResponse
	local model = self._playerModels[player]
	if model == nil then
		return respond("Rejected", "Personaje no registrado")
	end

	local character = self._characters[model]
	if character == nil then
		return respond("Rejected", "Personaje no registrado")
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

	if not character:SpendReiatsu(combo.ReiatsuCost) then
		return respond("InsufficientResource", "Reiatsu insuficiente")
	end

	local ok = character:TransitionTo("Attacking")
	if not ok then
		return respond("InvalidState", "Transición a Attacking bloqueada")
	end

	playerCooldowns[combo.Id] = now
	scheduleCombo(self, model, combo)

	return respond("Accepted", nil)
end

local function processBlock(self: CombatServiceInternal, player: Player, _intent: CombatIntent): ServerCombatResponse
	local model = self._playerModels[player]
	local character = model ~= nil and self._characters[model] or nil
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no registrado")
	end

	if character:GetState() == "Blocking" then
		local ok = character:TransitionTo("Idle")
		if ok then
			self._blockStartTimes[model] = nil
		end
		return respond(ok and "Accepted" or "InvalidState", nil)
	end

	if not character:CanTransitionTo("Blocking") then
		return respond("InvalidState", string.format("No se puede bloquear desde %s", character:GetState()))
	end

	character:TransitionTo("Blocking")
	self._blockStartTimes[model] = os.clock()

	return respond("Accepted", nil)
end

local function processShunpo(self: CombatServiceInternal, player: Player, _intent: CombatIntent): ServerCombatResponse
	local model = self._playerModels[player]
	local character = model ~= nil and self._characters[model] or nil
	if model == nil or character == nil then
		return respond("Rejected", "Personaje no registrado")
	end

	if not character:CanTransitionTo("Shunpo") then
		return respond("InvalidState", string.format("No se puede usar Shunpo desde %s", character:GetState()))
	end

	if not character:SpendReiatsu(SHUNPO_REIATSU_COST) then
		return respond("InsufficientResource", "Reiatsu insuficiente")
	end

	character:TransitionTo("Shunpo")

	local thread = task.delay(SHUNPO_DURATION_SECONDS, function()
		if character:GetState() == "Shunpo" then
			character:TransitionTo("Idle")
		end
	end)
	table.insert(self._pendingTasks, thread)

	return respond("Accepted", nil)
end

function CombatService:ProcessIntent(player: Player, intent: CombatIntent): ServerCombatResponse
	local self = (self :: any) :: CombatServiceInternal

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
end

function CombatService:Shutdown(): ()
	local self = (self :: any) :: CombatServiceInternal

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	for _, thread in ipairs(self._pendingTasks) do
		if coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
	end
	table.clear(self._pendingTasks)

	table.clear(self._combos)
	table.clear(self._characters)
	table.clear(self._playerModels)
	table.clear(self._lastComboUse)
	table.clear(self._blockStartTimes)
end

return (CombatService :: any) :: CombatService
