--!strict

-- Seguimiento de misiones (§52, D-031): panel a la derecha con la misión
-- activa y sus objetivos, y un marcador en el mundo hacia cada objetivo
-- pendiente con su distancia (pauta D-023).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Quests = require(ReplicatedStorage.Shared.Content.Quests)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)

local PlayerDataController = require(script.Parent.PlayerDataController)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type ActiveQuest = PlayerDataTypes.ActiveQuest

local MARKER_UPDATE_SECONDS = 0.25
-- Por debajo de esta distancia el marcador se oculta: ya se está en la zona.
local MARKER_HIDE_DISTANCE = 20

type Marker = {
	Anchor: Part,
	Distance: TextLabel,
	Position: Vector3,
}

local player = Players.LocalPlayer
local content: Frame
local markerGui: Folder
local markers: { Marker } = {}

local function clearMarkers(): ()
	for _, marker in markers do
		marker.Anchor:Destroy()
	end
	table.clear(markers)
end

local function addMarker(position: Vector3, text: string): ()
	-- Pieza invisible y local que sirve de ancla al BillboardGui.
	local anchor = UIUtil.create("Part", {
		Name = "QuestMarker",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
		Position = position + Vector3.new(0, 6, 0),
		Parent = markerGui,
	})
	local billboard = UIUtil.create("BillboardGui", {
		Adornee = anchor,
		AlwaysOnTop = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(160, 48),
		Parent = anchor,
	})
	UIUtil.label({
		Text = `◆ {text}`,
		TextSize = 16,
		TextColor3 = Theme.Colors.Quest,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 0.5),
		Parent = billboard,
	})
	local distance = UIUtil.label({
		Text = "",
		TextSize = 14,
		FontFace = Theme.FontRegular,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(1, 0.5),
		Parent = billboard,
	})
	table.insert(markers, { Anchor = anchor, Distance = distance, Position = position })
end

local function updateMarkers(): ()
	local model = player.Character
	local root = if model ~= nil then model:FindFirstChild("HumanoidRootPart") else nil
	if root == nil or not root:IsA("BasePart") then
		return
	end
	for _, marker in markers do
		local distance = (marker.Position - root.Position).Magnitude
		local billboard = marker.Anchor:FindFirstChildOfClass("BillboardGui")
		if billboard ~= nil then
			billboard.Enabled = distance > MARKER_HIDE_DISTANCE
		end
		marker.Distance.Text = string.format("%d m", math.floor(distance))
	end
end

local function render(): ()
	for _, child in content:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	clearMarkers()

	local data = PlayerDataController:GetData()
	local active: { ActiveQuest } = if data ~= nil then data.Quests.Active else {}
	local order = 0
	local function line(text: string, color: Color3, size: number, bold: boolean): ()
		order += 1
		UIUtil.label({
			Text = text,
			TextSize = size,
			TextColor3 = color,
			FontFace = if bold then Theme.FontBold else Theme.FontRegular,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, size + 2),
			LayoutOrder = order,
			Parent = content,
		})
	end

	line("MISIÓN", Theme.Colors.Accent, 13, true)
	if #active == 0 then
		line("Sin misiones activas", Theme.Colors.TextDim, 16, false)
		return
	end

	for _, quest in active do
		local definition = Quests.Definitions[quest.Id]
		if definition ~= nil then
			line(definition.Title, Theme.Colors.Quest, 19, true)
			for index, objective in definition.Objectives do
				local progress = math.min(quest.Progress[index] or 0, objective.Count)
				local done = progress >= objective.Count
				local prefix = if done then "✓" else "•"
				line(
					`{prefix} {objective.Description} {progress}/{objective.Count}`,
					if done then Theme.Colors.TextDim else Theme.Colors.Text,
					16,
					false
				)
				local location = objective.Location
				if location ~= nil and not done then
					addMarker(location, objective.Description)
				end
			end
		end
	end
	updateMarkers()
end

local QuestTrackerController = {
	Name = "QuestTrackerController",
}

function QuestTrackerController:Start(): ()
	local gui = UIUtil.create("ScreenGui", {
		Name = "QuestTracker",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = UIUtil.create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0.28, 0),
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		UIUtil.create("UIGradient", { Transparency = NumberSequence.new(0.55, 0) }),
	})
	content = UIUtil.create("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		UIUtil.create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		}),
	})
	markerGui = UIUtil.create("Folder", { Name = "QuestMarkers", Parent = Workspace })

	PlayerDataController.Loaded:Connect(render)
	PlayerDataController.Changed:Connect(function(key)
		if key == "Quests" then
			render()
		end
	end)
	render()

	task.spawn(function()
		while true do
			task.wait(MARKER_UPDATE_SECONDS)
			updateMarkers()
		end
	end)
end

return QuestTrackerController
