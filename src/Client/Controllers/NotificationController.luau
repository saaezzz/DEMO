--!strict

-- Avisos de progreso arriba al centro (D-031): EXP ganada, subida de nivel,
-- misiones nuevas o completadas, objetos conseguidos (D-036), hitos de raza y
-- su progreso (D-039). Se deducen de los cambios en los datos del jugador
-- (PlayerDataController); no hace falta ningún remote más. También avisa al
-- entrar o salir de una zona ambiental si la raza tiene un recurso que
-- depende de ella (D-041).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Progression = require(ReplicatedStorage.Shared.Modules.Progression)
local Quests = require(ReplicatedStorage.Shared.Content.Quests)
local Items = require(ReplicatedStorage.Shared.Content.Items)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)
local AbilityInfo = require(ReplicatedStorage.Shared.Content.AbilityInfo)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local Stats = require(ReplicatedStorage.Shared.Content.Stats)
local KitLogic = require(ReplicatedStorage.Shared.Modules.KitLogic)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)

local PlayerDataController = require(script.Parent.PlayerDataController)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type PlayerData = PlayerDataTypes.PlayerData

local TOAST_SECONDS = 2.5
local FADE = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Nivel y EXP llegan en dos mensajes seguidos: se espera a tener ambos.
local PROGRESS_SETTLE_SECONDS = 0.1

local list: Frame
local lastLevel = 1
local lastExperience = 0
local lastActive: { [string]: boolean } = {}
local lastCompleted: { [string]: boolean } = {}
-- Cantidad de cada objeto, para anunciar lo que se consigue.
local lastItems: { [string]: number } = {}
local progressPending = false
local lastMilestones: { string } = {}
local lastStats: { [string]: number } = {}
local zoneConnection: RBXScriptConnection? = nil

