--!strict

-- Valida el payload de CombatIntent recibido del cliente y devuelve una copia
-- saneada. El servidor nunca debe usar la tabla original del cliente.

local GameTypes = require(game:GetService("ReplicatedStorage").Shared.Types.GameTypes)

type CombatIntent = GameTypes.CombatIntent
type CombatIntentType = GameTypes.CombatIntentType

local MAX_FIELDS = 2
local MAX_ID_LENGTH = 64

local VALID_TYPES: { [string]: CombatIntentType } = {
	Attack = "Attack",
	Block = "Block",
	Shunpo = "Shunpo",
}

local ALLOWED_FIELDS: { [string]: boolean } = {
	Type = true,
	ComboId = true,
}

local CombatIntentValidator = {}

function CombatIntentValidator.Validate(payload: unknown): (CombatIntent?, string?)
	if typeof(payload) ~= "table" then
		return nil, "Payload no es una tabla"
	end
	local raw = payload :: { [unknown]: unknown }

	local fieldCount = 0
	for key in raw do
		fieldCount += 1
		if fieldCount > MAX_FIELDS then
			return nil, "Payload demasiado grande"
		end
		if typeof(key) ~= "string" or not ALLOWED_FIELDS[key] then
			return nil, "Campo no permitido"
		end
	end

	local rawType = raw.Type
	local intentType: CombatIntentType? = if typeof(rawType) == "string" then VALID_TYPES[rawType] else nil
	if intentType == nil then
		return nil, "Tipo de intent inválido"
	end

	local rawComboId = raw.ComboId
	local comboId: string? = nil
	if rawComboId ~= nil then
		if typeof(rawComboId) ~= "string" or #rawComboId == 0 or #rawComboId > MAX_ID_LENGTH then
			return nil, "ComboId inválido"
		end
		comboId = rawComboId
	end

	local intent: CombatIntent = {
		Type = intentType,
		ComboId = comboId,
	}
	return intent, nil
end

return CombatIntentValidator
