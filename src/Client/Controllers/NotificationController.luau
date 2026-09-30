--!strict

-- Avisos de progreso arriba al centro (D-031): EXP ganada, subida de nivel y
-- misiones nuevas o completadas. Se deducen de los cambios en los datos del
-- jugador (PlayerDataController); no hace falta ningún remote más.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Progression = require(ReplicatedStorage.Shared.Modules.Progression)
local Quests = require(ReplicatedStorage.Shared.Content.Quests)
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
local progressPending = false

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

local NotificationController = {
	Name = "NotificationController",
}

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
		elseif (key == "Experience" or key == "Level") and not progressPending then
			progressPending = true
			task.delay(PROGRESS_SETTLE_SECONDS, flushProgress)
		end
	end)
end

return NotificationController
