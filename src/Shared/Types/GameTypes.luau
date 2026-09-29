--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type RaceId = ContentTypes.RaceId
type ResourceId = ContentTypes.ResourceId

-- Estados de acción de un personaje (§15, adaptado en D-017). Son exclusivos
-- entre sí. La locomoción (Moving/Running/Sprinting) y la forma transformada
-- (Transformed) son capas independientes, no estados de esta máquina.
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
	ComboId: string?,
}

export type ServerResponseStatus = "Accepted" | "Rejected" | "OnCooldown" | "InsufficientResource" | "InvalidState"

export type ServerCombatResponse = {
	Status: ServerResponseStatus,
	Message: string?,
}

export type StateTransitionTable = { [CharacterStateName]: { CharacterStateName } }

return {}
