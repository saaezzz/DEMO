--!strict

-- Botín de un enemigo (§42 drops, D-036). Lógica pura: el azar se inyecta
-- para poder testearlo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type DropEntry = ItemTypes.DropEntry

export type Drop = {
	Item: string,
	Quantity: number,
}

-- `chance()` devuelve un número en [0, 1); `between(min, max)` un entero en [min, max].
export type RandomSource = {
	Chance: () -> number,
	Between: (min: number, max: number) -> number,
}

local DropLogic = {}

function DropLogic.Roll(drops: { DropEntry }, random: RandomSource): { Drop }
	local result: { Drop } = {}
	for _, entry in drops do
		if random.Chance() < entry.Chance then
			table.insert(result, { Item = entry.Item, Quantity = random.Between(entry.Min, entry.Max) })
		end
	end
	return result
end

return DropLogic
