--!strict

-- Esquema del payload de CombatIntent. Devuelve una copia saneada; el servidor
-- nunca usa la tabla original del cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(ReplicatedStorage.Shared.Network.Schema)

local CombatIntentValidator = {}

-- (true, CombatIntent) o (false, motivo).
CombatIntentValidator.Validate = Schema.record({
	Action = Schema.literal({
		"LightAttack",
		"HeavyAttack",
		"Block",
		"Dodge",
		"Dash",
		"Sprint",
		"Ability1",
		"Ability2",
		"Ability3",
		"Ability4",
	}),
	Active = Schema.optional(Schema.boolean()),
})

return CombatIntentValidator
