local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local ProceduralClip = require(Client.Animation.ProceduralClip)

local clip = {
	Hold = false,
	Keyframes = {
		{ Time = 1, Pose = { Arm = { 90, 0, 0 } } },
		{ Time = 2, Pose = { Leg = { 0, 40, 0 } } },
	},
}

return {
	["las curvas empiezan en 0 y terminan en 1"] = function()
		for _, easing in { "Linear", "QuadIn", "QuadOut", "SineInOut", "BackOut" } do
			expect(ProceduralClip.Ease(easing, 0)).toBeCloseTo(0)
			expect(ProceduralClip.Ease(easing, 1)).toBeCloseTo(1)
		end
	end,

	["Ease limita t a [0, 1]"] = function()
		expect(ProceduralClip.Ease("Linear", 2)).toBe(1)
		expect(ProceduralClip.Ease("Linear", -1)).toBe(0)
	end,

	["antes del primer keyframe parte de la pose de reposo"] = function()
		local pose = ProceduralClip.Sample(clip, 0.5)
		expect(pose.Arm[1]).toBeCloseTo(45)
		expect(pose.Arm[2]).toBeCloseTo(0)
	end,

	["entre keyframes mezcla y devuelve a reposo lo que desaparece"] = function()
		local pose = ProceduralClip.Sample(clip, 1.5)
		expect(pose.Arm[1]).toBeCloseTo(45)
		expect(pose.Leg[2]).toBeCloseTo(20)
	end,

	["tras el último keyframe mantiene su pose"] = function()
		local pose = ProceduralClip.Sample(clip, 5)
		expect(pose.Arm).toBeNil()
		expect(pose.Leg[2]).toBeCloseTo(40)
	end,

	["un clip sin Hold termina en su duración; con Hold no termina"] = function()
		expect(ProceduralClip.GetDuration(clip)).toBe(2)
		expect(ProceduralClip.IsFinished(clip, 1.9)).toBe(false)
		expect(ProceduralClip.IsFinished(clip, 2)).toBe(true)
		local held = { Hold = true, Keyframes = clip.Keyframes }
		expect(ProceduralClip.IsFinished(held, 100)).toBe(false)
	end,

	["aplica la curva del tramo que llega al keyframe"] = function()
		local eased = {
			Hold = false,
			Keyframes = { { Time = 1, Easing = "QuadIn", Pose = { Arm = { 100, 0, 0 } } } },
		}
		expect(ProceduralClip.Sample(eased, 0.5).Arm[1]).toBeCloseTo(25)
	end,
}
