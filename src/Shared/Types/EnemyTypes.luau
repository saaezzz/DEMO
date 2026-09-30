--!strict

-- Definiciones de enemigos (§42, D-029). Todos los enemigos usan el mismo
-- servicio y la misma IA; cada uno es solo datos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

export type EnemyTier = "Weak" | "Standard" | "Elite"

export type EnemyAttack = {
	-- Habilidad de Content/Abilities.
	Ability: string,
	-- Distancia máxima al objetivo para usarla.
	Range: number,
	-- Aviso visible antes de atacar (D-023).
	TelegraphSeconds: number,
	-- Radio del área de impacto alrededor del enemigo: se marca en el suelo durante el aviso.
	AreaRadius: number?,
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
	-- Modelo del manifiesto (MDL_...). Si no está colocado en Studio, se genera un
	-- rig con Appearance.
	Model: string?,
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
	-- Botín (D-036): cada jugador que le haya hecho daño tira el suyo.
	Drops: { ItemTypes.DropEntry }?,
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
