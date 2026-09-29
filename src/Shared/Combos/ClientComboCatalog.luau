--!strict

-- Catálogo de solo-lectura para el cliente: únicamente IDs de animación para
-- reproducción local/predicción visual. Los valores de daño, postura y
-- cooldown viven exclusivamente en src/server/Combos/ExampleCombos.luau.
local ClientComboCatalog: { [string]: string } = {
	BasicSlash = "rbxassetid://0",
}

return ClientComboCatalog
