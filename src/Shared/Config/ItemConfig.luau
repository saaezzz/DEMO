--!strict

-- Rarezas e inventario (no IP, D-036). Pauta D-023: lo raro se distingue a
-- simple vista por su color.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type Rarity = ItemTypes.Rarity
type RarityDefinition = ItemTypes.RarityDefinition

local Rarities: { [Rarity]: RarityDefinition } = {
	Common = { DisplayName = "Común", Color = "#B9BEC7", Order = 1 },
	Uncommon = { DisplayName = "Poco común", Color = "#5BD16B", Order = 2 },
	Rare = { DisplayName = "Raro", Color = "#4FA3FF", Order = 3 },
	Epic = { DisplayName = "Épico", Color = "#B06BFF", Order = 4 },
	Legendary = { DisplayName = "Legendario", Color = "#FF9F1A", Order = 5 },
}

return {
	Rarities = Rarities,
	-- Casillas del inventario.
	MaxSlots = 30,
}
