--!strict

-- Objetos e inventario (§46, D-036). Framework genérico: cada objeto es solo
-- datos (Content/Items).

-- Categorías de §46.
export type ItemCategory =
	"Weapon"
	| "Consumable"
	| "QuestItem"
	| "Material"
	| "Accessory"
	| "Cosmetic"
	| "TransformationItem"

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

-- Efecto de usar un objeto consumible.
export type ItemUse = {
	Heal: number?,
	-- Recupera un recurso (Content/Resources).
	Restore: { Resource: string, Amount: number }?,
	-- Segundos antes de poder usar otro igual.
	Cooldown: number,
}

export type ItemDefinition = {
	Id: string,
	DisplayName: string,
	Description: string,
	Category: ItemCategory,
	Rarity: Rarity,
	-- Cuántos caben en una casilla.
	MaxStack: number,
	-- Imagen del manifiesto (UI_...). Sin ella, la casilla muestra las iniciales.
	Icon: string?,
	-- Solo los consumibles.
	Use: ItemUse?,
}

-- Posible botín de un enemigo: probabilidad (0-1) y cantidad entre Min y Max.
export type DropEntry = {
	Item: string,
	Chance: number,
	Min: number,
	Max: number,
}

export type RarityDefinition = {
	DisplayName: string,
	Color: string,
	-- Para ordenar (mayor = más raro).
	Order: number,
}

return {}
