--!strict

-- Animaciones de los personajes (D-022):
-- - Locomoción: sustituye las del script Animate por defecto del personaje propio.
-- - Habilidades: cada vez que sube ActionSeq se reproduce ActionAnimation (D-025).
-- - Estados sin habilidad (guardia, aturdimiento): Content/StateAnimations.
-- Si la animación tiene asset subido, el dueño la reproduce en su Animator
-- (replica sola a los demás); si no, cada cliente muestra su placeholder procedural.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationRegistry = require(ReplicatedStorage.Shared.Modules.AnimationRegistry)
local StateAnimations = require(ReplicatedStorage.Shared.Content.StateAnimations)
local LocomotionAnimations = require(ReplicatedStorage.Shared.Content.LocomotionAnimations)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CharacterWatcher = require(script.Parent.Parent.Utils.CharacterWatcher)
local PlaceholderAnimations = require(script.Parent.Parent.Animation.PlaceholderAnimations)
local ProceduralAnimator = require(script.Parent.Parent.Animation.ProceduralAnimator)

type ProceduralAnimator = ProceduralAnimator.ProceduralAnimator

local PARTS_TIMEOUT_SECONDS = 5

type Rig = {
	Model: Model,
	IsLocal: boolean,
	Animator: Animator?,
	Tracks: { [string]: AnimationTrack },
	CurrentTrack: AnimationTrack?,
	Procedural: ProceduralAnimator?,
}

local log = Logger.new("CharacterAnimation")
local localPlayer = Players.LocalPlayer
-- Rigs con animación procedural en curso; se recorren cada frame.
local activeRigs: { [Rig]: boolean } = {}

local function getTrack(rig: Rig, key: string, contentId: string): AnimationTrack?
	local cached: AnimationTrack? = rig.Tracks[key]
	if cached ~= nil then
		return cached
	end
	local animator = rig.Animator
	local definition = AnimationRegistry.Get(key)
	if animator == nil or definition == nil then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = contentId
	local track = animator:LoadAnimation(animation)
	track.Priority = AnimationRegistry.GetEnumPriority(definition)
	track.Looped = definition.Looped
	rig.Tracks[key] = track
	return track
end

-- Al salir de un estado, las animaciones en bucle se cortan; las de una sola
-- pasada (un tajo) terminan su recuperación.
local function stopHeld(rig: Rig): ()
	local track = rig.CurrentTrack
	if track ~= nil and track.Looped then
		track:Stop(0.15)
		rig.CurrentTrack = nil
	end
	local procedural = rig.Procedural
	if procedural ~= nil and procedural:IsHolding() then
		procedural:Stop()
	end
end

local function playKey(rig: Rig, key: string): ()
	local contentId = AnimationRegistry.GetContentId(key)
	if contentId ~= nil then
		-- Con asset real solo anima el dueño; su Animator replica al resto.
		if not rig.IsLocal then
			return
		end
		local track = getTrack(rig, key, contentId)
		if track ~= nil then
			if rig.CurrentTrack ~= nil and rig.CurrentTrack ~= track then
				rig.CurrentTrack:Stop(0.1)
			end
			rig.CurrentTrack = track
			track:Play(0.1)
		end
		return
	end

	local clip = PlaceholderAnimations[key]
	if clip == nil then
		return
	end
	-- Se crea al primer uso, con el rig ya montado.
	local procedural: ProceduralAnimator = rig.Procedural or ProceduralAnimator.new(rig.Model)
	rig.Procedural = procedural
	procedural:Play(clip)
	activeRigs[rig] = true
end

local function onStateChanged(rig: Rig): ()
	local state = rig.Model:GetAttribute(ReplicatedAttributes.STATE)
	local key = if typeof(state) == "string" then StateAnimations[state :: any] else nil
	if key == nil then
		stopHeld(rig)
	else
		playKey(rig, key)
	end
end

local function onActionStarted(rig: Rig): ()
	local key = rig.Model:GetAttribute(ReplicatedAttributes.ACTION_ANIMATION)
	if typeof(key) == "string" then
		playKey(rig, key)
	end
end

-- Sustituye los AnimationId del script Animate por defecto. El Animate
-- detecta el cambio y usa las nuevas en su siguiente reproducción.
local function applyLocomotion(model: Model, humanoid: Humanoid): ()
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		log:Warn("La locomoción provisional requiere avatares R15 (Game Settings → Avatar)")
		return
	end
	local animate = model:WaitForChild("Animate", PARTS_TIMEOUT_SECONDS)
	if animate == nil then
		return
	end

	for folderName, values in LocomotionAnimations do
		local folder = animate:FindFirstChild(folderName)
		for valueName, key in values do
			local animation = if folder ~= nil then folder:FindFirstChild(valueName) else nil
			local contentId = AnimationRegistry.GetContentId(key)
			if animation ~= nil and animation:IsA("Animation") and contentId ~= nil then
				animation.AnimationId = contentId
			end
		end
	end
end

local function onCharacter(player: Player?, model: Model): CharacterWatcher.Cleanup?
	local humanoid = model:WaitForChild("Humanoid", PARTS_TIMEOUT_SECONDS) :: Humanoid?
	if humanoid == nil then
		return nil
	end

	local isLocal = player == localPlayer
	if isLocal then
		applyLocomotion(model, humanoid)
	end

	local rig: Rig = {
		Model = model,
		IsLocal = isLocal,
		Animator = if isLocal then humanoid:WaitForChild("Animator", PARTS_TIMEOUT_SECONDS) :: Animator? else nil,
		Tracks = {},
		CurrentTrack = nil,
		Procedural = nil,
	}

	local connections = {
		model:GetAttributeChangedSignal(ReplicatedAttributes.STATE):Connect(function()
			onStateChanged(rig)
		end),
		model:GetAttributeChangedSignal(ReplicatedAttributes.ACTION_SEQ):Connect(function()
			onActionStarted(rig)
		end),
	}
	onStateChanged(rig)

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		activeRigs[rig] = nil
		if rig.Procedural ~= nil then
			rig.Procedural:Destroy()
		end
	end
end

local CharacterAnimationController = {
	Name = "CharacterAnimationController",
}

function CharacterAnimationController:Start(): ()
	CharacterWatcher.Observe(onCharacter)

	RunService.Heartbeat:Connect(function(deltaSeconds: number)
		for rig in activeRigs do
			local procedural = rig.Procedural
			if procedural == nil or not procedural:Step(deltaSeconds) then
				activeRigs[rig] = nil
			end
		end
	end)
end

return CharacterAnimationController
