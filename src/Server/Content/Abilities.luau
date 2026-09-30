--!strict

-- Contenido: habilidades de combate (capa IP, §4, §17, D-025). Autoritativo:
-- solo lo lee el servidor. Valores provisionales hasta BALANCE.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type AbilityDefinition = AbilityTypes.AbilityDefinition
type HitboxDefinition = GameTypes.HitboxDefinition

-- Caja algo mayor para el ataque pesado.
local HEAVY_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(7, 6, 7),
	Offset = CFrame.new(0, 0, -4.5),
	MaxTargets = 5,
}

-- Caja frontal de los golpes con arma a una mano.
local SWORD_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(6, 5, 6),
	Offset = CFrame.new(0, 0, -4),
	MaxTargets = 5,
}

local Abilities: { AbilityDefinition } = {
	-- Cadena M1 (Moveset.LightAttack): dos tajos y un remate que empuja.
	{
		Id = "Slash1",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.45,
		Cooldown = 0,
		Hits = {
			{ MarkerName = "Hit", StartTime = 0.2, Damage = 10, PostureDamage = 8, Hitbox = SWORD_HITBOX },
		},
		Animation = "Combat.Slash1",
	},
	{
		Id = "Slash2",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.45,
		Cooldown = 0,
		Hits = {
			{ MarkerName = "Hit", StartTime = 0.2, Damage = 10, PostureDamage = 8, Hitbox = SWORD_HITBOX },
		},
		Animation = "Combat.Slash2",
	},
	{
		Id = "Slash3",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.65,
		Cooldown = 0,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.3,
				Damage = 16,
				PostureDamage = 14,
				Hitbox = SWORD_HITBOX,
				Knockback = 45,
			},
		},
		Animation = "Combat.Slash3",
	},

	-- Ataque pesado: lento y costoso, rompe la guardia. Se puede hacer parry.
	{
		Id = "HeavySlash",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.9,
		Cooldown = 3,
		Cost = { Resource = "Stamina", Amount = 20 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.5,
				Damage = 24,
				PostureDamage = 30,
				Hitbox = HEAVY_HITBOX,
				GuardBreak = true,
				Knockback = 35,
			},
		},
		Animation = "Combat.HeavySlash",
	},

	-- Esquiva con invulnerabilidad; cancela un ataque o un bloqueo.
	{
		Id = "Dodge",
		State = "Dodging",
		Requirements = { StartStates = { "Idle", "Blocking", "Attacking" } },
		Duration = 0.4,
		Cooldown = 0.6,
		Cost = { Resource = "Stamina", Amount = 20 },
		IFrames = { Start = 0, End = 0.28 },
		Movement = { Distance = 14, Duration = 0.25, Direction = "InputOrBackward", AllowAir = false },
		Animation = "Combat.Dodge",
	},

	-- GAMEPLAY ADAPTATION de Shunpo (paso instantáneo): dash direccional,
	-- también en el aire. Sonido, Hirenkyaku, etc. serán otras definiciones (§18).
	{
		Id = "Dash",
		State = "Dashing",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.3,
		Cooldown = 1,
		Cost = { Resource = "Reiatsu", Amount = 15 },
		Movement = { Distance = 28, Duration = 0.2, Direction = "InputOrForward", AllowAir = true },
		Animation = "Combat.Dash",
	},
}

return Abilities
