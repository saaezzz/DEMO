--!strict

-- Animaciones procedurales provisionales (D-022), con las mismas claves que
-- Content/Animations. Solo se usan mientras el asset real no tiene AssetId;
-- al subirlo, el asset las sustituye sin tocar código.
--
-- Ejes sobre el C0 de cada Motor6D R15 (grados):
--   Hombro/cadera X+ = extremidad hacia delante; hombro derecho Z+ = hacia fuera.
--   Waist X- = inclinarse hacia delante; Y+ = girar el torso a la izquierda.
--   Neck X+ = mirar arriba.

local ProceduralClip = require(script.Parent.ProceduralClip)

type Clip = ProceduralClip.Clip
type Pose = ProceduralClip.Pose

local SLASH_STRIKE: Pose = {
	RightShoulder = { 70, 0, -45 },
	RightElbow = { 5, 0, 0 },
	LeftShoulder = { -20, 0, -15 },
	Waist = { -10, 40, 0 },
	Neck = { 0, -20, 0 },
}

local DASH_LEAN: Pose = {
	Waist = { -28, 0, 0 },
	Neck = { 20, 0, 0 },
	RightShoulder = { -50, 0, 15 },
	LeftShoulder = { -50, 0, -15 },
	RightHip = { 20, 0, 0 },
	LeftHip = { -25, 0, 0 },
}

local DODGE_CROUCH: Pose = {
	Waist = { -22, 0, 0 },
	Neck = { 18, 0, 0 },
	RightShoulder = { 45, 0, -20 },
	LeftShoulder = { 45, 0, 20 },
	RightElbow = { 50, 0, 0 },
	LeftElbow = { 50, 0, 0 },
	RightHip = { 30, 0, 0 },
	LeftHip = { -10, 0, 0 },
}

export type StrikeOptions = {
	WindupTime: number,
	Windup: Pose,
	StrikeTime: number,
	Strike: Pose,
	-- Mantiene el golpe hasta aquí y después vuelve a reposo en EndTime.
	HoldUntil: number,
	EndTime: number,
}

-- Golpe con arma: preparación, impacto rápido, pausa y recuperación.
local function strike(options: StrikeOptions): Clip
	return {
		Hold = false,
		Keyframes = {
			{ Time = options.WindupTime, Easing = "QuadOut", Pose = options.Windup },
			{ Time = options.StrikeTime, Easing = "QuadIn", Pose = options.Strike },
			{ Time = options.HoldUntil, Pose = options.Strike },
			{ Time = options.EndTime, Easing = "SineInOut", Pose = {} },
		},
	}
end

