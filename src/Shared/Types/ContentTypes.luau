--!strict

-- Tipos de las definiciones de contenido (D-017). El núcleo del juego solo
-- conoce estos tipos e identificadores opacos; los datos concretos (nombres de
-- razas, recursos, habilidades...) viven en las carpetas Content y pueden
-- sustituirse sin tocar los servicios (constitución §4).

export type RaceId = string
export type ResourceId = string

export type ResourceDefinition = {
	Id: ResourceId,
	DisplayName: string,
	DefaultMax: number,
	-- Regeneración pasiva por segundo mientras el personaje está vivo.
	RegenPerSecond: number,
}

export type RaceDefinition = {
	Id: RaceId,
	DisplayName: string,
	-- false para razas que existen en los datos pero aún no se pueden elegir.
	Playable: boolean,
	-- Recursos con los que empieza un personaje de esta raza.
	Resources: { ResourceId },
}

return {}
