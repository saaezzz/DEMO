--!strict

local GameTypes = require(script.Parent.Parent.Types.GameTypes)

type CharacterStateName = GameTypes.CharacterStateName
type StateTransitionTable = GameTypes.StateTransitionTable

export type StateChangedCallback = (oldState: CharacterStateName, newState: CharacterStateName) -> ()

export type StateMachine = {
	CurrentState: CharacterStateName,
	StateChanged: RBXScriptSignal,

	GetState: (self: StateMachine) -> CharacterStateName,
	CanTransition: (self: StateMachine, newState: CharacterStateName) -> boolean,
	TransitionTo: (self: StateMachine, newState: CharacterStateName) -> (boolean, string?),
	OnStateChanged: (self: StateMachine, callback: StateChangedCallback) -> RBXScriptConnection,
	Destroy: (self: StateMachine) -> (),
}

type StateMachineInternal = StateMachine & {
	_transitionTable: StateTransitionTable,
	_changedEvent: BindableEvent,
	_connections: { RBXScriptConnection },
	_destroyed: boolean,
}

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(initialState: CharacterStateName, transitionTable: StateTransitionTable): StateMachine
	local changedEvent = Instance.new("BindableEvent")

	local self = setmetatable({
		CurrentState = initialState,
		StateChanged = changedEvent.Event,
		_transitionTable = transitionTable,
		_changedEvent = changedEvent,
		_connections = {},
		_destroyed = false,
	}, StateMachine) :: StateMachineInternal

	return (self :: any) :: StateMachine
end

function StateMachine:GetState(): CharacterStateName
	local self = (self :: any) :: StateMachineInternal
	return self.CurrentState
end

function StateMachine:CanTransition(newState: CharacterStateName): boolean
	local self = (self :: any) :: StateMachineInternal

	if self._destroyed then
		return false
	end

	local allowedStates = self._transitionTable[self.CurrentState]
	if allowedStates == nil then
		return false
	end

	for _, allowedState in ipairs(allowedStates) do
		if allowedState == newState then
			return true
		end
	end

	return false
end

function StateMachine:TransitionTo(newState: CharacterStateName): (boolean, string?)
	local self = (self :: any) :: StateMachineInternal

	if self._destroyed then
		return false, "StateMachine destruida"
	end

	if self.CurrentState == newState then
		return false, "Ya se encuentra en el estado solicitado"
	end

	if not self:CanTransition(newState) then
		return false, string.format("Transición bloqueada: %s -> %s", self.CurrentState, newState)
	end

	local oldState = self.CurrentState
	self.CurrentState = newState
	self._changedEvent:Fire(oldState, newState)

	return true, nil
end

function StateMachine:OnStateChanged(callback: StateChangedCallback): RBXScriptConnection
	local self = (self :: any) :: StateMachineInternal

	local connection = self.StateChanged:Connect(callback)
	table.insert(self._connections, connection)

	return connection
end

function StateMachine:Destroy(): ()
	local self = (self :: any) :: StateMachineInternal

	if self._destroyed then
		return
	end

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self._changedEvent:Destroy()
	self._transitionTable = {} :: any

	self._destroyed = true
	setmetatable(self :: any, nil)
end

return StateMachine
