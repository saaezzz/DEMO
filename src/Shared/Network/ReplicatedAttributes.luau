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
	-- Capa de locomoción (LocomotionState) y forma (id de transformación o nil), D-024.
	LOCOMOTION = "Locomotion",
	FORM = "Form",
	-- Animación de la habilidad en curso (clave de Content/Animations) y un
	-- contador que sube con cada habilidad, para que dos habilidades seguidas con
	-- el mismo estado se distingan. Se escriben antes de la transición (D-025).
	ACTION_ANIMATION = "ActionAnimation",
	ACTION_SEQ = "ActionSeq",
	-- NPCs de combate: nombre visible y aviso de ataque (sube antes de atacar, D-023).
	DISPLAY_NAME = "DisplayName",
	TELEGRAPH = "Telegraph",
	-- Etiqueta (CollectionService) de los modelos de NPC que combaten.
	NPC_TAG = "CombatNPC",
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