local PlaceholderAnimations: { [string]: Clip } = {
	-- Tajo de derecha a izquierda.
	["Combat.Slash1"] = strike({
		WindupTime = 0.1,
		Windup = {
			RightShoulder = { 140, 0, 45 },
			RightElbow = { 30, 0, 0 },
			LeftShoulder = { 30, 0, -20 },
			Waist = { 0, -35, 0 },
			Neck = { 0, 20, 0 },
		},
		StrikeTime = 0.22,
		Strike = SLASH_STRIKE,
		HoldUntil = 0.34,
		EndTime = 0.5,
	}),

	-- Revés de izquierda a derecha.
	["Combat.Slash2"] = strike({
		WindupTime = 0.1,
		Windup = {
			RightShoulder = { 95, 0, -70 },
			RightElbow = { 60, 0, 0 },
			Waist = { 0, 35, 0 },
			Neck = { 0, -15, 0 },
		},
		StrikeTime = 0.22,
		Strike = {
			RightShoulder = { 85, 0, 60 },
			RightElbow = { 5, 0, 0 },
			LeftShoulder = { 10, 0, -25 },
			Waist = { -8, -40, 0 },
			Neck = { 0, 20, 0 },
		},
		HoldUntil = 0.34,
		EndTime = 0.5,
	}),

	-- Remate vertical de arriba abajo.
	["Combat.Slash3"] = strike({
		WindupTime = 0.18,
		Windup = {
			RightShoulder = { 170, 0, 10 },
			LeftShoulder = { 150, 0, -10 },
			RightElbow = { 20, 0, 0 },
			LeftElbow = { 20, 0, 0 },
			Waist = { 12, 0, 0 },
			Neck = { -10, 0, 0 },
		},
		StrikeTime = 0.3,
		Strike = {
			RightShoulder = { 40, 0, 0 },
			LeftShoulder = { 35, 0, 0 },
			Waist = { -25, 0, 0 },
			Neck = { 15, 0, 0 },
			RightHip = { 20, 0, 0 },
		},
		HoldUntil = 0.45,
		EndTime = 0.68,
	}),

	-- Pesado: carga larga y exagerada para que se pueda leer y hacer parry (D-023).
	["Combat.HeavySlash"] = strike({
		WindupTime = 0.4,
		Windup = {
			RightShoulder = { 175, 0, 15 },
			LeftShoulder = { 160, 0, -15 },
			RightElbow = { 30, 0, 0 },
			LeftElbow = { 30, 0, 0 },
			Waist = { 18, -25, 0 },
			Neck = { -12, 15, 0 },
			LeftHip = { 25, 0, 0 },
		},
		StrikeTime = 0.5,
		Strike = {
			RightShoulder = { 20, 0, -10 },
			LeftShoulder = { 20, 0, 10 },
			Waist = { -35, 10, 0 },
			Neck = { 25, 0, 0 },
			RightHip = { 30, 0, 0 },
			LeftHip = { -15, 0, 0 },
		},
		HoldUntil = 0.68,
		EndTime = 0.92,
	}),

	-- Enemigos -------------------------------------------------------------

	-- Zarpazo con una mano.
	["Enemy.Swipe"] = strike({
		WindupTime = 0.18,
		Windup = {
			RightShoulder = { 120, 0, 60 },
			RightElbow = { 40, 0, 0 },
			Waist = { 0, -30, 0 },
		},
		StrikeTime = 0.27,
		Strike = {
			RightShoulder = { 60, 0, -50 },
			RightElbow = { 10, 0, 0 },
			Waist = { -10, 35, 0 },
		},
		HoldUntil = 0.38,
		EndTime = 0.6,
	}),

	-- Agacharse y saltar con las dos garras por delante.
	["Enemy.Lunge"] = strike({
		WindupTime = 0.15,
		Windup = {
			Waist = { 18, 0, 0 },
			RightShoulder = { -30, 0, 20 },
			LeftShoulder = { -30, 0, -20 },
			RightHip = { 30, 0, 0 },
			LeftHip = { 30, 0, 0 },
		},
		StrikeTime = 0.3,
		Strike = {
			Waist = { -30, 0, 0 },
			Neck = { 20, 0, 0 },
			RightShoulder = { 100, 0, -10 },
			LeftShoulder = { 100, 0, 10 },
		},
		HoldUntil = 0.45,
		EndTime = 0.7,
	}),

	-- Brazos muy arriba (aviso claro) y golpe al suelo.
	["Enemy.Crush"] = strike({
		WindupTime = 0.35,
		Windup = {
			RightShoulder = { 170, 0, 15 },
			LeftShoulder = { 170, 0, -15 },
			Waist = { 15, 0, 0 },
			Neck = { -15, 0, 0 },
		},
		StrikeTime = 0.45,
		Strike = {
			RightShoulder = { 15, 0, 5 },
			LeftShoulder = { 15, 0, -5 },
			Waist = { -40, 0, 0 },
			Neck = { 25, 0, 0 },
		},
		HoldUntil = 0.7,
		EndTime = 1,
	}),

	-- Paso rápido agachado, en guardia.
	["Combat.Dodge"] = {
		Hold = false,
		Keyframes = {
			{ Time = 0.06, Easing = "QuadOut", Pose = DODGE_CROUCH },
			{ Time = 0.25, Pose = DODGE_CROUCH },
			{ Time = 0.42, Easing = "SineInOut", Pose = {} },
		},
	},

	["Combat.Block"] = {
		Hold = true,
		Keyframes = {
			{
				Time = 0.12,
				Easing = "BackOut",
				Pose = {
					RightShoulder = { 95, 0, -40 },
					LeftShoulder = { 95, 0, 40 },
					RightElbow = { 55, 0, 0 },
					LeftElbow = { 55, 0, 0 },
					Waist = { -8, 0, 0 },
					Neck = { 8, 0, 0 },
				},
			},
		},
	},

	["Combat.Dash"] = {
		Hold = false,
		Keyframes = {
			{ Time = 0.08, Easing = "QuadOut", Pose = DASH_LEAN },
			{ Time = 0.32, Pose = DASH_LEAN },
			{ Time = 0.48, Easing = "SineInOut", Pose = {} },
		},
	},

	["Reaction.Stun"] = {
		Hold = true,
		Keyframes = {
			{
				Time = 0.1,
				Easing = "BackOut",
				Pose = {
					Waist = { 18, -12, 0 },
					Neck = { 25, 10, 0 },
					RightShoulder = { 25, 0, 35 },
					LeftShoulder = { 25, 0, -35 },
					RightElbow = { 20, 0, 0 },
					LeftElbow = { 20, 0, 0 },
				},
			},
			{
				Time = 0.4,
				Easing = "SineInOut",
				Pose = {
					Waist = { 14, 8, 0 },
					Neck = { 18, -8, 0 },
					RightShoulder = { 20, 0, 30 },
					LeftShoulder = { 20, 0, -30 },
					RightElbow = { 15, 0, 0 },
					LeftElbow = { 15, 0, 0 },
				},
			},
		},
	},
}

return PlaceholderAnimations
