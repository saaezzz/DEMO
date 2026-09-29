--!strict

-- Valida el payload de CombatIntent recibido del cliente y devuelve una copia
-- saneada. El servidor nunca debe usar la tabla original del cliente.
-- Solo depende de `game` para importar tipos; en tests fuera de Studio hay que
-- proporcionar ReplicatedStorage.Shared (ver D-006).

local GameTypes = require(game:GetService("ReplicatedStorage").Shared.Types.GameTypes)

type CombatIntent = GameTypes.CombatIntent

local MAX_FIELDS = 8
local MAX_ID_LENGTH = 64
local MAX_DIRECTION_MAGNITUDE = 1.5

local VALID_TYPES: { [string]: boolean } = {
	Attack = true,
	Block = true,
	Shunpo = true,
	CastAbility = true,
}

local ALLOWED_FIELDS: { [string]: boolean } = {
	Type = true,
	ComboId = true,
	AbilityId = true,
	TargetDirection = true,
	ClientTimestamp = true,
}

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function validateId(value: unknown): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if typeof(value) ~= "string" then
		return false, nil
	end
	local id = value :: string
	if #id == 0 or #id > MAX_ID_LENGTH then
		return false, nil
	end
	return true, id
end

local CombatIntentValidator = {}

function CombatIntentValidator.Validate(payload: unknown): (CombatIntent?, string?)
	if typeof(payload) ~= "table" then
		return nil, "Payload no es una tabla"
	end
	local raw = payload :: { [unknown]: unknown }

	local fieldCount = 0
	for key in pairs(raw) do
		fieldCount += 1
		if fieldCount > MAX_FIELDS then
			return nil, "Payload demasiado grande"
		end
		if typeof(key) ~= "string" or not ALLOWED_FIELDS[key :: string] then
			return nil, "Campo no permitido"
		end
	end

	local intentType = raw.Type
	if typeof(intentType) ~= "string" or not VALID_TYPES[intentType :: string] then
		return nil, "Tipo de intent inválido"
	end

	local comboOk, comboId = validateId(raw.ComboId)
	if not comboOk then
		return nil, "ComboId inválido"
	end

	local abilityOk, abilityId = validateId(raw.AbilityId)
	if not abilityOk then
		return nil, "AbilityId inválido"
	end

	local targetDirection: Vector3? = nil
	if raw.TargetDirection ~= nil then
		if typeof(raw.TargetDirection) ~= "Vector3" then
			return nil, "TargetDirection inválido"
		end
		local direction = raw.TargetDirection :: Vector3
		if
			not isFiniteNumber(direction.X)
			or not isFiniteNumber(direction.Y)
			or not isFiniteNumber(direction.Z)
			or direction.Magnitude > MAX_DIRECTION_MAGNITUDE
		then
			return nil, "TargetDirection inválido"
		end
		targetDirection = direction
	end

	-- El timestamp del cliente es solo informativo; nunca se usa para decisiones.
	local clientTimestamp = 0
	if typeof(raw.ClientTimestamp) == "number" and isFiniteNumber(raw.ClientTimestamp :: number) then
		clientTimestamp = raw.ClientTimestamp :: number
	end

	return {
		Type = intentType :: any,
		ComboId = comboId,
		AbilityId = abilityId,
		TargetDirection = targetDirection,
		ClientTimestamp = clientTimestamp,
	},
		nil
end

return CombatIntentValidator
