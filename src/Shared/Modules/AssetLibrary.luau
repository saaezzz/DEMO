--!strict

-- Assets de arte colocados en Studio (D-033). Arte y animación trabajan en
-- Studio (§55): basta con meter el objeto en ReplicatedStorage.Assets, en la
-- subcarpeta de su categoría y con el nombre exacto del manifiesto
-- (docs/GUIA_EQUIPO.md). El código lo usa sin cambios; si no está, se usa
-- el placeholder.
--
--   Animations/ANIM_Sword_Slash1   (Animation con su AnimationId)
--   Models/MDL_Weapon_StarterSword (Model)
--   VFX/VFX_Combat_SlashTrail      (Model o Part con ParticleEmitters)
--   Sounds/SFX_Combat_SwordHit     (Sound con su SoundId)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)
local AssetRegistry = require(ReplicatedStorage.Shared.Modules.AssetRegistry)

type AssetCategory = ContentTypes.AssetCategory

local ROOT_FOLDER = "Assets"

-- Subcarpeta de Assets donde va cada categoría.
local FOLDERS: { [AssetCategory]: string } = {
	Animation = "Animations",
	Model = "Models",
	VFX = "VFX",
	SFX = "Sounds",
	Music = "Sounds",
}

local AssetLibrary = {}

AssetLibrary.FOLDERS = FOLDERS

-- El objeto colocado en Studio para `name`, o nil si no está.
function AssetLibrary.FindInstance(name: string): Instance?
	local entry = AssetRegistry.Get(name)
	local folderName = if entry ~= nil then FOLDERS[entry.Category] else nil
	local root = ReplicatedStorage:FindFirstChild(ROOT_FOLDER)
	local folder = if root ~= nil and folderName ~= nil then root:FindFirstChild(folderName) else nil
	return if folder ~= nil then folder:FindFirstChild(name) else nil
end

-- ID de Roblox listo para usar: el del manifiesto o, si aún no lo tiene, el del
-- objeto de Studio (Animation.AnimationId o Sound.SoundId). nil si no hay ninguno.
function AssetLibrary.GetContentId(name: string): string?
	local fromManifest = AssetRegistry.GetContentId(name)
	if fromManifest ~= nil then
		return fromManifest
	end
	local instance = AssetLibrary.FindInstance(name)
	local contentId = if instance == nil
		then nil
		elseif instance:IsA("Animation") then instance.AnimationId
		elseif instance:IsA("Sound") then instance.SoundId
		else nil
	return if contentId ~= nil and contentId ~= "" then contentId else nil
end

-- Copia del modelo o efecto colocado en Studio, o nil si no está.
function AssetLibrary.Clone(name: string): Instance?
	local instance = AssetLibrary.FindInstance(name)
	return if instance ~= nil then instance:Clone() else nil
end

return AssetLibrary
