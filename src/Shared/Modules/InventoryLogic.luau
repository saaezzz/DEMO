--!strict

-- Operaciones del inventario (§46, D-036). Lógica pura: nunca modifica la
-- lista recibida (son datos del perfil), devuelve una copia.
-- El inventario es una lista de casillas { Id, Quantity }; un mismo objeto
-- puede ocupar varias si supera su MaxStack.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)

type ItemDefinition = ItemTypes.ItemDefinition
type InventoryItem = PlayerDataTypes.InventoryItem
type Inventory = { InventoryItem }

local function copy(inventory: Inventory): Inventory
	local result: Inventory = {}
	for _, slot in inventory do
		table.insert(result, { Id = slot.Id, Quantity = slot.Quantity })
	end
	return result
end

local InventoryLogic = {}

function InventoryLogic.Count(inventory: Inventory, itemId: string): number
	local total = 0
	for _, slot in inventory do
		if slot.Id == itemId then
			total += slot.Quantity
		end
	end
	return total
end

-- Añade hasta `quantity`: primero llena las casillas que ya tiene y después
-- ocupa casillas nuevas mientras queden. Devuelve el inventario nuevo y
-- cuántos cupieron (lo que no cabe se pierde).
function InventoryLogic.Add(
	inventory: Inventory,
	definition: ItemDefinition,
	quantity: number,
	maxSlots: number
): (Inventory, number)
	local result = copy(inventory)
	local requested = math.max(0, math.floor(quantity))
	local remaining = requested

	for _, slot in result do
		if remaining <= 0 then
			break
		end
		if slot.Id == definition.Id and slot.Quantity < definition.MaxStack then
			local added = math.min(remaining, definition.MaxStack - slot.Quantity)
			slot.Quantity += added
			remaining -= added
		end
	end
	while remaining > 0 and #result < maxSlots do
		local added = math.min(remaining, definition.MaxStack)
		table.insert(result, { Id = definition.Id, Quantity = added })
		remaining -= added
	end

	return result, requested - remaining
end

-- Quita `quantity` (empezando por las últimas casillas). nil si no hay suficientes.
function InventoryLogic.Remove(inventory: Inventory, itemId: string, quantity: number): Inventory?
	if InventoryLogic.Count(inventory, itemId) < quantity then
		return nil
	end
	local result = copy(inventory)
	local remaining = quantity
	for index = #result, 1, -1 do
		local slot = result[index]
		if remaining > 0 and slot.Id == itemId then
			local removed = math.min(remaining, slot.Quantity)
			slot.Quantity -= removed
			remaining -= removed
			if slot.Quantity <= 0 then
				table.remove(result, index)
			end
		end
	end
	return result
end

return InventoryLogic
