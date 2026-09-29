--!strict

local StateMachine = require(script.Parent.StateMachine)
local GameTypes = require(script.Parent.Parent.Types.GameTypes)

type CharacterAttributes = GameTypes.CharacterAttributes
type CharacterRace = GameTypes.CharacterRace
type CharacterStateName = GameTypes.CharacterStateName
type StateTransitionTable = GameTypes.StateTransitionTable
type StateMachine = StateMachine.StateMachine

-- Tabla de transiciones permitidas para cualquier personaje del juego.
-- Ragdoll es un estado terminal por golpe: solo puede volver a Idle.
local DEFAULT_STATE_TRANSITIONS: StateTransitionTable = {
	Idle = { "Attacking", "Blocking", "Shunpo", "Casting", "Stunned", "Ragdoll" },
	Attacking = { "Idle", "Stunned", "Ragdoll" },
	Blocking = { "Idle", "Stunned", "Ragdoll" },
	Shunpo = { "Idle", "Stunned", "Ragdoll" },
	Casting = { "Idle", "Stunned", "Ragdoll" },
	Stunned = { "Idle", "Ragdoll" },
	Ragdoll = { "Idle" },
}

export type NumericStatChangedCallback = (newValue: number, oldValue: number) -> ()
export type DiedCallback = () -> ()

export type Character = {
	UserId: number,
	Race: CharacterRace,
	Level: number,

	HealthChanged: RBXScriptSignal,
	ReiatsuChanged: RBXScriptSignal,
	PostureChanged: RBXScriptSignal,
	Died: RBXScriptSignal,

	GetHealth: (self: Character) -> number,
	GetMaxHealth: (self: Character) -> number,
	GetReiatsu: (self: Character) -> number,
	GetMaxReiatsu: (self: Character) -> number,
	GetPosture: (self: Character) -> number,
	GetMaxPosture: (self: Character) -> number,
	IsAlive: (self: Character) -> boolean,

	TakeDamage: (self: Character, amount: number) -> number,
	Heal: (self: Character, amount: number) -> number,
	SpendReiatsu: (self: Character, amount: number) -> boolean,
	RestoreReiatsu: (self: Character, amount: number) -> number,
	ApplyPostureDamage: (self: Character, amount: number) -> number,
	ResetPosture: (self: Character) -> (),

	GetState: (self: Character) -> CharacterStateName,
	CanTransitionTo: (self: Character, newState: CharacterStateName) -> boolean,
	TransitionTo: (self: Character, newState: CharacterStateName) -> (boolean, string?),
	OnStateChanged: (self: Character, callback: StateMachine.StateChangedCallback) -> RBXScriptConnection,

	Destroy: (self: Character) -> (),
}

type CharacterInternal = Character & {
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
	_connections: { RBXScriptConnection },
	_destroyed: boolean,
}

local Character = {}
Character.__index = Character

local function clamp(value: number, min: number, max: number): number
	if value < min then
		return min
	elseif value > max then
		return max
	end
	return value
end

function Character.new(userId: number, attributes: CharacterAttributes): Character
	local healthChangedEvent = Instance.new("BindableEvent")
	local reiatsuChangedEvent = Instance.new("BindableEvent")
	local postureChangedEvent = Instance.new("BindableEvent")
	local diedEvent = Instance.new("BindableEvent")

	local self = setmetatable({
		UserId = userId,
		Race = attributes.Race,
		Level = attributes.Level,

		HealthChanged = healthChangedEvent.Event,
		ReiatsuChanged = reiatsuChangedEvent.Event,
		PostureChanged = postureChangedEvent.Event,
		Died = diedEvent.Event,

		_health = clamp(attributes.Health, 0, attributes.MaxHealth),
		_maxHealth = attributes.MaxHealth,
		_reiatsu = clamp(attributes.Reiatsu, 0, attributes.MaxReiatsu),
		_maxReiatsu = attributes.MaxReiatsu,
		_posture = clamp(attributes.Posture, 0, attributes.MaxPosture),
		_maxPosture = attributes.MaxPosture,
		_isAlive = attributes.Health > 0,

		_stateMachine = StateMachine.new("Idle", DEFAULT_STATE_TRANSITIONS),

		_healthChangedEvent = healthChangedEvent,
		_reiatsuChangedEvent = reiatsuChangedEvent,
		_postureChangedEvent = postureChangedEvent,
		_diedEvent = diedEvent,
		_connections = {},
		_destroyed = false,
	}, Character) :: CharacterInternal

	return (self :: any) :: Character
