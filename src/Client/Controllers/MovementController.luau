--!strict

-- Aplica el desplazamiento de una habilidad de movimiento que el servidor ha
-- aceptado (D-026). El cliente es dueño de la física de su personaje, así que
-- el impulso se aplica aquí para que responda sin esperar a la replicación.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local VelocityImpulse = require(ReplicatedStorage.Shared.Modules.VelocityImpulse)

type MovementSpec = GameTypes.MovementSpec

local MOVING_THRESHOLD = 0.1

local player = Players.LocalPlayer

local function flatten(vector: Vector3): Vector3?
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return if flat.Magnitude > 1e-3 then flat.Unit else nil
end

local function resolveDirection(spec: MovementSpec, humanoid: Humanoid, rootPart: BasePart): Vector3?
	local forward = flatten(rootPart.CFrame.LookVector)
	if forward == nil then
		return nil
	end
	local input = if humanoid.MoveDirection.Magnitude > MOVING_THRESHOLD then flatten(humanoid.MoveDirection) else nil

	if spec.Direction == "InputOrForward" then
		return input or forward
	elseif spec.Direction == "InputOrBackward" then
		return input or -forward
	elseif spec.Direction == "Forward" then
		return forward
	end
	return -forward
end

local MovementController = {
	Name = "MovementController",
}

function MovementController:Apply(spec: MovementSpec): ()
	local model = player.Character
	local humanoid = if model ~= nil then model:FindFirstChildOfClass("Humanoid") else nil
	local rootPart = if model ~= nil then model:FindFirstChild("HumanoidRootPart") else nil
	if humanoid == nil or rootPart == nil or not rootPart:IsA("BasePart") or spec.Duration <= 0 then
		return
	end

	local direction = resolveDirection(spec, humanoid, rootPart)
	if direction ~= nil then
		VelocityImpulse.Apply(rootPart, direction * (spec.Distance / spec.Duration), spec.Duration)
	end
end

return MovementController
