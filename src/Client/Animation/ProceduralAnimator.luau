--!strict

-- Aplica clips procedurales (ProceduralClip) a los Motor6D de un modelo R15
-- (D-022). Solo toca el C0, así que se suma a las animaciones normales del
-- Animator. Es local a cada cliente: el C0 no replica.

local ProceduralClip = require(script.Parent.ProceduralClip)

type Clip = ProceduralClip.Clip

-- Velocidad de la mezcla hacia la pose objetivo (mayor = más rápida).
local BLEND_SPEED = 30
local SETTLE_EPSILON = 1e-3

local ProceduralAnimator = {}
ProceduralAnimator.__index = ProceduralAnimator

type ProceduralAnimatorData = {
	_joints: { [string]: Motor6D },
	_baseC0: { [string]: CFrame },
	_offsets: { [string]: CFrame },
	_clip: Clip?,
	_elapsed: number,
	_active: boolean,
}

export type ProceduralAnimator = typeof(setmetatable({} :: ProceduralAnimatorData, ProceduralAnimator))

function ProceduralAnimator.new(model: Model): ProceduralAnimator
	local joints: { [string]: Motor6D } = {}
	local baseC0: { [string]: CFrame } = {}
	local offsets: { [string]: CFrame } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") then
			joints[descendant.Name] = descendant
			baseC0[descendant.Name] = descendant.C0
			offsets[descendant.Name] = CFrame.identity
		end
	end

	return setmetatable({
		_joints = joints,
		_baseC0 = baseC0,
		_offsets = offsets,
		_clip = nil,
		_elapsed = 0,
		_active = false,
	}, ProceduralAnimator)
end

function ProceduralAnimator.Play(self: ProceduralAnimator, clip: Clip): ()
	self._clip = clip
	self._elapsed = 0
	self._active = true
end

-- Vuelve a reposo con mezcla suave.
function ProceduralAnimator.Stop(self: ProceduralAnimator): ()
	self._clip = nil
end

function ProceduralAnimator.IsHolding(self: ProceduralAnimator): boolean
	local clip = self._clip
	return clip ~= nil and clip.Hold
end

-- Avanza la animación. Devuelve false cuando ya está en reposo y no necesita más pasos.
function ProceduralAnimator.Step(self: ProceduralAnimator, deltaSeconds: number): boolean
	if not self._active then
		return false
	end

	local target = {}
	local clip = self._clip
	if clip ~= nil then
		self._elapsed += deltaSeconds
		target = ProceduralClip.Sample(clip, self._elapsed)
		if ProceduralClip.IsFinished(clip, self._elapsed) then
			self._clip = nil
		end
	end

	local alpha = 1 - math.exp(-BLEND_SPEED * deltaSeconds)
	local settled = self._clip == nil
	for name, joint in self._joints do
		local angles = target[name]
		local goal = if angles ~= nil
			then CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
			else CFrame.identity
		local offset = self._offsets[name]:Lerp(goal, alpha)
		if settled and not offset:FuzzyEq(CFrame.identity, SETTLE_EPSILON) then
			settled = false
		end
		self._offsets[name] = offset
		-- La articulación puede haberse roto (muerte) o destruido.
		if joint.Parent ~= nil then
			joint.C0 = self._baseC0[name] * offset
		end
	end

	if settled then
		self:_reset()
		self._active = false
	end
	return self._active
end

function ProceduralAnimator._reset(self: ProceduralAnimator): ()
	for name, joint in self._joints do
		self._offsets[name] = CFrame.identity
		if joint.Parent ~= nil then
			joint.C0 = self._baseC0[name]
		end
	end
end

function ProceduralAnimator.Destroy(self: ProceduralAnimator): ()
	self._clip = nil
	self._active = false
	self:_reset()
end

return ProceduralAnimator
