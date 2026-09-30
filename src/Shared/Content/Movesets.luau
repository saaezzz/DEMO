--!strict

-- Contenido: qué habilidad ejecuta cada acción de input (D-025). Cada raza
-- elige su moveset en su kit (Content/Races). Compartido: el cliente lo usa
-- para mostrar las técnicas en la barra de acciones.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)

type Moveset = AbilityTypes.Moveset

local Movesets: { [string]: Moveset } = {
	-- Antes de elegir raza: golpes básicos y un paso rápido que gasta stamina.
	Default = {
		LightAttack = { "Slash1", "Slash2", "Slash3" },
		HeavyAttack = "HeavySlash",
		Dodge = "Dodge",
		Dash = "Step",
		Skills = {},
	},
	-- Shinigami (§22, §26, §28): espada, Shunpo y Kido básico.
	Shinigami = {
		LightAttack = { "Slash1", "Slash2", "Slash3" },
		HeavyAttack = "HeavySlash",
		Dodge = "Dodge",
		Dash = "Shunpo",
		Skills = { "Byakurai", "Sai" },
	},
}

return Movesets
