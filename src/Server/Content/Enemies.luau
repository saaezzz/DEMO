--!strict

-- Contenido: enemigos (capa IP, §4, §42). Valores provisionales hasta BALANCE.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.Shared.Types.EnemyTypes)

type EnemyDefinition = EnemyTypes.EnemyDefinition
type EnemyPhase = EnemyTypes.EnemyPhase

-- Fases del jefe: en la 2 añade la carga y acelera; en la 3 ataca sin pausa.
local GREAT_HOLLOW_PHASES: { EnemyPhase } = {
	{
		HealthBelow = 0.6,
		Attacks = {
			{ Ability = "BossSwipe", Range = 12, TelegraphSeconds = 0.5 },
			{ Ability = "BossSlam", Range = 12, TelegraphSeconds = 1.1, AreaRadius = 14 },
			{ Ability = "BossCharge", Range = 35, TelegraphSeconds = 0.9 },
		},
		AttackIntervalSeconds = 1.5,
		WalkSpeed = 16,
		Announcement = "¡El Gran Hollow se enfurece!",
	},
	{
		HealthBelow = 0.25,
		AttackIntervalSeconds = 1.1,
		Announcement = "¡El Gran Hollow está desesperado!",
	},
}

local Enemies: { EnemyDefinition } = {
	{
		Id = "WeakHollow",
		DisplayName = "Hollow débil",
		Tier = "Weak",
		Model = "MDL_Enemy_WeakHollow",
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
		Drops = {
			{ Item = "MaskFragment", Chance = 0.6, Min = 1, Max = 2 },
			{ Item = "HealingBalm", Chance = 0.1, Min = 1, Max = 1 },
		},
	},
	{
		Id = "StandardHollow",
		DisplayName = "Hollow",
		Tier = "Standard",
		Model = "MDL_Enemy_StandardHollow",
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
		Drops = {
			{ Item = "MaskFragment", Chance = 0.8, Min = 1, Max = 3 },
			{ Item = "HollowCore", Chance = 0.15, Min = 1, Max = 1 },
			{ Item = "ReiatsuTonic", Chance = 0.15, Min = 1, Max = 1 },
		},
	},
	{
		Id = "EliteHollow",
		DisplayName = "Hollow élite",
		Tier = "Elite",
		Model = "MDL_Enemy_EliteHollow",
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
		Drops = {
			{ Item = "HollowCore", Chance = 0.6, Min = 1, Max = 2 },
			{ Item = "EliteFang", Chance = 0.25, Min = 1, Max = 1 },
			{ Item = "HealingBalm", Chance = 0.5, Min = 1, Max = 2 },
		},
	},

	-- Jefe (§43, D-037): la dificultad sale de sus patrones y avisos, no de una
	-- vida enorme. Contraataques: su postura se rompe (aturdido 1,5 s) y se le
	-- puede hacer parry; el golpe en área se esquiva saliendo del círculo.
	{
		Id = "GreatHollow",
		DisplayName = "Gran Hollow",
		Tier = "Boss",
		Model = "MDL_Boss_GreatHollow",
		Level = 10,
		MaxHealth = 1600,
		MaxPosture = 250,
		WalkSpeed = 13,
		Appearance = { BodyColor = "#141418", Scale = 2.2, Mask = true },
		Aggro = { DetectionRange = 50, LoseRange = 90, LeashRange = 110 },
		Attacks = {
			{ Ability = "BossSwipe", Range = 12, TelegraphSeconds = 0.6 },
			{ Ability = "BossSlam", Range = 12, TelegraphSeconds = 1.2, AreaRadius = 14 },
		},
		AttackIntervalSeconds = 1.9,
		Experience = 600,
		Drops = {
			{ Item = "HollowCore", Chance = 1, Min = 2, Max = 3 },
			{ Item = "EliteFang", Chance = 1, Min = 1, Max = 2 },
			{ Item = "GreatHollowMask", Chance = 0.3, Min = 1, Max = 1 },
		},
		Phases = GREAT_HOLLOW_PHASES,
	},
}

return Enemies
