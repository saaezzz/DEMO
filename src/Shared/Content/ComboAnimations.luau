--!strict

-- Contenido: animación de cada combo (clave de Content/Animations). Los
-- valores de daño, postura y cooldown viven exclusivamente en el servidor
-- (src/Server/Content/Combos.luau).

local ComboAnimations: { [string]: string } = {
	BasicSlash = "Combat.BasicSlash",
}

return ComboAnimations
