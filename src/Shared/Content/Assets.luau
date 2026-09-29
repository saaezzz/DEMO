--!strict

-- Contenido: manifiesto de assets (§54, D-020). Única fuente de verdad de los
-- IDs de Roblox. Convención de nombres y flujo de estados en docs/ASSETS.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type AssetEntry = ContentTypes.AssetEntry

local Assets: { AssetEntry } = {
	{
		Name = "ANIM_Sword_BasicSlash",
		Category = "Animation",
		AssetId = nil,
		Owner = "Animación/Visual",
		Status = "TODO",
		Version = 0,
		Dependencies = {},
		UsedBy = { "Combo:BasicSlash" },
		Notes = "Tajo horizontal de una mano. Marker 'Hit' en el frame del impacto (~0,2 s).",
	},
}

return Assets
