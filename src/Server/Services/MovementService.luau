--!strict

-- Movimiento de los personajes de jugador (§18, D-026): velocidad del
-- Humanoid según el estado, sprint con gasto de stamina y capa de locomoción
-- (D-024) a partir del movimiento real. Los desplazamientos de las
-- habilidades (dash, esquiva) los define AbilityDefinition.Movement.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

local MovementConfig = require(script.Parent.Parent.Config.MovementConfig)
local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)

type CombatEntity = CombatRegistry.CombatEntity
type LocomotionState = GameTypes.LocomotionState

-- Estados que ralentizan y estados que casi inmovilizan.
local SLOW_STATES = { "Attacking", "Blocking", "Parrying", "Casting", "Transforming" }
local STUN_STATES = { "Stunned", "Knocked", "Ragdolled", "Disabled" }

local function update(entity: CombatEntity, deltaSeconds: number): ()
	local character = entity.Character
	local humanoid = entity.Humanoid
	local state = character:GetState()
	local moving = humanoid.MoveDirection.Magnitude > MovementConfig.MovingThreshold
	local slowed = table.find(SLOW_STATES, state) ~= nil
	local stunned = table.find(STUN_STATES, state) ~= nil
	local resource = MovementConfig.SprintResource
	local stamina = if character:HasResource(resource) then character:GetResource(resource) else 0
	local minimum = if character:GetLocomotion() == "Sprinting" then 0 else MovementConfig.SprintMinToStart
	local canSprint = entity.SprintRequested and state == "Idle" and stamina > minimum

	local speed = if stunned
		then MovementConfig.StunnedSpeed
		elseif slowed then MovementConfig.SlowSpeed
		elseif canSprint then MovementConfig.SprintSpeed
		else MovementConfig.RunSpeed
	if humanoid.WalkSpeed ~= speed then
		humanoid.WalkSpeed = speed
	end

	local locomotion: LocomotionState = if not moving
		then "Stationary"
		elseif stunned or slowed then "Moving"
		elseif canSprint then "Sprinting"
		else "Running"
	character:SetLocomotion(locomotion)

	if locomotion == "Sprinting" then
		local cost = math.min(MovementConfig.SprintCostPerSecond * deltaSeconds, stamina)
		character:SpendResource(resource, cost)
	end
end

local MovementService = {
	Name = "MovementService",
}

function MovementService:Start(): ()
	task.spawn(function()
		while true do
			local deltaSeconds = task.wait(MovementConfig.TickSeconds)
			for _, entity in CombatRegistry.GetAll() do
				-- Los NPCs los mueve su propio controlador.
				if entity.Player ~= nil and entity.Character:IsAlive() then
					update(entity, deltaSeconds)
				end
			end
		end
	end)
end

-- Idempotente: pulsar y soltar sprint (D-026).
function MovementService:SetSprint(entity: CombatEntity, active: boolean): ()
	entity.SprintRequested = active
end

return MovementService
