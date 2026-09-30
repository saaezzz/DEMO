--!strict

-- Definiciones de misiones (§40, D-030). Reutilizables y dirigidas por datos.

-- Tipos de §40. Por ahora solo hay objetivos de derrotar enemigos; el resto
-- de tipos añadirán sus propios objetivos cuando se usen.
export type QuestType =
	"Hunt"
	| "Patrol"
	| "Rescue"
	| "Escort"
	| "Investigation"
	| "Defense"
	| "Delivery"
	| "Training"
	| "BossHunt"
	| "Promotion"
	| "Transformation"
	| "Faction"
	| "Story"

export type QuestObjective = {
	Kind: "Kill",
	-- Id del enemigo (Content/Enemies).
	Target: string,
	Count: number,
	-- Texto del seguimiento, p. ej. "Derrota 3 enemigos".
	Description: string,
	-- Dónde está el objetivo, para el marcador en el mundo (D-023).
	Location: Vector3?,
}

export type QuestRewards = {
	Experience: number,
}

export type QuestDefinition = {
	Id: string,
	Title: string,
	Type: QuestType,
	Description: string,
	Objectives: { QuestObjective },
	Rewards: QuestRewards,
	-- Misión que empieza al completar esta.
	Next: string?,
}

return {}
