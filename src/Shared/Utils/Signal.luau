--!strict

-- Señal en Luau puro (sin Instance), testeable fuera de Studio.
--
-- Semántica (D-013):
-- - Fire es síncrono: los handlers se ejecutan en orden de conexión antes de
--   que Fire retorne. Los handlers no deben ceder (yield).
-- - Un error en un handler se propaga a quien llamó a Fire.
-- - Conectar durante un Fire no afecta a esa emisión; un handler desconectado
--   antes de su turno ya no se llama.

-- Tipos públicos declarados como interfaz: el solver de tipos no maneja bien
-- clases genéricas definidas con typeof(setmetatable(...)).
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

type Handler = (...any) -> ()

type ConnectionImpl = {
	Connected: boolean,
	_handler: Handler,
	_connections: { ConnectionImpl },
}

type SignalImpl = {
	_connections: { ConnectionImpl },
}

local ConnectionMethods = {}
ConnectionMethods.__index = ConnectionMethods

function ConnectionMethods.Disconnect(self: ConnectionImpl): ()
	if not self.Connected then
		return
	end
	self.Connected = false

	local index = table.find(self._connections, self)
	if index ~= nil then
		table.remove(self._connections, index)
	end
end

local SignalMethods = {}
SignalMethods.__index = SignalMethods

function SignalMethods.Connect(self: SignalImpl, handler: Handler): ConnectionImpl
	local connection: ConnectionImpl = setmetatable({
		Connected = true,
		_handler = handler,
		_connections = self._connections,
	}, ConnectionMethods) :: any
	table.insert(self._connections, connection)
	return connection
end

function SignalMethods.Once(self: SignalImpl, handler: Handler): ConnectionImpl
	local connection: ConnectionImpl
	connection = SignalMethods.Connect(self, function(...)
		ConnectionMethods.Disconnect(connection)
		handler(...)
	end)
	return connection
end

function SignalMethods.Fire(self: SignalImpl, ...: any): ()
	for _, connection in table.clone(self._connections) do
		if connection.Connected then
			connection._handler(...)
		end
	end
end

function SignalMethods.DisconnectAll(self: SignalImpl): ()
	for _, connection in self._connections do
		connection.Connected = false
	end
	table.clear(self._connections)
end

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local signal: SignalImpl = { _connections = {} }
	return setmetatable(signal, SignalMethods) :: any
end

return Signal
