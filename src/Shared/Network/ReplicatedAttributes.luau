--!strict

-- Contrato de los atributos que el servidor escribe en el modelo de cada
-- personaje (D-021). Los atributos replican solos a todos los clientes; la UI
-- y las animaciones los leen, nunca los escriben.

local RESOURCE_PREFIX = "Resource_"
local RESOURCE_MAX_PREFIX = "ResourceMax_"

local ReplicatedAttributes = {
	LEVEL = "Level",
	RACE = "Race",
	POSTURE = "Posture",
	MAX_POSTURE = "MaxPosture",
	-- Estado de acción (CharacterStateName).
	STATE = "ActionState",
	-- Id del combo en curso; se escribe antes de pasar a Attacking.
	ACTION_ID = "ActionId",
}

function ReplicatedAttributes.Resource(resourceId: string): string
	return RESOURCE_PREFIX .. resourceId
end

function ReplicatedAttributes.ResourceMax(resourceId: string): string
	return RESOURCE_MAX_PREFIX .. resourceId
end

-- Id del recurso si el atributo es el valor actual de un recurso.
function ReplicatedAttributes.ParseResource(attributeName: string): string?
	return string.match(attributeName, "^" .. RESOURCE_PREFIX .. "(.+)$")
end

return ReplicatedAttributes
