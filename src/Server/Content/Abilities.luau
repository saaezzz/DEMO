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

local CLAW_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(6, 5, 6),
	Offset = CFrame.new(0, 0, -3.5),
	MaxTargets = 3,
}

local CRUSH_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(9, 6, 9),
	Offset = CFrame.new(0, 0, -4.5),
	MaxTargets = 5,
}

-- Rayo recto y largo.
local BEAM_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(3, 3, 40),
	Offset = CFrame.new(0, 0.5, -21),
	MaxTargets = 3,
}

-- Atadura a un único objetivo cercano.
local BIND_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(6, 6, 14),
	Offset = CFrame.new(0, 0, -7),
	MaxTargets = 1,
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
				Knockback = 55,
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
				Knockback = 45,
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

	-- Enemigos (Content/Enemies) -------------------------------------------

	-- Zarpazo rápido de corto alcance.
	{
		Id = "EnemySwipe",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.6,
		Cooldown = 0,
		Hits = {
			{ MarkerName = "Hit", StartTime = 0.25, Damage = 8, PostureDamage = 10, Hitbox = CLAW_HITBOX },
		},
		Animation = "Enemy.Swipe",
	},
	-- Embestida: salta hacia delante y golpea.
	{
		Id = "EnemyLunge",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.7,
		Cooldown = 3,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.3,
				Damage = 14,
				PostureDamage = 18,
				Hitbox = CLAW_HITBOX,
				Knockback = 40,
			},
		},
		Movement = { Distance = 14, Duration = 0.25, Direction = "Forward", AllowAir = false },
		Animation = "Enemy.Lunge",
	},
	-- Aplastamiento lento que rompe la guardia: se esquiva o se hace parry.
	{
		Id = "EnemyCrush",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 1,
		Cooldown = 5,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.45,
				Damage = 26,
				PostureDamage = 35,
				Hitbox = CRUSH_HITBOX,
				GuardBreak = true,
				Knockback = 50,
			},
		},
		Animation = "Enemy.Crush",
	},

	-- Movimiento (§18, §28): el mismo motor con distintos datos. Sonido,
	-- Hirenkyaku, Utsusemi... serán más definiciones como estas.

	-- Paso rápido de quien aún no tiene raza: corto, en el suelo, con stamina.
	{
		Id = "Step",
		State = "Dashing",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.3,
		Cooldown = 1.2,
		Cost = { Resource = "Stamina", Amount = 15 },
		Movement = { Distance = 16, Duration = 0.2, Direction = "InputOrForward", AllowAir = false },
		Animation = "Combat.Dash",
	},
	-- GAMEPLAY ADAPTATION de Shunpo (paso instantáneo): largo, también en el aire, con Reiatsu.
	{
		Id = "Shunpo",
		State = "Dashing",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.3,
		Cooldown = 1,
		Cost = { Resource = "Reiatsu", Amount = 15 },
		Movement = { Distance = 28, Duration = 0.2, Direction = "InputOrForward", AllowAir = true },
		Animation = "Combat.Dash",
	},

	-- Kido (§26): hechizos con el mismo framework. Hado = ataque, Bakudo = control.

	-- Hado #4 Byakurai: rayo recto de largo alcance.
	{
		Id = "Byakurai",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.7,
		Cooldown = 6,
		Cost = { Resource = "Reiatsu", Amount = 25 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.35,
				Damage = 22,
				PostureDamage = 12,
				Hitbox = BEAM_HITBOX,
			},
		},
		Animation = "Cast.Point",
	},
	-- Bakudo #1 Sai: inmoviliza a un objetivo cercano. Ignora la guardia.
	{
		Id = "Sai",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.6,
		Cooldown = 10,
		Cost = { Resource = "Reiatsu", Amount = 20 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.3,
				Damage = 0,
				PostureDamage = 0,
				Hitbox = BIND_HITBOX,
				Stun = 2,
				Unblockable = true,
			},
		},
		Animation = "Cast.Bind",
	},
}

return Abilities
