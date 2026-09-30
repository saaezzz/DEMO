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

local BOSS_SWIPE_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(14, 8, 12),
	Offset = CFrame.new(0, 0, -7),
	MaxTargets = 0,
}

-- Esfera centrada en el jefe: el radio (14) debe coincidir con el AreaRadius del ataque.
local BOSS_SLAM_HITBOX: HitboxDefinition = {
	Shape = "Sphere",
	Size = Vector3.new(28, 28, 28),
	Offset = CFrame.identity,
	MaxTargets = 0,
}

local BOSS_CHARGE_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(9, 8, 10),
	Offset = CFrame.new(0, 0, -5),
	MaxTargets = 0,
}

-- Garras de un jugador Hollow: algo más cortas que una espada.
local PLAYER_CLAW_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(6, 5, 5.5),
	Offset = CFrame.new(0, 0, -3.5),
	MaxTargets = 4,
}

-- Mordisco a un único objetivo pegado al Hollow.
local DEVOUR_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(5, 6, 7),
	Offset = CFrame.new(0, 0, -4),
	MaxTargets = 1,
}

-- Cero: rayo ancho y muy largo que atraviesa a varios enemigos.
local CERO_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(5, 5, 50),
	Offset = CFrame.new(0, 0.5, -26),
	MaxTargets = 5,
}

-- Bala: proyectil rápido y fino a un único objetivo.
local BALA_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(2.5, 2.5, 35),
	Offset = CFrame.new(0, 0.5, -18.5),
	MaxTargets = 1,
}

-- Flecha: línea fina de largo alcance, a un único objetivo.
local ARROW_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(2.5, 3, 36),
	Offset = CFrame.new(0, 0.5, -19),
	MaxTargets = 1,
}

-- Flecha cargada: más gruesa y larga, atraviesa hasta tres enemigos.
local CHARGED_ARROW_HITBOX: HitboxDefinition = {
	Shape = "Box",
	Size = Vector3.new(3.5, 3.5, 45),
	Offset = CFrame.new(0, 0.5, -23.5),
	MaxTargets = 3,
}

