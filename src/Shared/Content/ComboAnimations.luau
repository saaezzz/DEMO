--!strict

-- Contenido: ID de animación por combo, para reproducción en el cliente. Los
-- valores de daño, postura y cooldown viven exclusivamente en el servidor
-- (src/Server/Content/Combos.luau).
-- Un combo sin entrada aquí se ejecuta en el servidor pero no se anima.
local ComboAnimations: { [string]: string } = {
	-- BasicSlash = "rbxassetid://<id>", -- Pendiente: animación del equipo de arte.
}

return ComboAnimations
