--!strict

-- Acceso al manifiesto de assets (§54, D-020). Los sistemas piden assets por
-- nombre; nunca escriben IDs de Roblox a mano.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)
local Assets = require(ReplicatedStorage.Shared.Content.Assets)

type AssetEntry = ContentTypes.AssetEntry
type AssetCategory = ContentTypes.AssetCategory

-- Prefijo obligatorio del nombre según la categoría (docs/ASSETS.md).
local CATEGORY_PREFIXES: { [AssetCategory]: string } = {
	Animation = "ANIM",
	Model = "MDL",
	VFX = "VFX",
	SFX = "SFX",
	Music = "MUS",
	UI = "UI",
	Texture = "TEX",
}

local byName: { [string]: AssetEntry } = {}
for _, entry in Assets do
	assert(byName[entry.Name] == nil, `[AssetRegistry] asset duplicado: {entry.Name}`)
	byName[entry.Name] = entry
end

local AssetRegistry = {}

AssetRegistry.CATEGORY_PREFIXES = CATEGORY_PREFIXES

-- <PREFIJO>_<Grupo>_<Nombre>, en PascalCase y sin espacios.
-- Ej.: ANIM_Sword_BasicSlash, VFX_Combat_SlashTrail, UI_Hud_HealthBar.
function AssetRegistry.IsValidName(name: string, category: AssetCategory): boolean
	local prefix = CATEGORY_PREFIXES[category]
	if prefix == nil or string.sub(name, 1, #prefix + 1) ~= prefix .. "_" then
		return false
	end
	local rest = string.sub(name, #prefix + 2)
	return string.match(rest, "^%u%w*_%u%w*$") ~= nil
end

function AssetRegistry.Get(name: string): AssetEntry?
	return byName[name]
end

-- "rbxassetid://<id>", o nil si el asset no existe o aún no se ha subido.
function AssetRegistry.GetContentId(name: string): string?
	local entry = byName[name]
	if entry == nil or entry.AssetId == nil then
		return nil
	end
	return `rbxassetid://{entry.AssetId}`
end

return AssetRegistry
