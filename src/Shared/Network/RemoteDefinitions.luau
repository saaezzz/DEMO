--!strict

-- Catálogo de remotes del juego (D-016). El servidor los crea al arrancar en
-- ReplicatedStorage.Remotes; no se declaran en default.project.json.
--
-- Para añadir un remote: añade su nombre a RemoteName y su definición aquí,
-- y regístralo en el servidor con ServerNetwork:HandleFunction/HandleEvent
-- junto con un validador de Schema.

export type RemoteName = "CombatIntent"

export type RemoteKind = "Function" | "Event"

export type RemoteDefinition = {
	Kind: RemoteKind,
	-- Rate limit por jugador (token bucket): ráfaga máxima y ritmo sostenido.
	Burst: number,
	PerSecond: number,
}

local RemoteDefinitions: { [RemoteName]: RemoteDefinition } = {
	CombatIntent = { Kind = "Function", Burst = 10, PerSecond = 8 },
}

return RemoteDefinitions
