--!strict

-- Catálogo de remotes del juego (D-016). El servidor los crea al arrancar en
-- ReplicatedStorage.Remotes; no se declaran en default.project.json.
--
-- Para añadir un remote: añade su nombre a RemoteName y su definición aquí.
-- Los remotes que inicia el cliente (Function, ToServerEvent) necesitan
-- RateLimit y un handler registrado en el servidor con un validador de Schema.

export type RemoteName = "CombatIntent" | "PlayerData"

export type RemoteKind =
	"Function" -- petición del cliente con respuesta del servidor
	| "ToServerEvent" -- evento del cliente al servidor
	| "ToClientEvent" -- evento del servidor al cliente

export type RateLimit = {
	-- Token bucket por jugador: ráfaga máxima y ritmo sostenido.
	Burst: number,
	PerSecond: number,
}

export type RemoteDefinition = {
	Kind: RemoteKind,
	RateLimit: RateLimit?,
}

local RemoteDefinitions: { [RemoteName]: RemoteDefinition } = {
	CombatIntent = { Kind = "Function", RateLimit = { Burst = 10, PerSecond = 8 } },
	-- Replicación de los datos del propio jugador (D-005).
	PlayerData = { Kind = "ToClientEvent" },
}

return RemoteDefinitions
