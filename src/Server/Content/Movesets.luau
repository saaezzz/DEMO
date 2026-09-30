--!strict

-- Contenido: qué habilidad ejecuta cada acción de input (D-025). Por ahora
-- todos los personajes usan el mismo; más adelante dependerá de raza y arma.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)

type Moveset = AbilityTypes.Moveset

local Movesets: { [string]: Moveset } = {
	Default = {
		LightAttack = { "Slash1", "Slash2", "Slash3" },
		HeavyAttack = "HeavySlash",
		Dodge = "Dodge",
		Dash = "Dash",
	},
}

return Movesets
