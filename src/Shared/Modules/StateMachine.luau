--!strict

local Shared = game:GetService("ReplicatedStorage").Shared
local GameTypes = require(Shared.Types.GameTypes)
local Signal = require(Shared.Utils.Signal)

type CharacterStateName = GameTypes.CharacterStateName
type StateTransitionTable = GameTypes.StateTransitionTable
type Connection = Signal.Connection

export type StateChangedCallback = (oldState: CharacterStateName, newState: CharacterStateName) -> ()

local StateMachine = {}
StateMachine.__index = StateMachine

type StateMachineData = {
	_state: CharacterStateName,
	_transitionTable: StateTransitionTable,
	_changed: Signal.Signal<CharacterStateName, CharacterStateName>,
	_destroyed: boolean,
}

export type StateMachine = typeof(setmetatable({} :: StateMachineData, StateMachine))

function StateMachine.new(initialState: CharacterStateName, transitionTable: StateTransitionTable): StateMachine
	return setmetatable({
		_state = initialState,
		_transitionTable = transitionTable,
		_changed = Signal.new(),
		_destroyed = false,
	}, StateMachine)
end

function StateMachine.GetState(self: StateMachine): CharacterStateName
	return self._state
end

function StateMachine.CanTransition(self: StateMachine, newState: CharacterStateName): boolean
	if self._destroyed then
		return false
	end

	local allowedStates = self._transitionTable[self._state]
	if allowedStates == nil then
		return false
	end

	return table.find(allowedStates, newState) ~= nil
end

function StateMachine.TransitionTo(self: StateMachine, newState: CharacterStateName): (boolean, string?)
	if self._destroyed then
		return false, "StateMachine destruida"
	end

	if self._state == newState then
		return false, "Ya se encuentra en el estado solicitado"
	end

	if not self:CanTransition(newState) then
		return false, string.format("Transición bloqueada: %s -> %s", self._state, newState)
	end

	local oldState: CharacterStateName = self._state
	self._state = newState
	self._changed:Fire(oldState, newState)

	return true, nil
end

-- Los callbacks se ejecutan de forma síncrona dentro de TransitionTo.
function StateMachine.OnStateChanged(self: StateMachine, callback: StateChangedCallback): Connection
	return self._changed:Connect(callback)
end

-- Desconecta todas las conexiones de OnStateChanged.
function StateMachine.Destroy(self: StateMachine): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._changed:DisconnectAll()
end

return StateMachine
