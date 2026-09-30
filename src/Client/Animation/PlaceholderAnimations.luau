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

local PlaceholderAnimations: { [string]: Clip } = {
	["Combat.BasicSlash"] = {
		Hold = false,
		Keyframes = {
			{
				Time = 0.1,
				Easing = "QuadOut",
				Pose = {
					RightShoulder = { 140, 0, 45 },
					RightElbow = { 30, 0, 0 },
					LeftShoulder = { 30, 0, -20 },
					Waist = { 0, -35, 0 },
					Neck = { 0, 20, 0 },
				},
			},
			{ Time = 0.22, Easing = "QuadIn", Pose = SLASH_STRIKE },
			{ Time = 0.34, Pose = SLASH_STRIKE },
			{ Time = 0.55, Easing = "SineInOut", Pose = {} },
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
