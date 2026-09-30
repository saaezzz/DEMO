--!strict

-- Acciones comunes de los NPCs de combate: encarar y atacar con aviso previo
-- (D-023). Las usan los muñecos y los enemigos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local CombatService = require(script.Parent.Parent.Services.CombatService)
local NpcFactory = require(script.Parent.NpcFactory)

type Npc = NpcFactory.Npc

local NpcActions = {}

-- Gira al NPC en horizontal hacia `target`.
function NpcActions.FaceTowards(npc: Npc, target: Vector3): ()
	local position = npc.RootPart.Position
	local flatTarget = Vector3.new(target.X, position.Y, target.Z)
	if (flatTarget - position).Magnitude > 1e-3 then
		npc.RootPart.CFrame = CFrame.lookAt(position, flatTarget)
	end
end

-- Avisa (el cliente resalta al NPC en rojo) y, tras `telegraphSeconds`, usa la
-- habilidad mirando al objetivo. Si entretanto muere o deja de estar libre
-- (aturdido por un golpe), el ataque no sale. `onDone` se llama siempre.
function NpcActions.TelegraphAttack(
	npc: Npc,
	abilityId: string,
	telegraphSeconds: number,
	target: BasePart,
	onDone: () -> ()
): ()
	NpcActions.FaceTowards(npc, target.Position)
	npc.Model:SetAttribute(ReplicatedAttributes.TELEGRAPH, os.clock())

	task.delay(telegraphSeconds, function()
		local character = npc.Character
		if npc.Model.Parent ~= nil and character:IsAlive() and character:GetState() == "Idle" then
			if target.Parent ~= nil then
				NpcActions.FaceTowards(npc, target.Position)
			end
			CombatService:ActivateAbility(npc.Model, abilityId)
		end
		onDone()
	end)
end

return NpcActions