-- Lluvia de flechas: círculo de radio 9 a 18 studs por delante.
local ARROW_RAIN_HITBOX: HitboxDefinition = {
	Shape = "Sphere",
	Size = Vector3.new(18, 18, 18),
	Offset = CFrame.new(0, 0, -18),
	MaxTargets = 0,
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

	-- Jefe (Content/Enemies: GreatHollow) --------------------------------------

	-- Zarpazo amplio delante.
	{
		Id = "BossSwipe",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.8,
		Cooldown = 0,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.3,
				Damage = 18,
				PostureDamage = 20,
				Hitbox = BOSS_SWIPE_HITBOX,
				Knockback = 40,
			},
		},
		Animation = "Enemy.Swipe",
	},
	-- Golpe al suelo en área alrededor del jefe: rompe la guardia. Se avisa con
	-- un círculo en el suelo (AreaRadius en Content/Enemies): hay que salir o hacer parry.
	{
		Id = "BossSlam",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 1.1,
		Cooldown = 6,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.35,
				Damage = 32,
				PostureDamage = 40,
				Hitbox = BOSS_SLAM_HITBOX,
				GuardBreak = true,
				Knockback = 60,
			},
		},
		Animation = "Enemy.Crush",
	},
	-- Carga en línea recta (fase 2+).
	{
		Id = "BossCharge",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.9,
		Cooldown = 7,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.3,
				Damage = 25,
				PostureDamage = 25,
				Hitbox = BOSS_CHARGE_HITBOX,
				Knockback = 70,
			},
		},
		Movement = { Distance = 30, Duration = 0.4, Direction = "Forward", AllowAir = false },
		Animation = "Enemy.Lunge",
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

	-- Hollow (§29) --------------------------------------------------------------

	-- Cadena M1 con garras: rápida, algo menos de alcance que la espada.
	{
		Id = "ClawSlash1",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.4,
		Cooldown = 0,
		Hits = {
			{ MarkerName = "Hit", StartTime = 0.18, Damage = 9, PostureDamage = 8, Hitbox = PLAYER_CLAW_HITBOX },
		},
		Animation = "Claw.Slash1",
	},
	{
		Id = "ClawSlash2",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.4,
		Cooldown = 0,
		Hits = {
			{ MarkerName = "Hit", StartTime = 0.18, Damage = 9, PostureDamage = 8, Hitbox = PLAYER_CLAW_HITBOX },
		},
		Animation = "Claw.Slash2",
	},
	{
		Id = "ClawSlash3",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.6,
		Cooldown = 0,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.28,
				Damage = 15,
				PostureDamage = 14,
				Hitbox = PLAYER_CLAW_HITBOX,
				Knockback = 50,
			},
		},
		Animation = "Claw.Slash3",
	},
	-- Desgarro con las dos garras: el pesado del Hollow.
	{
		Id = "ClawRend",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.85,
		Cooldown = 3,
		Cost = { Resource = "Stamina", Amount = 20 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.45,
				Damage = 22,
				PostureDamage = 30,
				Hitbox = HEAVY_HITBOX,
				GuardBreak = true,
				Knockback = 40,
			},
		},
		Animation = "Claw.Heavy",
	},
	-- Devorar: mordisco que cura lo que hace y remata a un enemigo debilitado
	-- (no a un jefe). Cada remate cuenta para la evolución (Content/Races).
	{
		Id = "Devour",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.9,
		Cooldown = 8,
		Cost = { Resource = "Reiatsu", Amount = 10 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.45,
				Damage = 12,
				PostureDamage = 0,
				Hitbox = DEVOUR_HITBOX,
				Unblockable = true,
				Drain = 1,
				Execute = { HealthFraction = 0.3, MaxDamage = 150 },
				KillStat = "Devoured",
			},
		},
		Animation = "Claw.Bite",
	},
	-- Cero: carga larga y rayo devastador.
	{
		Id = "Cero",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 1.2,
		Cooldown = 9,
		Cost = { Resource = "Reiatsu", Amount = 35 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.8,
				Damage = 30,
				PostureDamage = 25,
				Hitbox = CERO_HITBOX,
				Knockback = 45,
			},
		},
		Animation = "Cast.ChargedBeam",
	},
	-- Bala: disparo rápido y barato (se desbloquea con un hito).
	{
		Id = "Bala",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.6,
		Cooldown = 2,
		Cost = { Resource = "Reiatsu", Amount = 8 },
		Hits = {
			{ MarkerName = "Hit", StartTime = 0.35, Damage = 10, PostureDamage = 15, Hitbox = BALA_HITBOX },
		},
		Animation = "Cast.Point",
	},
	-- Hierro: piel endurecida, recibe un 30 % menos de daño durante 10 s.
	{
		Id = "Hierro",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.5,
		Cooldown = 18,
		Cost = { Resource = "Reiatsu", Amount = 25 },
		SelfModifier = { Id = "Hierro", Duration = 10, DamageTaken = 0.7 },
		Animation = "Cast.Focus",
	},
	-- Sonido: desplazamiento rápido del Hollow, también en el aire.
	{
		Id = "Sonido",
		State = "Dashing",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.3,
		Cooldown = 0.8,
		Cost = { Resource = "Reiatsu", Amount = 12 },
		Movement = { Distance = 26, Duration = 0.2, Direction = "InputOrForward", AllowAir = true },
		Animation = "Combat.Dash",
	},

	-- Quincy (§31) ---------------------------------------------------------------

	-- Cadena M1: tres flechas de Heilig Pfeil. Cada baja cuenta para sus hitos.
	{
		Id = "Pfeil1",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.45,
		Cooldown = 0,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.25,
				Damage = 7,
				PostureDamage = 5,
				Hitbox = ARROW_HITBOX,
				KillStat = "ArrowKills",
			},
		},
		Animation = "Bow.Shot",
	},
	{
		Id = "Pfeil2",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.45,
		Cooldown = 0,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.25,
				Damage = 7,
				PostureDamage = 5,
				Hitbox = ARROW_HITBOX,
				KillStat = "ArrowKills",
			},
		},
		Animation = "Bow.Shot",
	},
	{
		Id = "Pfeil3",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.55,
		Cooldown = 0,
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.25,
				Damage = 11,
				PostureDamage = 8,
				Hitbox = ARROW_HITBOX,
				Knockback = 30,
				KillStat = "ArrowKills",
			},
		},
		Animation = "Bow.Shot",
	},
	-- Flecha cargada: el pesado del Quincy. Rompe la guardia a distancia.
	{
		Id = "ChargedPfeil",
		State = "Attacking",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.95,
		Cooldown = 3,
		Cost = { Resource = "Stamina", Amount = 20 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.6,
				Damage = 22,
				PostureDamage = 25,
				Hitbox = CHARGED_ARROW_HITBOX,
				GuardBreak = true,
				Knockback = 40,
				KillStat = "ArrowKills",
			},
		},
		Animation = "Bow.Charged",
	},
	-- Licht Regen: lluvia de flechas sobre una zona por delante.
	{
		Id = "LichtRegen",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 1.1,
		Cooldown = 10,
		Cost = { Resource = "Reishi", Amount = 35 },
		Hits = {
			{
				MarkerName = "Hit",
				StartTime = 0.7,
				Damage = 18,
				PostureDamage = 15,
				Hitbox = ARROW_RAIN_HITBOX,
				KillStat = "ArrowKills",
			},
		},
		Animation = "Bow.Rain",
	},
	-- Blut Vene: sangre endurecida, recibe un 40 % menos de daño durante 8 s.
	{
		Id = "BlutVene",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.5,
		Cooldown = 20,
		Cost = { Resource = "Reishi", Amount = 30 },
		SelfModifier = { Id = "BlutVene", Duration = 8, DamageTaken = 0.6 },
		Animation = "Cast.Focus",
	},
	-- Blut Arterie: hace un 35 % más de daño durante 8 s (se desbloquea con un hito).
	{
		Id = "BlutArterie",
		State = "Casting",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.5,
		Cooldown = 20,
		Cost = { Resource = "Reishi", Amount = 30 },
		SelfModifier = { Id = "BlutArterie", Duration = 8, DamageDealt = 1.35 },
		Animation = "Cast.Focus",
	},
	-- Hirenkyaku: paso sobre Reishi, el más largo, también en el aire.
	{
		Id = "Hirenkyaku",
		State = "Dashing",
		Requirements = { StartStates = { "Idle" } },
		Duration = 0.3,
		Cooldown = 0.9,
		Cost = { Resource = "Reishi", Amount = 12 },
		Movement = { Distance = 32, Duration = 0.22, Direction = "InputOrForward", AllowAir = true },
		Animation = "Combat.Dash",
	},
}

return Abilities
