--!strict

local StateMachine = require(script.Parent.StateMachine)
local GameTypes = require(script.Parent.Parent.Types.GameTypes)

type CharacterAttributes = GameTypes.CharacterAttributes
type CharacterRace = GameTypes.CharacterRace
type CharacterStateName = GameTypes.CharacterStateName
type StateTransitionTable = GameTypes.StateTransitionTable
type StateMachine = StateMachine.StateMachine

-- Tabla de transiciones permitidas para cualquier personaje del juego.
-- Desde Ragdoll solo se puede volver a Idle.
local DEFAULT_STATE_TRANSITIONS: StateTransitionTable = {
	Idle = { "Attacking", "Blocking", "Shunpo", "Casting", "Stunned", "Ragdoll" },
	Attacking = { "Idle", "Stunned", "Ragdoll" },
	Blocking = { "Idle", "Stunned", "Ragdoll" },
	Shunpo = { "Idle", "Stunned", "Ragdoll" },
	Casting = { "Idle", "Stunned", "Ragdoll" },
	Stunned = { "Idle", "Ragdoll" },
	Ragdoll = { "Idle" },
}

local Character = {}
Character.__index = Character

type CharacterData = {
	Race: CharacterRace,
	Level: number,

	-- Señales: (newValue: number, oldValue: number) para vida, Reiatsu y postura.
	HealthChanged: RBXScriptSignal,
	ReiatsuChanged: RBXScriptSignal,
	PostureChanged: RBXScriptSignal,
	Died: RBXScriptSignal,

	_health: number,
	_maxHealth: number,
	_reiatsu: number,
	_maxReiatsu: number,
	_posture: number,
	_maxPosture: number,
	_isAlive: boolean,
	_stateMachine: StateMachine,
	_healthChangedEvent: BindableEvent,
	_reiatsuChangedEvent: BindableEvent,
	_postureChangedEvent: BindableEvent,
	_diedEvent: BindableEvent,
	_destroyed: boolean,
}

export type Character = typeof(setmetatable({} :: CharacterData, Character))

function Character.new(attributes: CharacterAttributes): Character
	local healthChangedEvent = Instance.new("BindableEvent")
	local reiatsuChangedEvent = Instance.new("BindableEvent")
	local postureChangedEvent = Instance.new("BindableEvent")
	local diedEvent = Instance.new("BindableEvent")

	return setmetatable({
		Race = attributes.Race,
		Level = attributes.Level,

		HealthChanged = healthChangedEvent.Event,
		ReiatsuChanged = reiatsuChangedEvent.Event,
		PostureChanged = postureChangedEvent.Event,
		Died = diedEvent.Event,

		_health = math.clamp(attributes.Health, 0, attributes.MaxHealth),
		_maxHealth = attributes.MaxHealth,
		_reiatsu = math.clamp(attributes.Reiatsu, 0, attributes.MaxReiatsu),
		_maxReiatsu = attributes.MaxReiatsu,
		_posture = math.clamp(attributes.Posture, 0, attributes.MaxPosture),
		_maxPosture = attributes.MaxPosture,
		_isAlive = attributes.Health > 0,
		_stateMachine = StateMachine.new("Idle", DEFAULT_STATE_TRANSITIONS),
		_healthChangedEvent = healthChangedEvent,
		_reiatsuChangedEvent = reiatsuChangedEvent,
		_postureChangedEvent = postureChangedEvent,
		_diedEvent = diedEvent,
		_destroyed = false,
	}, Character)
end

function Character.GetHealth(self: Character): number
	return self._health
end

function Character.GetMaxHealth(self: Character): number
	return self._maxHealth
end

function Character.GetReiatsu(self: Character): number
	return self._reiatsu
end

function Character.GetMaxReiatsu(self: Character): number
	return self._maxReiatsu
end

function Character.GetPosture(self: Character): number
	return self._posture
end

function Character.GetMaxPosture(self: Character): number
	return self._maxPosture
end

function Character.IsAlive(self: Character): boolean
	return self._isAlive
end

function Character.TakeDamage(self: Character, amount: number): number
	if self._destroyed or not self._isAlive or amount <= 0 then
		return self._health
	end

	local oldHealth = self._health
	self._health = math.clamp(oldHealth - amount, 0, self._maxHealth)
	self._healthChangedEvent:Fire(self._health, oldHealth)

	if self._health <= 0 then
		self._isAlive = false
		self._diedEvent:Fire()
	end

	return self._health
end

function Character.Heal(self: Character, amount: number): number
	if self._destroyed or not self._isAlive or amount <= 0 then
		return self._health
	end

	local oldHealth = self._health
	self._health = math.clamp(oldHealth + amount, 0, self._maxHealth)
	self._healthChangedEvent:Fire(self._health, oldHealth)

	return self._health
end

function Character.SpendReiatsu(self: Character, amount: number): boolean
	if self._destroyed or amount <= 0 or self._reiatsu < amount then
		return false
	end

	local oldReiatsu = self._reiatsu
	self._reiatsu = math.clamp(oldReiatsu - amount, 0, self._maxReiatsu)
	self._reiatsuChangedEvent:Fire(self._reiatsu, oldReiatsu)

	return true
end

function Character.RestoreReiatsu(self: Character, amount: number): number
	if self._destroyed or amount <= 0 or self._reiatsu >= self._maxReiatsu then
		return self._reiatsu
	end

	local oldReiatsu = self._reiatsu
	self._reiatsu = math.clamp(oldReiatsu + amount, 0, self._maxReiatsu)
	self._reiatsuChangedEvent:Fire(self._reiatsu, oldReiatsu)

	return self._reiatsu
end

-- La rotura de postura (aturdimiento y su duración) la resuelve CombatService.
function Character.ApplyPostureDamage(self: Character, amount: number): number
	if self._destroyed or amount <= 0 then
		return self._posture
	end

	local oldPosture = self._posture
	self._posture = math.clamp(oldPosture + amount, 0, self._maxPosture)
	self._postureChangedEvent:Fire(self._posture, oldPosture)

	return self._posture
end

function Character.RecoverPosture(self: Character, amount: number): number
	if self._destroyed or amount <= 0 or self._posture <= 0 then
		return self._posture
	end

	local oldPosture = self._posture
	self._posture = math.clamp(oldPosture - amount, 0, self._maxPosture)
	self._postureChangedEvent:Fire(self._posture, oldPosture)

	return self._posture
end

function Character.ResetPosture(self: Character): ()
	if self._destroyed or self._posture == 0 then
		return
	end

	local oldPosture = self._posture
	self._posture = 0
	self._postureChangedEvent:Fire(self._posture, oldPosture)
end

function Character.GetState(self: Character): CharacterStateName
	return self._stateMachine:GetState()
end

function Character.CanTransitionTo(self: Character, newState: CharacterStateName): boolean
	return self._stateMachine:CanTransition(newState)
end

function Character.TransitionTo(self: Character, newState: CharacterStateName): (boolean, string?)
	return self._stateMachine:TransitionTo(newState)
end

function Character.OnStateChanged(self: Character, callback: StateMachine.StateChangedCallback): RBXScriptConnection
	return self._stateMachine:OnStateChanged(callback)
end

-- Tras Destroy, los métodos siguen siendo seguros de llamar: no mutan estado
-- ni emiten señales.
function Character.Destroy(self: Character): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._stateMachine:Destroy()
	self._healthChangedEvent:Destroy()
	self._reiatsuChangedEvent:Destroy()
	self._postureChangedEvent:Destroy()
	self._diedEvent:Destroy()
end

return Character
