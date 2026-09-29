--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type ComboDefinition = GameTypes.ComboDefinition

-- Contenido: combos autoritativos (capa IP, §4). La animación de cada combo
-- está en Shared/Content/ComboAnimations.

-- Combo de demostración: tajo simple de una sola fase con hitbox frontal en caja.
local BasicSlash: ComboDefinition = {
	Id = "BasicSlash",
	Hits = {
		{
			MarkerName = "Hit",
			StartTime = 0.2,
			EndTime = 0.35,
			BaseDamage = 12,
			PostureDamage = 8,
			Hitbox = {
				Shape = "Box",
				Size = Vector3.new(6, 5, 6),
				Offset = CFrame.new(0, 0, -4),
				MaxTargets = 5,
			},
		},
	},
	CooldownSeconds = 0.6,
}

local Combos: { ComboDefinition } = { BasicSlash }

return Combos
