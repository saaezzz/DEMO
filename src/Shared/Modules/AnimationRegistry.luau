--!strict

-- Acceso a las animaciones de juego (§53, D-020). Los sistemas usan claves
-- ("Combat.Slash1") y markers estándar; nunca IDs de Roblox.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)
local Animations = require(ReplicatedStorage.Shared.Content.Animations)
local AssetLibrary = require(ReplicatedStorage.Shared.Modules.AssetLibrary)

type AnimationDefinition = ContentTypes.AnimationDefinition
type AnimationMarker = ContentTypes.AnimationMarker

local STANDARD_MARKERS: { AnimationMarker } =
	{ "Startup", "Hit", "Active", "Recovery", "VFX", "SFX", "IFrameStart", "IFrameEnd" }

local ENUM_PRIORITIES: { [string]: Enum.AnimationPriority } = {
	Core = Enum.AnimationPriority.Core,
	Idle = Enum.AnimationPriority.Idle,
	Movement = Enum.AnimationPriority.Movement,
	Action = Enum.AnimationPriority.Action,
}

local AnimationRegistry = {}

AnimationRegistry.STANDARD_MARKERS = STANDARD_MARKERS

function AnimationRegistry.GetEnumPriority(definition: AnimationDefinition): Enum.AnimationPriority
	return ENUM_PRIORITIES[definition.Priority]
end

-- Un marker estándar, opcionalmente con sufijo numérico (Hit, Hit2...).
function AnimationRegistry.IsValidMarker(name: string): boolean
	local base = string.match(name, "^(%a+)%d*$")
	return base ~= nil and table.find(STANDARD_MARKERS, base :: any) ~= nil
end

function AnimationRegistry.Get(key: string): AnimationDefinition?
	return Animations[key]
end

-- ID de Roblox de la animación (del manifiesto o de la colocada en Studio,
-- D-033), o nil si aún no existe: entonces se usa el placeholder.
function AnimationRegistry.GetContentId(key: string): string?
	local definition = Animations[key]
	if definition == nil then
		return nil
	end
	return AssetLibrary.GetContentId(definition.Asset)
end

return AnimationRegistry
