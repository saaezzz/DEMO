--!strict

-- Impone una velocidad a un personaje durante un tiempo (dash, esquiva,
-- empuje; D-026). Funciona en cliente y servidor: una restricción creada por
-- el servidor replica al dueño de la física, que es quien la simula.

local ATTACHMENT_NAME = "VelocityImpulseAttachment"

local VelocityImpulse = {}

-- Sustituye al impulso anterior del mismo personaje en lugar de sumarse.
function VelocityImpulse.Apply(rootPart: BasePart, velocity: Vector3, duration: number): ()
	local previous = rootPart:FindFirstChild(ATTACHMENT_NAME)
	if previous ~= nil then
		previous:Destroy()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = ATTACHMENT_NAME

	local constraint = Instance.new("LinearVelocity")
	constraint.Attachment0 = attachment
	constraint.RelativeTo = Enum.ActuatorRelativeTo.World
	constraint.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	constraint.VectorVelocity = velocity
	constraint.MaxForce = math.huge
	constraint.Parent = attachment
	attachment.Parent = rootPart

	task.delay(duration, function()
		if attachment.Parent ~= nil then
			attachment:Destroy()
		end
	end)
end

return VelocityImpulse
