--!strict

-- Progreso de misiones (§40, D-030). Lógica pura sobre QuestData: nunca
-- modifica la tabla recibida (son datos del perfil), devuelve una copia.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)
local QuestTypes = require(ReplicatedStorage.Shared.Types.QuestTypes)

type QuestData = PlayerDataTypes.QuestData
type ActiveQuest = PlayerDataTypes.ActiveQuest
type QuestDefinition = QuestTypes.QuestDefinition
type Definitions = { [string]: QuestDefinition }

local function copy(data: QuestData): QuestData
	local active: { ActiveQuest } = {}
	for _, quest in data.Active do
		table.insert(active, { Id = quest.Id, Progress = table.clone(quest.Progress) })
	end
	return { Active = active, Completed = table.clone(data.Completed) }
end

local function isActive(data: QuestData, questId: string): boolean
	for _, quest in data.Active do
		if quest.Id == questId then
			return true
		end
	end
	return false
end

local function isFinished(quest: ActiveQuest, definition: QuestDefinition): boolean
	for index, objective in definition.Objectives do
		if (quest.Progress[index] or 0) < objective.Count then
			return false
		end
	end
	return true
end

local QuestLogic = {}

-- nil si no existe, ya está en curso o ya se completó.
function QuestLogic.Start(data: QuestData, questId: string, definitions: Definitions): QuestData?
	local definition = definitions[questId]
	if definition == nil or data.Completed[questId] or isActive(data, questId) then
		return nil
	end
	local result = copy(data)
	local progress: { number } = table.create(#definition.Objectives, 0)
	table.insert(result.Active, { Id = questId, Progress = progress })
	return result
end

-- Suma una baja de `enemyId` a los objetivos que la cuenten. Las misiones que
-- quedan completas salen de Active y pasan a Completed; se devuelven sus ids
-- (las recompensas y la siguiente misión las gestiona QuestService).
function QuestLogic.RecordKill(data: QuestData, enemyId: string, definitions: Definitions): (QuestData, { string })
	local result = copy(data)
	local completed: { string } = {}
	local remaining: { ActiveQuest } = {}

	for _, quest in result.Active do
		local definition = definitions[quest.Id]
		if definition == nil then
			-- Misión retirada del contenido: se conserva sin tocarla.
			table.insert(remaining, quest)
			continue
		end
		for index, objective in definition.Objectives do
			local current = quest.Progress[index] or 0
			if objective.Kind == "Kill" and objective.Target == enemyId and current < objective.Count then
				quest.Progress[index] = current + 1
			end
		end
		if isFinished(quest, definition) then
			result.Completed[quest.Id] = true
			table.insert(completed, quest.Id)
		else
			table.insert(remaining, quest)
		end
	end

	result.Active = remaining
	return result, completed
end

return QuestLogic
