--!strict

-- Estados posibles de la máquina de estados de combate de un personaje.
export type CharacterStateName = "Idle" | "Attacking" | "Blocking" | "Stunned" | "Shunpo" | "Casting" | "Ragdoll"

-- Razas jugables del universo Bleach.
export type CharacterRace = "Human" | "Shinigami" | "Hollow" | "Quincy" | "Fullbring"

export type CharacterAttributes = {
	Health: number,
	MaxHealth: number,
	Reiatsu: number,
	MaxReiatsu: number,
	Posture: number,
	MaxPosture: number,
	Race: CharacterRace,
	Level: number,
}

-- Ventana temporal de un golpe dentro de un combo, referenciada a un Keyframe Marker.
export type HitboxShape = "Box" | "Sphere" | "Cylinder"

export type HitboxDefinition = {
	Shape: HitboxShape,
	Size: Vector3,
	Offset: CFrame,
	MaxTargets: number,
}

export type ComboHitWindow = {
	MarkerName: string,
	StartTime: number,
	EndTime: number,
	BaseDamage: number,
	PostureDamage: number,
	Hitbox: HitboxDefinition,
}

export type ComboDefinition = {
	Id: string,
	AnimationId: string,
	Hits: { ComboHitWindow },
	CooldownSeconds: number,
	ReiatsuCost: number,
}

-- Intención enviada por el cliente al servidor; nunca contiene datos resolutivos como daño.
export type CombatIntent = {
	Type: "Attack" | "Block" | "Shunpo" | "CastAbility",
	ComboId: string?,
	AbilityId: string?,
	TargetDirection: Vector3?,
	ClientTimestamp: number,
}

export type ServerResponseStatus = "Accepted" | "Rejected" | "OnCooldown" | "InsufficientResource" | "InvalidState"

export type ServerCombatResponse = {
	Status: ServerResponseStatus,
	Message: string?,
	AppliedDamage: number?,
	TargetUserId: number?,
}

export type StateTransitionTable = { [CharacterStateName]: { CharacterStateName } }

return {}
