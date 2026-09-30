--!strict

-- Definiciones de enemigos (§42, D-029). Todos los enemigos usan el mismo
-- servicio y la misma IA; cada uno es solo datos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

export type EnemyTier = "Weak" | "Standard" | "Elite" | "Boss"

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

-- Fase de un enemigo (§43): al bajar su vida de HealthBelow (fracción 0-1)
-- cambia su forma de pelear. Los campos que falten se heredan de la base.
export type EnemyPhase = {
	HealthBelow: number,
	Attacks: { EnemyAttack }?,
	AttackIntervalSeconds: number?,
	WalkSpeed: number?,
	-- Aviso en pantalla al entrar en la fase.
	Announcement: string?,
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
	-- Fases, de mayor a menor HealthBelow (jefes, D-037).
	Phases: { EnemyPhase }?,
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
