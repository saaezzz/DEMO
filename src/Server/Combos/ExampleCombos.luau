--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type ComboDefinition = GameTypes.ComboDefinition

-- Combo de demostración: tajo simple de una sola fase con hitbox frontal en caja.
local BasicSlash: ComboDefinition = {
	Id = "BasicSlash",
	AnimationId = "rbxassetid://0",
	Hits = {
		{
			MarkerName = "Hit1",
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
	ReiatsuCost = 0,
}

local ExampleCombos: { ComboDefinition } = { BasicSlash }

return ExampleCombos
