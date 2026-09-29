--!strict

local GameTypes = require(script.Parent.Parent.Types.GameTypes)

type CharacterStateName = GameTypes.CharacterStateName
type StateTransitionTable = GameTypes.StateTransitionTable

export type StateChangedCallback = (oldState: CharacterStateName, newState: CharacterStateName) -> ()

local StateMachine = {}
StateMachine.__index = StateMachine

type StateMachineData = {
	_state: CharacterStateName,
	_transitionTable: StateTransitionTable,
	_changedEvent: BindableEvent,
	_destroyed: boolean,
}

export type StateMachine = typeof(setmetatable({} :: StateMachineData, StateMachine))

function StateMachine.new(initialState: CharacterStateName, transitionTable: StateTransitionTable): StateMachine
	return setmetatable({
		_state = initialState,
		_transitionTable = transitionTable,
		_changedEvent = Instance.new("BindableEvent"),
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

	local oldState = self._state
	self._state = newState
	self._changedEvent:Fire(oldState, newState)

	return true, nil
end

function StateMachine.OnStateChanged(self: StateMachine, callback: StateChangedCallback): RBXScriptConnection
	return self._changedEvent.Event:Connect(callback)
end

-- Destruir el BindableEvent desconecta todas las conexiones de OnStateChanged.
function StateMachine.Destroy(self: StateMachine): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._changedEvent:Destroy()
end

return StateMachine
