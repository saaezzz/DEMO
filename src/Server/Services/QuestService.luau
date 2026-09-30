--!strict

-- Misiones (§40, D-030): la primera empieza al cargar el perfil; cada baja
-- avanza los objetivos; al completar una se da la recompensa y empieza la
-- siguiente. El progreso se guarda en el perfil (Quests) y replica al dueño,
-- que lo muestra en el seguimiento.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Quests = require(ReplicatedStorage.Shared.Content.Quests)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local QuestLogic = require(script.Parent.Parent.Modules.QuestLogic)
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)

local log = Logger.new("QuestService")

local function startQuest(player: Player, questId: string): ()
	local data = DataService:GetData(player)
	if data == nil then
		return
	end
	local updated = QuestLogic.Start(data.Quests, questId, Quests.Definitions)
	if updated ~= nil then
		DataService:SetValue(player, "Quests", updated)
		log:Debug("%s empieza %s", player.Name, questId)
	end
end

-- Un personaje nuevo (o que aún no la tenía) empieza la primera misión.
local function ensureStartingQuest(player: Player): ()
	local data = DataService:GetData(player)
	if data ~= nil and #data.Quests.Active == 0 and not data.Quests.Completed[Quests.Starting] then
		startQuest(player, Quests.Starting)
	end
end

local QuestService = {
	Name = "QuestService",
}

function QuestService:Start(): ()
	DataService.ProfileLoaded:Connect(ensureStartingQuest)
	-- Perfiles que terminaron de cargar antes de este Start.
	for _, player in Players:GetPlayers() do
		if DataService:IsLoaded(player) then
			ensureStartingQuest(player)
		end
	end
end

-- `player` ha participado en derrotar a un enemigo `enemyId`.
function QuestService:RecordKill(player: Player, enemyId: string): ()
	local data = DataService:GetData(player)
	if data == nil then
		return
	end
	local updated, completed = QuestLogic.RecordKill(data.Quests, enemyId, Quests.Definitions)
	DataService:SetValue(player, "Quests", updated)

	for _, questId in completed do
		local definition = Quests.Definitions[questId]
		log:Info("%s completa %s", player.Name, questId)
		ProgressionService:AwardExperience(player, definition.Rewards.Experience)
		local nextQuest = definition.Next
		if nextQuest ~= nil then
			startQuest(player, nextQuest)
		end
	end
end

return QuestService
