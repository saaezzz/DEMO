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

-- Acciones de combate que el cliente puede pedir (D-025). El cliente pide la
-- acción; el servidor decide qué habilidad ejecuta según el moveset.
export type CombatAction =
	"LightAttack"
	| "HeavyAttack"
	| "Block"
	| "Dodge"
	| "Dash"
	| "Sprint"
	-- Técnicas del moveset (Moveset.Skills).
	| "Ability1"
	| "Ability2"
	| "Ability3"
	| "Ability4"

-- Intención enviada por el cliente al servidor; nunca contiene datos resolutivos como daño.
export type CombatIntent = {
	Action: CombatAction,
	-- Block y Sprint: true al pulsar, false al soltar (idempotente).
	Active: boolean?,
}

-- Cómo se desplaza el personaje en una habilidad de movimiento (§18).
-- "InputOr*": dirección del movimiento del jugador; si no se mueve, la alternativa.
export type MovementDirection = "InputOrForward" | "InputOrBackward" | "Forward" | "Backward"

export type MovementSpec = {
	Distance: number,
	Duration: number,
	Direction: MovementDirection,
	AllowAir: boolean,
}

export type ServerResponseStatus = "Accepted" | "Rejected" | "OnCooldown" | "InsufficientResource" | "InvalidState"

export type ServerCombatResponse = {
	Status: ServerResponseStatus,
	Message: string?,
	-- Habilidad de movimiento aceptada: el cliente aplica el desplazamiento (D-026).
	Movement: MovementSpec?,
	-- Habilidad aceptada con cooldown: segundos hasta poder repetirla (para la UI).
	Cooldown: number?,
}

-- Respuesta de las peticiones que no son de combate (elegir raza, usar objeto...).
export type RequestResponse = {
	Status: "Accepted" | "Rejected",
	Message: string?,
}

export type StateTransitionTable = { [CharacterStateName]: { CharacterStateName } }

return {}
