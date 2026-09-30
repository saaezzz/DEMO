local InventoryLogic = require(game:GetService("ReplicatedStorage").Shared.Modules.InventoryLogic)

local POTION = { Id = "Potion", MaxStack = 5 }
local ORE = { Id = "Ore", MaxStack = 99 }

return {
	["Add llena la casilla existente antes de abrir otra"] = function()
		local inventory = { { Id = "Potion", Quantity = 3 } }
		local result, added = InventoryLogic.Add(inventory, POTION, 4, 10)
		expect(added).toBe(4)
		expect(result).toEqual({ { Id = "Potion", Quantity = 5 }, { Id = "Potion", Quantity = 2 } })
		-- No toca la lista original.
		expect(inventory[1].Quantity).toBe(3)
	end,

	["Add respeta el límite de casillas y dice cuántos cupieron"] = function()
		local inventory = { { Id = "Ore", Quantity = 1 } }
		local result, added = InventoryLogic.Add(inventory, POTION, 12, 2)
		expect(added).toBe(5)
		expect(#result).toBe(2)
	end,

	["Count suma todas las casillas del objeto"] = function()
		local inventory =
			{ { Id = "Potion", Quantity = 5 }, { Id = "Ore", Quantity = 9 }, { Id = "Potion", Quantity = 2 } }
		expect(InventoryLogic.Count(inventory, "Potion")).toBe(7)
		expect(InventoryLogic.Count(inventory, "Nope")).toBe(0)
	end,

	["Remove quita desde las últimas casillas y borra las vacías"] = function()
		local inventory =
			{ { Id = "Potion", Quantity = 5 }, { Id = "Ore", Quantity = 9 }, { Id = "Potion", Quantity = 2 } }
		local result = InventoryLogic.Remove(inventory, "Potion", 3)
		expect(result).toEqual({ { Id = "Potion", Quantity = 4 }, { Id = "Ore", Quantity = 9 } })
	end,

	["Remove devuelve nil si no hay suficientes"] = function()
		expect(InventoryLogic.Remove({ { Id = "Ore", Quantity = 1 } }, "Ore", 2)).toBeNil()
	end,

	["Add con cantidades no enteras o negativas no añade de más"] = function()
		local _, added = InventoryLogic.Add({}, ORE, -3, 10)
		expect(added).toBe(0)
		local _, fractional = InventoryLogic.Add({}, ORE, 2.7, 10)
		expect(fractional).toBe(2)
	end,
}
