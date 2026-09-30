--!strict

-- Contenido: objetos (capa IP, §4, §46). Pocos al principio (§46: "avoid
-- enormous loot complexity initially").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type ItemDefinition = ItemTypes.ItemDefinition

local Items: { [string]: ItemDefinition } = {
	HealingBalm = {
		Id = "HealingBalm",
		DisplayName = "Bálsamo curativo",
		Description = "Recupera 40 de vida.",
		Category = "Consumable",
		Rarity = "Uncommon",
		MaxStack = 10,
		Use = { Heal = 40, Cooldown = 5 },
	},
	ReiatsuTonic = {
		Id = "ReiatsuTonic",
		DisplayName = "Tónico de Reiatsu",
		Description = "Recupera 50 de Reiatsu.",
		Category = "Consumable",
		Rarity = "Uncommon",
		MaxStack = 10,
		Use = { Restore = { Resource = "Reiatsu", Amount = 50 }, Cooldown = 5 },
	},
	MaskFragment = {
		Id = "MaskFragment",
		DisplayName = "Fragmento de máscara",
		Description = "Trozo de la máscara de un Hollow. Material común.",
		Category = "Material",
		Rarity = "Common",
		MaxStack = 99,
	},
	HollowCore = {
		Id = "HollowCore",
		DisplayName = "Núcleo de Hollow",
		Description = "Concentrado de Reiatsu de un Hollow fuerte.",
		Category = "Material",
		Rarity = "Rare",
		MaxStack = 20,
	},
	EliteFang = {
		Id = "EliteFang",
		DisplayName = "Colmillo de élite",
		Description = "Trofeo de un Hollow élite.",
		Category = "Material",
		Rarity = "Epic",
		MaxStack = 20,
	},
	GreatHollowMask = {
		Id = "GreatHollowMask",
		DisplayName = "Máscara del Gran Hollow",
		Description = "Trofeo de haber derrotado al Gran Hollow.",
		Category = "Material",
		Rarity = "Legendary",
		MaxStack = 5,
	},
}

return Items