end

function Character:GetHealth(): number
	return ((self :: any) :: CharacterInternal)._health
end

function Character:GetMaxHealth(): number
	return ((self :: any) :: CharacterInternal)._maxHealth
end

function Character:GetReiatsu(): number
	return ((self :: any) :: CharacterInternal)._reiatsu
end

function Character:GetMaxReiatsu(): number
	return ((self :: any) :: CharacterInternal)._maxReiatsu
end

function Character:GetPosture(): number
	return ((self :: any) :: CharacterInternal)._posture
end

function Character:GetMaxPosture(): number
	return ((self :: any) :: CharacterInternal)._maxPosture
end

function Character:IsAlive(): boolean
	return ((self :: any) :: CharacterInternal)._isAlive
end

function Character:TakeDamage(amount: number): number
	local self = (self :: any) :: CharacterInternal

	if self._destroyed or not self._isAlive or amount <= 0 then
		return self._health
	end

	local oldHealth = self._health
	self._health = clamp(oldHealth - amount, 0, self._maxHealth)
	self._healthChangedEvent:Fire(self._health, oldHealth)

	if self._health <= 0 and self._isAlive then
		self._isAlive = false
		self._diedEvent:Fire()
	end

	return self._health
end

function Character:Heal(amount: number): number
	local self = (self :: any) :: CharacterInternal

	if self._destroyed or not self._isAlive or amount <= 0 then
		return self._health
	end

	local oldHealth = self._health
	self._health = clamp(oldHealth + amount, 0, self._maxHealth)
	self._healthChangedEvent:Fire(self._health, oldHealth)

	return self._health
end

function Character:SpendReiatsu(amount: number): boolean
	local self = (self :: any) :: CharacterInternal

	if self._destroyed or amount <= 0 or self._reiatsu < amount then
		return false
	end

	local oldReiatsu = self._reiatsu
	self._reiatsu = clamp(oldReiatsu - amount, 0, self._maxReiatsu)
	self._reiatsuChangedEvent:Fire(self._reiatsu, oldReiatsu)

	return true
end

function Character:RestoreReiatsu(amount: number): number
	local self = (self :: any) :: CharacterInternal

	if self._destroyed or amount <= 0 then
		return self._reiatsu
	end

	local oldReiatsu = self._reiatsu
	self._reiatsu = clamp(oldReiatsu + amount, 0, self._maxReiatsu)
	self._reiatsuChangedEvent:Fire(self._reiatsu, oldReiatsu)

	return self._reiatsu
end

function Character:ApplyPostureDamage(amount: number): number
	local self = (self :: any) :: CharacterInternal

	if self._destroyed or amount <= 0 then
		return self._posture
	end

	local oldPosture = self._posture
	self._posture = clamp(oldPosture + amount, 0, self._maxPosture)
	self._postureChangedEvent:Fire(self._posture, oldPosture)

	if self._posture >= self._maxPosture then
		self._stateMachine:TransitionTo("Stunned")
	end

	return self._posture
end

function Character:ResetPosture(): ()
	local self = (self :: any) :: CharacterInternal

	if self._destroyed or self._posture == 0 then
		return
	end

	local oldPosture = self._posture
	self._posture = 0
	self._postureChangedEvent:Fire(self._posture, oldPosture)
end

function Character:GetState(): CharacterStateName
	local self = (self :: any) :: CharacterInternal
	return self._stateMachine:GetState()
end

function Character:CanTransitionTo(newState: CharacterStateName): boolean
	local self = (self :: any) :: CharacterInternal
	return self._stateMachine:CanTransition(newState)
end

function Character:TransitionTo(newState: CharacterStateName): (boolean, string?)
	local self = (self :: any) :: CharacterInternal
	return self._stateMachine:TransitionTo(newState)
end

function Character:OnStateChanged(callback: StateMachine.StateChangedCallback): RBXScriptConnection
	local self = (self :: any) :: CharacterInternal
	return self._stateMachine:OnStateChanged(callback)
end

function Character:Destroy(): ()
	local self = (self :: any) :: CharacterInternal

	if self._destroyed then
		return
	end

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self._stateMachine:Destroy()

	self._healthChangedEvent:Destroy()
	self._reiatsuChangedEvent:Destroy()
	self._postureChangedEvent:Destroy()
	self._diedEvent:Destroy()

	self._destroyed = true
	setmetatable(self :: any, nil)
end

return Character
