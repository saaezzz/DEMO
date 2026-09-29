--!strict

-- Esquema del payload de CombatIntent. Devuelve una copia saneada; el servidor
-- nunca usa la tabla original del cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schema = require(ReplicatedStorage.Shared.Network.Schema)

local MAX_ID_LENGTH = 64

local CombatIntentValidator = {}

-- (true, CombatIntent) o (false, motivo).
CombatIntentValidator.Validate = Schema.record({
	Type = Schema.literal({ "Attack", "Block", "Dash" }),
	ComboId = Schema.optional(Schema.string(MAX_ID_LENGTH)),
})

return CombatIntentValidator
