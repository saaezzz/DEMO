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
	-- La regeneración se multiplica por la densidad ambiental de la zona en la
	-- que está el personaje (Server/Content/AmbientZones, D-041).
	AmbientScaling: boolean?,
}

-- Estadísticas que se cuentan en el perfil (D-039), p. ej. enemigos
-- derrotados con cierto golpe. Solo el nombre visible; el Id es su clave.
export type StatDefinition = {
	DisplayName: string,
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

-- Hito de progresión de una raza (D-039): al cumplir sus requisitos se
-- alcanza para siempre y desbloquea técnicas. No basta con matar: se pide
-- nivel y además estadísticas concretas (constitución §29).
export type RaceMilestone = {
	Id: string,
	DisplayName: string,
	Description: string,
	RequiredLevel: number,
	-- Estadística (Content/Stats) → mínimo necesario.
	RequiredStats: { [string]: number },
	-- Técnicas que se añaden a la barra, detrás de las del moveset.
	UnlockSkills: { string },
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
	-- Hitos en orden de progresión (vacío = sin hitos todavía).
	Milestones: { RaceMilestone },
}

-- Armas (D-034) ----------------------------------------------------------------

export type WeaponDefinition = {
	Id: string,
	DisplayName: string,
	-- Modelo del manifiesto (MDL_...). Si no está colocado en Studio, se usa Placeholder.
	Model: string,
	-- Parte del cuerpo a la que se suelda (por defecto "RightHand"). Sirve
	-- también para piezas que no son armas, como una máscara ("Head").
	AttachTo: string?,
	-- Posición del mango respecto a esa parte del cuerpo.
	Grip: CFrame,
	-- Pieza provisional: tamaño (el eje largo es Z), color hexadecimal, si
	-- brilla (Neon) y si lleva guarda de espada.
	Placeholder: { Size: Vector3, Color: string, Glow: boolean?, Guard: boolean? },
}

-- Efectos visuales (D-035) -----------------------------------------------------

-- Forma del efecto provisional mientras no haya uno de Arte en Studio.
export type EffectKind =
	"Beam" -- rayo recto hacia delante (Length × Width)
	| "Burst" -- esfera que crece y se desvanece (Radius)
	| "Ring" -- círculo en el suelo (Radius), p. ej. aviso de área
	| "Aura" -- contorno de color sobre el personaje durante Duration (potenciadores)

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
