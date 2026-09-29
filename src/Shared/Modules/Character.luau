--!strict

local Shared = game:GetService("ReplicatedStorage").Shared
local StateMachine = require(Shared.Modules.StateMachine)
local GameTypes = require(Shared.Types.GameTypes)
local ContentTypes = require(Shared.Types.ContentTypes)
local Signal = require(Shared.Utils.Signal)

type CharacterAttributes = GameTypes.CharacterAttributes
type CharacterStateName = GameTypes.CharacterStateName
type ResourcePool = GameTypes.ResourcePool
type StateTransitionTable = GameTypes.StateTransitionTable
type RaceId = ContentTypes.RaceId
type ResourceId = ContentTypes.ResourceId
type StateMachine = StateMachine.StateMachine
type Signal<T...> = Signal.Signal<T...>

-- Estados a los que se puede pasar desde cualquier estado vivo (efectos que
-- sufre el personaje, no acciones que elige).
local INTERRUPT_STATES: { CharacterStateName } = { "Stunned", "Knocked", "Ragdolled", "Disabled", "Dead" }

-- Transiciones voluntarias (o de fin de acción) de cada estado.
local VOLUNTARY_TRANSITIONS: StateTransitionTable = {
	Idle = { "Attacking", "Blocking", "Parrying", "Dodging", "Dashing", "Casting", "Transforming" },
	Attacking = { "Idle" },
	Blocking = { "Idle", "Parrying" },
	Parrying = { "Idle", "Blocking" },
	Dodging = { "Idle" },
	Dashing = { "Idle" },
	Casting = { "Idle" },
	Transforming = { "Idle" },
	Stunned = { "Idle" },
	Knocked = { "Idle", "Ragdolled" },
	Ragdolled = { "Idle" },
	Disabled = { "Idle" },
	Dead = {},
}

-- Tabla final: voluntarias + interrupciones, salvo desde Dead (terminal).
local function buildTransitionTable(): StateTransitionTable
	local transitions: StateTransitionTable = {}
	for state: CharacterStateName, voluntary in VOLUNTARY_TRANSITIONS do
		local allowed = table.clone(voluntary)
		if state ~= "Dead" then
			for _, interrupt in INTERRUPT_STATES do
				if interrupt ~= state and not table.find(allowed, interrupt) then
					table.insert(allowed, interrupt)
				end
			end
		end
		transitions[state] = allowed
	end
	return transitions
end

local STATE_TRANSITIONS = buildTransitionTable()

local Character = {}
Character.__index = Character

type CharacterData = {
	Race: RaceId,
	Level: number,

	-- Señales síncronas (D-013).
	HealthChanged: Signal<number, number>, -- (nuevo, anterior)
	PostureChanged: Signal<number, number>, -- (nuevo, anterior)
	ResourceChanged: Signal<ResourceId, number, number>, -- (recurso, nuevo, anterior)
	Died: Signal<>,

	_health: number,
	_maxHealth: number,
	_posture: number,
	_maxPosture: number,
	_resources: { [ResourceId]: ResourcePool },
	_isAlive: boolean,
	_stateMachine: StateMachine,
	_destroyed: boolean,
}

export type Character = typeof(setmetatable({} :: CharacterData, Character))

function Character.new(attributes: CharacterAttributes): Character
	local resources: { [ResourceId]: ResourcePool } = {}
	for resourceId, pool in attributes.Resources do
		resources[resourceId] = {
			Current = math.clamp(pool.Current, 0, pool.Max),
			Max = pool.Max,
		}
	end

	return setmetatable({
		Race = attributes.Race,
		Level = attributes.Level,

		HealthChanged = Signal.new(),
		PostureChanged = Signal.new(),
		ResourceChanged = Signal.new(),
		Died = Signal.new(),

		_health = attributes.MaxHealth,
		_maxHealth = attributes.MaxHealth,
		_posture = 0,
		_maxPosture = attributes.MaxPosture,
		_resources = resources,
		_isAlive = attributes.MaxHealth > 0,
		_stateMachine = StateMachine.new("Idle", STATE_TRANSITIONS),
		_destroyed = false,
	}, Character)
end

-- Vida ------------------------------------------------------------------------

function Character.GetHealth(self: Character): number
	return self._health
end

