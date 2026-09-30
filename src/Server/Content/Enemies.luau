--!strict

-- Contenido: enemigos (capa IP, §4, §42). Valores provisionales hasta BALANCE.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.Shared.Types.EnemyTypes)

type EnemyDefinition = EnemyTypes.EnemyDefinition

local Enemies: { EnemyDefinition } = {
	{
		Id = "WeakHollow",
		DisplayName = "Hollow débil",
		Tier = "Weak",
		Level = 1,
		MaxHealth = 60,
		MaxPosture = 50,
		WalkSpeed = 12,
		Appearance = { BodyColor = "#3A3A44", Scale = 0.9, Mask = true },
		Aggro = { DetectionRange = 35, LoseRange = 60, LeashRange = 80 },
		Attacks = {
			{ Ability = "EnemySwipe", Range = 7, TelegraphSeconds = 0.5 },
		},
		AttackIntervalSeconds = 2.2,
		Experience = 20,
	},
	{
		Id = "StandardHollow",
		DisplayName = "Hollow",
		Tier = "Standard",
		Level = 3,
		MaxHealth = 140,
		MaxPosture = 80,
		WalkSpeed = 14,
		Appearance = { BodyColor = "#1E1E26", Scale = 1.1, Mask = true },
		Aggro = { DetectionRange = 40, LoseRange = 70, LeashRange = 90 },
		Attacks = {
			{ Ability = "EnemySwipe", Range = 7, TelegraphSeconds = 0.45 },
			{ Ability = "EnemyLunge", Range = 16, TelegraphSeconds = 0.6 },
		},
		AttackIntervalSeconds = 1.8,
		Experience = 55,
	},
	{
		Id = "EliteHollow",
		DisplayName = "Hollow élite",
		Tier = "Elite",
		Level = 6,
		MaxHealth = 400,
		MaxPosture = 150,
		WalkSpeed = 15,
		Appearance = { BodyColor = "#4A0F14", Scale = 1.45, Mask = true },
		Aggro = { DetectionRange = 45, LoseRange = 80, LeashRange = 100 },
		Attacks = {
			{ Ability = "EnemySwipe", Range = 8, TelegraphSeconds = 0.4 },
			{ Ability = "EnemyLunge", Range = 18, TelegraphSeconds = 0.55 },
			-- Golpe lento que rompe la guardia: hay que esquivarlo o hacer parry.
			{ Ability = "EnemyCrush", Range = 9, TelegraphSeconds = 0.9 },
		},
		AttackIntervalSeconds = 1.6,
		Experience = 180,
	},
}

return Enemies
