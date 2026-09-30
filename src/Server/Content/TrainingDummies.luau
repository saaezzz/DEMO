--!strict

-- Contenido: muñecos de entrenamiento (M2). Sirven para probar el combate en
-- solitario: golpes, parry, esquiva y rotura de guardia.

export type DummyBehavior =
	"Passive" -- no hace nada
	| "Attacker" -- ataca al jugador más cercano, con aviso previo
	| "Guard" -- mantiene la guardia; vuelve a ella tras un aturdimiento

export type DummyDefinition = {
	Id: string,
	DisplayName: string,
	Position: Vector3,
	Behavior: DummyBehavior,
	MaxHealth: number,
	MaxPosture: number,
	-- Solo "Attacker".
	AttackAbility: string?,
	AttackIntervalSeconds: number?,
	AttackRange: number?,
	-- Tiempo entre el aviso visible y el ataque.
	TelegraphSeconds: number?,
}

local TrainingDummies: { DummyDefinition } = {
	{
		Id = "Passive",
		DisplayName = "Muñeco",
		Position = Vector3.new(-12, 4, -30),
		Behavior = "Passive",
		MaxHealth = 300,
		MaxPosture = 100,
	},
	{
		Id = "Attacker",
		DisplayName = "Muñeco atacante",
		Position = Vector3.new(0, 4, -30),
		Behavior = "Attacker",
		MaxHealth = 300,
		MaxPosture = 100,
		AttackAbility = "Slash1",
		AttackIntervalSeconds = 2.5,
		AttackRange = 9,
		TelegraphSeconds = 0.6,
	},
	{
		Id = "Guard",
		DisplayName = "Muñeco en guardia",
		Position = Vector3.new(12, 4, -30),
		Behavior = "Guard",
		MaxHealth = 300,
		MaxPosture = 100,
	},
}

return TrainingDummies