function Character.GetMaxHealth(self: Character): number
	return self._maxHealth
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
	self.HealthChanged:Fire(self._health, oldHealth)

	if self._health <= 0 then
		self._isAlive = false
		self._stateMachine:TransitionTo("Dead")
		self.Died:Fire()
	end

	return self._health
end

function Character.Heal(self: Character, amount: number): number
	if self._destroyed or not self._isAlive or amount <= 0 then
		return self._health
	end

	local oldHealth = self._health
	self._health = math.clamp(oldHealth + amount, 0, self._maxHealth)
	self.HealthChanged:Fire(self._health, oldHealth)

	return self._health
end

-- Recursos (genéricos, definidos en Content/Resources) --------------------------

function Character.HasResource(self: Character, resourceId: ResourceId): boolean
	return self._resources[resourceId] ~= nil
end

-- 0 si el personaje no tiene ese recurso.
function Character.GetResource(self: Character, resourceId: ResourceId): number
	local pool: ResourcePool? = self._resources[resourceId]
	return if pool ~= nil then pool.Current else 0
end

function Character.GetMaxResource(self: Character, resourceId: ResourceId): number
	local pool: ResourcePool? = self._resources[resourceId]
	return if pool ~= nil then pool.Max else 0
end

function Character.GetResourceIds(self: Character): { ResourceId }
	local ids = {}
	for resourceId in self._resources do
		table.insert(ids, resourceId)
	end
	return ids
end

-- Gasta la cantidad completa o nada. Falla si el personaje no tiene el recurso.
function Character.SpendResource(self: Character, resourceId: ResourceId, amount: number): boolean
	local pool: ResourcePool? = self._resources[resourceId]
	if self._destroyed or pool == nil or amount <= 0 or pool.Current < amount then
		return false
	end

	local oldValue = pool.Current
	pool.Current = math.clamp(oldValue - amount, 0, pool.Max)
	self.ResourceChanged:Fire(resourceId, pool.Current, oldValue)

	return true
end

function Character.RestoreResource(self: Character, resourceId: ResourceId, amount: number): number
	local pool: ResourcePool? = self._resources[resourceId]
	if pool == nil then
		return 0
	end
	if self._destroyed or amount <= 0 or pool.Current >= pool.Max then
		return pool.Current
	end

	local oldValue = pool.Current
	pool.Current = math.clamp(oldValue + amount, 0, pool.Max)
	self.ResourceChanged:Fire(resourceId, pool.Current, oldValue)

	return pool.Current
end

-- Postura (medidor de combate) -------------------------------------------------

function Character.GetPosture(self: Character): number
	return self._posture
end

function Character.GetMaxPosture(self: Character): number
	return self._maxPosture
end

-- La rotura de postura (aturdimiento y su duración) la resuelve CombatService.
function Character.ApplyPostureDamage(self: Character, amount: number): number
	if self._destroyed or amount <= 0 then
		return self._posture
	end

	local oldPosture = self._posture
	self._posture = math.clamp(oldPosture + amount, 0, self._maxPosture)
	self.PostureChanged:Fire(self._posture, oldPosture)

	return self._posture
end

function Character.RecoverPosture(self: Character, amount: number): number
	if self._destroyed or amount <= 0 or self._posture <= 0 then
		return self._posture
	end

	local oldPosture = self._posture
	self._posture = math.clamp(oldPosture - amount, 0, self._maxPosture)
	self.PostureChanged:Fire(self._posture, oldPosture)

	return self._posture
end

function Character.ResetPosture(self: Character): ()
	if self._destroyed or self._posture == 0 then
		return
	end

	local oldPosture = self._posture
	self._posture = 0
	self.PostureChanged:Fire(self._posture, oldPosture)
end

-- Estado -----------------------------------------------------------------------

function Character.GetState(self: Character): CharacterStateName
	return self._stateMachine:GetState()
end

function Character.CanTransitionTo(self: Character, newState: CharacterStateName): boolean
	return self._stateMachine:CanTransition(newState)
end

function Character.TransitionTo(self: Character, newState: CharacterStateName): (boolean, string?)
	return self._stateMachine:TransitionTo(newState)
end

function Character.OnStateChanged(self: Character, callback: StateMachine.StateChangedCallback): Signal.Connection
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
	self.HealthChanged:DisconnectAll()
	self.PostureChanged:DisconnectAll()
	self.ResourceChanged:DisconnectAll()
	self.Died:DisconnectAll()
end

return Character
