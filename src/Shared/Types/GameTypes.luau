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
-- Shared/Combos/ClientComboCatalog, indexada por el mismo Id.
export type ComboDefinition = {
	Id: string,
	Hits: { ComboHitWindow },
	CooldownSeconds: number,
	ReiatsuCost: number,
}

export type CombatIntentType = "Attack" | "Block" | "Shunpo"

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
