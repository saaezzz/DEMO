--!strict

-- Catálogo de solo lectura para el cliente: ID de animación por combo, para
-- reproducción local. Los valores de daño, postura y cooldown viven
-- exclusivamente en el servidor (src/Server/Combos/ExampleCombos.luau).
-- Un combo sin entrada aquí se ejecuta en el servidor pero no se anima.
local ClientComboCatalog: { [string]: string } = {
	-- BasicSlash = "rbxassetid://<id>", -- Pendiente: animación del equipo de arte.
}

return ClientComboCatalog
