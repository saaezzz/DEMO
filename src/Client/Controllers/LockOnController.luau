--!strict

-- Fijado de objetivo y cámara de combate (§50, D-032). Opcional: el juego se
-- juega igual sin él.
-- - Pulsar: fija el enemigo más centrado en pantalla, o pasa al siguiente.
-- - Mantener: suelta el objetivo.
-- Con objetivo, el personaje lo encara y la cámara encuadra a ambos. Se suelta
-- solo si el objetivo muere, desaparece o se aleja demasiado.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

local InputController = require(script.Parent.InputController)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type ActionName = InputBindings.ActionName

local RENDER_STEP_NAME = "LockOnCamera"
-- Distancia máxima para fijar y para mantener el objetivo.
local LOCK_RANGE = 70
local KEEP_RANGE = 90
-- Mantener la tecla más de esto suelta el objetivo.
local RELEASE_HOLD_SECONDS = 0.35
-- Cámara: distancia detrás del jugador, altura y suavizado.
local CAMERA_DISTANCE = 13
local CAMERA_HEIGHT = 5
local CAMERA_SMOOTHING = 12

local player = Players.LocalPlayer
local target: Model? = nil
local marker: BillboardGui? = nil
local cameraCFrame: CFrame? = nil
local pressedAt: number? = nil

local LockOnController = {
	Name = "LockOnController",
	-- (modelo o nil) al fijar, cambiar o soltar el objetivo.
	TargetChanged = Signal.new() :: Signal.Signal<Model?>,
}

local function getRoot(model: Model?): BasePart?
	local root = if model ~= nil then model:FindFirstChild("HumanoidRootPart") else nil
	return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function isAlive(model: Model): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and model:IsDescendantOf(Workspace)
end

-- Candidatos ordenados de más a menos centrados en pantalla (y cercanos).
local function getCandidates(): { Model }
	local camera = Workspace.CurrentCamera
	local myRoot = getRoot(player.Character)
	if camera == nil or myRoot == nil then
		return {}
	end
	local scored: { { Model: Model, Score: number } } = {}
	for _, instance in CollectionService:GetTagged(ReplicatedAttributes.NPC_TAG) do
		local root = if instance:IsA("Model") then getRoot(instance) else nil
		if root ~= nil and isAlive(instance :: Model) then
			local offset = root.Position - myRoot.Position
			local distance = offset.Magnitude
			if distance <= LOCK_RANGE and distance > 0 then
				local alignment = camera.CFrame.LookVector:Dot(offset.Unit)
				-- Lo que está detrás de la cámara no cuenta.
				if alignment > 0 then
					table.insert(scored, { Model = instance :: Model, Score = alignment - distance / (LOCK_RANGE * 4) })
				end
			end
		end
	end
	table.sort(scored, function(a, b)
		return a.Score > b.Score
	end)
	local result: { Model } = {}
	for _, entry in scored do
		table.insert(result, entry.Model)
	end
	return result
end

local function setHumanoidAutoRotate(enabled: boolean): ()
	local model = player.Character
	local humanoid = if model ~= nil then model:FindFirstChildOfClass("Humanoid") else nil
	if humanoid ~= nil then
		humanoid.AutoRotate = enabled
	end
end

local function setTarget(newTarget: Model?): ()
	if newTarget == target then
		return
	end
	target = newTarget
	if marker ~= nil then
		marker:Destroy()
		marker = nil
	end

	if newTarget ~= nil then
		local head = newTarget:FindFirstChild("Head")
		local billboard = UIUtil.create("BillboardGui", {
			Name = "LockOnMarker",
			Adornee = if head ~= nil then head else getRoot(newTarget),
			AlwaysOnTop = true,
			LightInfluence = 0,
			Size = UDim2.fromOffset(40, 40),
			StudsOffset = Vector3.new(0, 3.2, 0),
			Parent = player:FindFirstChildOfClass("PlayerGui"),
		})
		UIUtil.label({
			Text = "▼",
			TextSize = 32,
			TextColor3 = Theme.Colors.Telegraph,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = billboard,
		})
		marker = billboard
		local camera = Workspace.CurrentCamera
		cameraCFrame = if cameraCFrame == nil and camera ~= nil then camera.CFrame else cameraCFrame
	else
		cameraCFrame = nil
	end
	setHumanoidAutoRotate(newTarget == nil)
	LockOnController.TargetChanged:Fire(newTarget)
end

local function lockOrCycle(): ()
	local candidates = getCandidates()
	if target == nil then
		setTarget(candidates[1])
		return
	end
	-- El siguiente después del actual; si no hay otro, se queda con el actual.
	for index, candidate in candidates do
		if candidate == target then
			local nextCandidate = candidates[index % #candidates + 1]
			setTarget(nextCandidate)
			return
		end
	end
	setTarget(candidates[1] or target)
end

local function onRenderStep(deltaSeconds: number): ()
	local currentTarget = target
	if currentTarget == nil then
		return
	end
	local myRoot = getRoot(player.Character)
	local targetRoot = getRoot(currentTarget)
	if myRoot == nil or targetRoot == nil or not isAlive(currentTarget) then
		setTarget(nil)
		return
	end
	local offset = targetRoot.Position - myRoot.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if offset.Magnitude > KEEP_RANGE then
		setTarget(nil)
		return
	end
	if flat.Magnitude < 1e-3 then
		return
	end

	-- El personaje encara al objetivo (el cliente es dueño de su física).
	myRoot.CFrame = CFrame.lookAt(myRoot.Position, myRoot.Position + flat)

	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local direction = flat.Unit
	local cameraPosition = myRoot.Position - direction * CAMERA_DISTANCE + Vector3.new(0, CAMERA_HEIGHT, 0)
	local focus = myRoot.Position:Lerp(targetRoot.Position, 0.5)
	local desired = CFrame.lookAt(cameraPosition, focus)
	local alpha = 1 - math.exp(-CAMERA_SMOOTHING * deltaSeconds)
	local smoothed = (cameraCFrame or camera.CFrame):Lerp(desired, alpha)
	cameraCFrame = smoothed
	camera.CFrame = smoothed
end

function LockOnController:Start(): ()
	InputController.ActionBegan:Connect(function(action: ActionName)
		if action == "LockOn" then
			pressedAt = os.clock()
		end
	end)
	InputController.ActionEnded:Connect(function(action: ActionName)
		if action ~= "LockOn" then
			return
		end
		local held = if pressedAt ~= nil then os.clock() - pressedAt else 0
		pressedAt = nil
		if held >= RELEASE_HOLD_SECONDS then
			setTarget(nil)
		else
			lockOrCycle()
		end
	end)
	player.CharacterAdded:Connect(function()
		setTarget(nil)
	end)

	-- Justo después de la cámara de Roblox, para ajustar su resultado.
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, onRenderStep)
end

function LockOnController:GetTarget(): Model?
	return target
end

return LockOnController
