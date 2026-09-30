--!strict

-- Contenido: animación de los estados que no vienen de una habilidad (D-022).
-- Las habilidades (ataques, esquiva, dash) llevan su propia animación en su
-- definición (D-025).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type CharacterStateName = GameTypes.CharacterStateName

local StateAnimations: { [CharacterStateName]: string } = {
	Blocking = "Combat.Block",
	Parrying = "Combat.Block",
	Stunned = "Reaction.Stun",
	Knocked = "Reaction.Stun",
}

return StateAnimations
