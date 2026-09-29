--!strict

-- Contenido: parámetros de acciones de combate genéricas (capa IP, §4).
-- Provisional: el dash se convertirá en una definición del framework de
-- movimiento (M2), donde Shunpo, Sonido e Hirenkyaku serán datos distintos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type ResourceCost = GameTypes.ResourceCost

export type DashDefinition = {
	DurationSeconds: number,
	Cost: ResourceCost?,
}

local CombatActions: { Dash: DashDefinition } = {
	-- GAMEPLAY ADAPTATION de Shunpo (paso instantáneo).
	Dash = {
		DurationSeconds = 0.4,
		Cost = { Resource = "Reiatsu", Amount = 15 },
	},
}

return CombatActions
