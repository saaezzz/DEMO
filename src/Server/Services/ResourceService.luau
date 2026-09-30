--!strict

-- Regeneración pasiva de recursos y recuperación de postura (§17
-- ResourceService). Cada recurso usa su RegenPerSecond y su
-- RegenDelaySeconds (tras gastarlo, espera antes de regenerarse).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Shared.Content.Resources)

local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)

type CombatEntity = CombatRegistry.CombatEntity

local function regenerate(entity: CombatEntity, deltaSeconds: number, now: number): ()
	local character = entity.Character
	for _, resourceId in character:GetResourceIds() do
		local definition = Resources[resourceId]
		if definition ~= nil and definition.RegenPerSecond > 0 then
			local lastSpent = entity.LastSpent[resourceId]
			local delay = definition.RegenDelaySeconds or 0
			if lastSpent == nil or now - lastSpent >= delay then
				character:RestoreResource(resourceId, definition.RegenPerSecond * deltaSeconds)
			end
		end
	end

	local state = character:GetState()
	if state ~= "Blocking" and state ~= "Parrying" and state ~= "Stunned" then
		character:RecoverPosture(CombatConfig.PostureDecayPerSecond * deltaSeconds)
	end
end

local ResourceService = {
	Name = "ResourceService",
}

function ResourceService:Start(): ()
	task.spawn(function()
		while true do
			local deltaSeconds = task.wait(CombatConfig.RegenTickSeconds)
			local now = os.clock()
			for _, entity in CombatRegistry.GetAll() do
				if entity.Character:IsAlive() then
					regenerate(entity, deltaSeconds, now)
				end
			end
		end
	end)
end

-- Anota un gasto para el retardo de regeneración (lo llama CombatService al
-- ver bajar un recurso).
function ResourceService:NoteSpent(entity: CombatEntity, resourceId: string): ()
	entity.LastSpent[resourceId] = os.clock()
end

return ResourceService
