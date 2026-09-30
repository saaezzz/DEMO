--!strict

-- Clips de animación procedural (D-022): poses por keyframe como ángulos en
-- grados por articulación. Lógica pura: muestrear un clip no toca instancias,
-- ProceduralAnimator se encarga de aplicarlo a los Motor6D.

-- {X, Y, Z} en grados, rotación sobre el C0 original de la articulación.
export type JointAngles = { number }
-- Nombre del Motor6D (R15) → ángulos. Una articulación ausente está en reposo.
export type Pose = { [string]: JointAngles }

export type Easing = "Linear" | "QuadIn" | "QuadOut" | "SineInOut" | "BackOut"

export type Keyframe = {
	Time: number,
	Pose: Pose,
	-- Curva del tramo que llega a este keyframe (Linear si falta).
	Easing: Easing?,
}

export type Clip = {
	-- Ordenados por Time. Antes del primero se parte de la pose de reposo.
	Keyframes: { Keyframe },
	-- true: mantiene la última pose hasta que se detenga (guardia, aturdimiento).
	Hold: boolean,
}

local BACK_OVERSHOOT = 1.70158

local EASINGS: { [Easing]: (number) -> number } = {
	Linear = function(t: number): number
		return t
	end,
	QuadIn = function(t: number): number
		return t * t
	end,
	QuadOut = function(t: number): number
		return 1 - (1 - t) * (1 - t)
	end,
	SineInOut = function(t: number): number
		return -(math.cos(math.pi * t) - 1) / 2
	end,
	BackOut = function(t: number): number
		local c3 = BACK_OVERSHOOT + 1
		return 1 + c3 * (t - 1) ^ 3 + BACK_OVERSHOOT * (t - 1) ^ 2
	end,
}

local NEUTRAL: Keyframe = { Time = 0, Pose = {} }
local ZERO: JointAngles = { 0, 0, 0 }

local ProceduralClip = {}

function ProceduralClip.Ease(easing: Easing, t: number): number
	return EASINGS[easing](math.clamp(t, 0, 1))
end

function ProceduralClip.GetDuration(clip: Clip): number
	local last = clip.Keyframes[#clip.Keyframes]
	return if last ~= nil then last.Time else 0
end

function ProceduralClip.IsFinished(clip: Clip, elapsed: number): boolean
	return not clip.Hold and elapsed >= ProceduralClip.GetDuration(clip)
end

local function blendPoses(from: Pose, to: Pose, alpha: number): Pose
	local result: Pose = {}
	for joint, target in to do
		local origin = from[joint] or ZERO
		result[joint] = {
			origin[1] + (target[1] - origin[1]) * alpha,
			origin[2] + (target[2] - origin[2]) * alpha,
			origin[3] + (target[3] - origin[3]) * alpha,
		}
	end
	-- Articulaciones que solo están en el origen vuelven a reposo.
	for joint, origin in from do
		if to[joint] == nil then
			local keep = 1 - alpha
			result[joint] = { origin[1] * keep, origin[2] * keep, origin[3] * keep }
		end
	end
	return result
end

-- Pose del clip en el instante `elapsed` (segundos desde que empezó).
function ProceduralClip.Sample(clip: Clip, elapsed: number): Pose
	local previous = NEUTRAL
	for _, keyframe in clip.Keyframes do
		if elapsed < keyframe.Time then
			local span = keyframe.Time - previous.Time
			local linear = if span > 0 then (elapsed - previous.Time) / span else 1
			local alpha = ProceduralClip.Ease(keyframe.Easing or "Linear", linear)
			return blendPoses(previous.Pose, keyframe.Pose, alpha)
		end
		previous = keyframe
	end
	return blendPoses(previous.Pose, previous.Pose, 1)
end

return ProceduralClip
