--!strict

-- Definiciones de enemigos (§42, D-029). Todos los enemigos usan el mismo
-- servicio y la misma IA; cada uno es solo datos.

export type EnemyTier = "Weak" | "Standard" | "Elite"

export type EnemyAttack = {
	-- Habilidad de Content/Abilities.
	Ability: string,
	-- Distancia máxima al objetivo para usarla.
	Range: number,
	-- Aviso visible antes de atacar (D-023).
	TelegraphSeconds: number,
}

export type EnemyAppearance = {
	-- Color del cuerpo, en hexadecimal ("#RRGGBB").
	BodyColor: string,
	-- Escala del modelo (1 = tamaño normal).
	Scale: number,
	-- Máscara blanca en la cara.
	Mask: boolean,
}

export type EnemyAggro = {
	-- Distancia a la que detecta a un jugador.
	DetectionRange: number,
	-- Distancia a la que pierde al objetivo.
	LoseRange: number,
	-- Distancia máxima desde su punto de aparición: si la supera, vuelve y se cura.
	LeashRange: number,
}

export type EnemyDefinition = {
	Id: string,
	DisplayName: string,
	Tier: EnemyTier,
	Level: number,
	MaxHealth: number,
	MaxPosture: number,
	WalkSpeed: number,
	Appearance: EnemyAppearance,
	Aggro: EnemyAggro,
	Attacks: { EnemyAttack },
	-- Tiempo mínimo entre ataques.
	AttackIntervalSeconds: number,
	-- EXP para cada jugador que le haya hecho daño.
	Experience: number,
}

export type EnemySpawn = {
	Enemy: string,
	Position: Vector3,
	Count: number,
	-- Radio alrededor de Position en el que aparecen.
	Radius: number,
	RespawnSeconds: number,
}

return {}
