--!strict

-- Contenido: animación de cada estado de acción (D-022). Attacking no está:
-- su animación depende del combo (Content/ComboAnimations).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type CharacterStateName = GameTypes.CharacterStateName

local StateAnimations: { [CharacterStateName]: string } = {
	Blocking = "Combat.Block",
	Parrying = "Combat.Block",
	Dashing = "Combat.Dash",
	Stunned = "Reaction.Stun",
	Knocked = "Reaction.Stun",
}

return StateAnimations