local function show(text: string, color: Color3, size: number): ()
	local label = UIUtil.label({
		Text = text,
		TextSize = size,
		TextColor3 = color,
		TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, size + 6),
		TextTransparency = 1,
		Parent = list,
	})
	TweenService:Create(label, FADE, { TextTransparency = 0 }):Play()
	task.delay(TOAST_SECONDS, function()
		TweenService:Create(label, FADE, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(FADE.Time)
		label:Destroy()
	end)
end

-- EXP total ganada entre dos momentos, contando los niveles subidos.
local function experienceGained(fromLevel: number, fromXp: number, toLevel: number, toXp: number): number
	local total = toXp - fromXp
	for level = fromLevel, toLevel - 1 do
		total += Progression.XpToNext(level)
	end
	return total
end

local function flushProgress(): ()
	progressPending = false
	local data = PlayerDataController:GetData()
	if data == nil then
		return
	end
	local gained = experienceGained(lastLevel, lastExperience, data.Level, data.Experience)
	if gained > 0 then
		show(`+{gained} EXP`, Theme.Colors.Experience, 20)
	end
	if data.Level > lastLevel then
		show(`¡NIVEL {data.Level}!`, Theme.Colors.Accent, 40)
	end
	lastLevel = data.Level
	lastExperience = data.Experience
end

local function countItems(data: PlayerData): { [string]: number }
	local counts: { [string]: number } = {}
	for _, slot in data.Inventory do
		counts[slot.Id] = (counts[slot.Id] or 0) + slot.Quantity
	end
	return counts
end

-- Solo se anuncian las ganancias (usar un objeto no avisa).
local function onInventoryChanged(data: PlayerData): ()
	local counts = countItems(data)
	for itemId, count in counts do
		local gained = count - (lastItems[itemId] or 0)
		local item = Items[itemId]
		if gained > 0 and item ~= nil then
			local rarity = ItemConfig.Rarities[item.Rarity]
			local color = if rarity ~= nil then Color3.fromHex(rarity.Color) else Theme.Colors.Text
			show(`+{gained} {item.DisplayName}`, color, 20)
		end
	end
	lastItems = counts
end

local function snapshotQuests(data: PlayerData): ()
	table.clear(lastActive)
	for _, quest in data.Quests.Active do
		lastActive[quest.Id] = true
	end
	lastCompleted = table.clone(data.Quests.Completed)
end

local function onQuestsChanged(data: PlayerData): ()
	for questId in data.Quests.Completed do
		local definition = Quests.Definitions[questId]
		if not lastCompleted[questId] and definition ~= nil then
			show(`Misión completada: {definition.Title}`, Theme.Colors.Quest, 24)
		end
	end
	for _, quest in data.Quests.Active do
		local definition = Quests.Definitions[quest.Id]
		if not lastActive[quest.Id] and definition ~= nil then
			show(`Nueva misión: {definition.Title}`, Theme.Colors.Text, 22)
		end
	end
	snapshotQuests(data)
end

local function onMilestonesChanged(data: PlayerData): ()
	local race = Races.Definitions[data.Race]
	if race == nil then
		return
	end
	for _, milestone in race.Milestones do
		local isNew = table.find(data.Milestones, milestone.Id) ~= nil
			and table.find(lastMilestones, milestone.Id) == nil
		if isNew then
			show(`¡{milestone.DisplayName}!`, Theme.Colors.Accent, 34)
			show(milestone.Description, Theme.Colors.Text, 18)
			for _, skill in milestone.UnlockSkills do
				local info = AbilityInfo[skill]
				show(`Nueva técnica: {if info ~= nil then info.DisplayName else skill}`, Theme.Colors.Quest, 22)
			end
		end
	end
	lastMilestones = table.clone(data.Milestones)
end

-- Progreso hacia el siguiente hito: solo de las estadísticas que este pide.
local function onStatsChanged(data: PlayerData): ()
	local race = Races.Definitions[data.Race]
	local nextMilestone = if race ~= nil then KitLogic.NextMilestone(race, data.Milestones) else nil
	for stat, value in data.Stats do
		local required = if nextMilestone ~= nil then nextMilestone.RequiredStats[stat] else nil
		local definition = Stats[stat]
		if value > (lastStats[stat] or 0) and required ~= nil and definition ~= nil then
			show(`{definition.DisplayName}: {math.min(value, required)}/{required}`, Theme.Colors.Text, 18)
		end
	end
	lastStats = table.clone(data.Stats)
end

-- Recurso de la raza del jugador que depende de la zona ambiental, o nil.
local function ambientResourceName(): string?
	local data = PlayerDataController:GetData()
	local race = if data ~= nil then Races.Definitions[data.Race] else nil
	if race == nil then
		return nil
	end
	for _, resourceId in race.Resources do
		local definition = Resources[resourceId]
		if definition ~= nil and definition.AmbientScaling then
			return definition.DisplayName
		end
	end
	return nil
end

-- `previousZone` es nil al aparecer: empezar fuera de toda zona no se anuncia.
local function onZoneChanged(model: Model, previousZone: string?): ()
	local resourceName = ambientResourceName()
	local zoneName = model:GetAttribute(ReplicatedAttributes.AMBIENT_ZONE)
	local density = model:GetAttribute(ReplicatedAttributes.AMBIENT_DENSITY)
	if resourceName == nil or typeof(zoneName) ~= "string" or typeof(density) ~= "number" then
		return
	end
	if previousZone == nil and zoneName == "" then
		return
	end
	if zoneName == "" then
		show(`{resourceName} ambiental normal`, Theme.Colors.Text, 18)
	else
		show(`{zoneName}: {resourceName} ambiental ×{density}`, Theme.Colors.Accent, 20)
	end
end

local function bindCharacter(model: Model): ()
	local previous = zoneConnection
	if previous ~= nil then
		previous:Disconnect()
	end
	local current = model:GetAttribute(ReplicatedAttributes.AMBIENT_ZONE)
	local lastZone: string? = if typeof(current) == "string" then current else nil
	zoneConnection = model:GetAttributeChangedSignal(ReplicatedAttributes.AMBIENT_ZONE):Connect(function()
		onZoneChanged(model, lastZone)
		local zone = model:GetAttribute(ReplicatedAttributes.AMBIENT_ZONE)
		lastZone = if typeof(zone) == "string" then zone else nil
	end)
end

local NotificationController = {
	Name = "NotificationController",
}

-- Muestra un aviso propio (p. ej. el cambio de fase de un jefe).
function NotificationController:Show(text: string, color: Color3, size: number): ()
	show(text, color, size)
end

function NotificationController:Start(): ()
	local gui = UIUtil.create("ScreenGui", {
		Name = "Notifications",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	list = UIUtil.create("Frame", {
		Name = "List",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.fromOffset(520, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
	})

	-- Estado inicial: lo que ya tenía al entrar no se anuncia.
	local function initialize(data: PlayerData): ()
		lastLevel = data.Level
		lastExperience = data.Experience
		snapshotQuests(data)
		lastItems = countItems(data)
		lastMilestones = table.clone(data.Milestones)
		lastStats = table.clone(data.Stats)
	end
	PlayerDataController.Loaded:Connect(initialize)
	local current = PlayerDataController:GetData()
	if current ~= nil then
		initialize(current)
	end

	PlayerDataController.Changed:Connect(function(key)
		local data = PlayerDataController:GetData()
		if data == nil then
			return
		end
		if key == "Quests" then
			onQuestsChanged(data)
		elseif key == "Inventory" then
			onInventoryChanged(data)
		elseif key == "Milestones" then
			onMilestonesChanged(data)
		elseif key == "Stats" then
			onStatsChanged(data)
		elseif (key == "Experience" or key == "Level") and not progressPending then
			progressPending = true
			task.delay(PROGRESS_SETTLE_SECONDS, flushProgress)
		end
	end)

	local localPlayer = Players.LocalPlayer
	localPlayer.CharacterAdded:Connect(bindCharacter)
	if localPlayer.Character ~= nil then
		bindCharacter(localPlayer.Character)
	end
end

return NotificationController
