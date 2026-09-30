--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type RaceId = ContentTypes.RaceId
type ResourceId = ContentTypes.ResourceId

-- Estados de un personaje (§15, D-017 revisado en D-024). Tres capas
-- centralizadas en Character:
-- - Acción (CharacterStateName): exclusivos entre sí, máquina de estados.
-- - Locomoción (LocomotionState): cómo se desplaza, a la vez que cualquier acción.
-- - Forma: transformado o no ("Transformed").
export type CharacterStateName =
	"Idle"
	| "Attacking"
	| "Blocking"
	| "Parrying"
	| "Dodging"
	| "Dashing"
	| "Casting"
	| "Transforming"
	| "Stunned"
	| "Knocked"
	| "Ragdolled"
	| "Disabled"
	| "Dead"

-- "Stationary" = sin desplazarse (el "Idle" de §15 es el estado de acción).
export type LocomotionState = "Stationary" | "Moving" | "Running" | "Sprinting"

-- Cualquier estado de §15, de cualquier capa (para Character:IsInState).
export type StateQuery = CharacterStateName | LocomotionState | "Transformed"

-- Estados desde los que puede empezar una habilidad (§15). Solo StartStates
-- es obligatorio; el resto restringe además por locomoción o forma.
export type StateRequirements = {
	StartStates: { CharacterStateName },
	Locomotion: { LocomotionState }?,
	-- true: solo transformado; false: solo sin transformar; nil: da igual.
	Transformed: boolean?,
}

export type ResourcePool = {
	Current: number,
	Max: number,
}

-- Atributos con los que se crea un Character. La vida empieza al máximo y la
-- postura a 0.
export type CharacterAttributes = {
	Race: RaceId,
	Level: number,
	MaxHealth: number,
	MaxPosture: number,
	Resources: { [ResourceId]: ResourcePool },
}

export type ResourceCost = {
	Resource: ResourceId,
	Amount: number,
}

export type HitboxShape = "Box" | "Sphere" | "Cylinder"

export type HitboxDefinition = {
	Shape: HitboxShape,
	Size: Vector3,
	Offset: CFrame,
	-- 0 = sin límite de objetivos.
	MaxTargets: number,
}

-- Ventana temporal de un golpe dentro de un combo. MarkerName es el Keyframe
-- Marker de la animación que corresponde a este golpe.
export type ComboHitWindow = {
	MarkerName: string,
	StartTime: number,
	EndTime: number,
	BaseDamage: number,
	PostureDamage: number,
	Hitbox: HitboxDefinition,
}

-- Definición autoritativa (solo servidor). La animación asociada vive en
-- Shared/Content/ComboAnimations, indexada por el mismo Id.
export type ComboDefinition = {
	Id: string,
	Hits: { ComboHitWindow },
	CooldownSeconds: number,
	Cost: ResourceCost?,
}

export type CombatIntentType = "Attack" | "Block" | "Dash"

-- Intención enviada por el cliente al servidor; nunca contiene datos resolutivos como daño.
export type CombatIntent = {
	Type: CombatIntentType,
	-- Attack: combo a ejecutar.
	ComboId: string?,
	-- Block: true al empezar a bloquear, false al soltar (idempotente).
	Active: boolean?,
}

export type ServerResponseStatus = "Accepted" | "Rejected" | "OnCooldown" | "InsufficientResource" | "InvalidState"

export type ServerCombatResponse = {
	Status: ServerResponseStatus,
	Message: string?,
}

export type StateTransitionTable = { [CharacterStateName]: { CharacterStateName } }

return {}
