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
	-- Color de su barra en la UI, en hexadecimal ("#RRGGBB").
	Color: string,
}

-- Manifiesto de assets (§54, D-020) ------------------------------------------

export type AssetCategory = "Animation" | "Model" | "VFX" | "SFX" | "Music" | "UI" | "Texture"

export type AssetStatus = "TODO" | "BLOCKED" | "IN_PROGRESS" | "REVIEW" | "APPROVED" | "INTEGRATED"

export type AssetEntry = {
	-- Nombre único según la convención <PREFIJO>_<Grupo>_<Nombre> (docs/ASSETS.md).
	Name: string,
	Category: AssetCategory,
	-- ID numérico de Roblox; nil hasta que el asset se sube.
	AssetId: number?,
	Owner: string,
	Status: AssetStatus,
	Version: number,
	-- Nombres de otros assets del manifiesto que necesita.
	Dependencies: { string },
	-- Qué lo usa (p. ej. "Combo:BasicSlash"), para saber qué se rompe si cambia.
	UsedBy: { string },
	Notes: string?,
}

-- Animaciones (§53, D-020) ---------------------------------------------------

-- Markers estándar de las animaciones. Un marker puede llevar un sufijo
-- numérico si se repite en la misma animación (Hit1, Hit2...).
export type AnimationMarker = "Startup" | "Hit" | "Active" | "Recovery" | "VFX" | "SFX" | "IFrameStart" | "IFrameEnd"

export type AnimationDefinition = {
	-- Nombre del asset en el manifiesto (categoría Animation).
	Asset: string,
	Priority: "Core" | "Idle" | "Movement" | "Action",
	Looped: boolean,
	-- Markers que la animación debe tener (con sufijo si aplica).
	Markers: { string },
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
