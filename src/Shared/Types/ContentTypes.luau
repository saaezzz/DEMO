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
	-- Segundos sin gastarlo antes de empezar a regenerarse (0 o nil = sin espera).
	RegenDelaySeconds: number?,
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
	-- Qué lo usa (p. ej. "Ability:Slash1"), para saber qué se rompe si cambia.
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

export type StartingItem = {
	Item: string,
	Quantity: number,
}

-- Lo que recibe un personaje de la raza (D-034).
export type RaceKit = {
	-- Moveset de Content/Movesets.
	Moveset: string,
	-- Arma de Content/Weapons que lleva en la mano (nil = sin arma).
	Weapon: string?,
	-- Objetos que recibe al elegir la raza.
	StartingItems: { StartingItem },
}

export type RaceDefinition = {
	Id: RaceId,
	DisplayName: string,
	-- Texto de la pantalla de elección de raza.
	Description: string,
	-- false para razas que existen en los datos pero aún no se pueden elegir
	-- ("Próximamente" en la pantalla de elección).
	Playable: boolean,
	-- Recursos con los que empieza un personaje de esta raza.
	Resources: { ResourceId },
	Kit: RaceKit,
}

-- Armas (D-034) ----------------------------------------------------------------

export type WeaponDefinition = {
	Id: string,
	DisplayName: string,
	-- Modelo del manifiesto (MDL_...). Si no está colocado en Studio, se usa Placeholder.
	Model: string,
	-- Posición del mango respecto a la mano derecha (RightHand).
	Grip: CFrame,
	-- Hoja provisional: tamaño (el eje largo es Z) y color hexadecimal.
	Placeholder: { Size: Vector3, Color: string },
}

-- Efectos visuales (D-035) -----------------------------------------------------

-- Forma del efecto provisional mientras no haya uno de Arte en Studio.
export type EffectKind =
	"Beam" -- rayo recto hacia delante (Length × Width)
	| "Burst" -- esfera que crece y se desvanece (Radius)
	| "Ring" -- círculo en el suelo (Radius), p. ej. aviso de área

export type EffectDefinition = {
	Kind: EffectKind,
	-- Efecto de Arte (VFX_...). Si está colocado en Studio, se usa en lugar del provisional.
	Asset: string?,
	Color: string,
	Duration: number,
	Length: number?,
	Width: number?,
	Radius: number?,
	-- Desplazamiento respecto al personaje (hacia delante es -Z).
	Offset: CFrame?,
}

-- Presentación de una habilidad para el cliente (nombre y efectos).
export type AbilityEffect = {
	Effect: string,
	-- Segundos desde el inicio de la habilidad.
	Delay: number,
}

export type AbilityInfo = {
	DisplayName: string,
	Description: string,
	Effects: { AbilityEffect }?,
}

return {}
