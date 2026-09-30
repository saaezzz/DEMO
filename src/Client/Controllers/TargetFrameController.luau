--!strict

-- Información del objetivo fijado (§52, D-031): arriba al centro, nombre,
-- nivel, vida y postura. Solo aparece con un objetivo fijado (LockOnController).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local LockOnController = require(script.Parent.LockOnController)
local StatBar = require(script.Parent.Parent.UI.StatBar)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type StatBar = StatBar.StatBar

local panel: Frame
local nameLabel: TextLabel
local health: StatBar
local posture: StatBar
local connections: { RBXScriptConnection } = {}

local function disconnectAll(): ()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function bind(model: Model?): ()
	disconnectAll()
	local humanoid = if model ~= nil then model:FindFirstChildOfClass("Humanoid") else nil
	if model == nil or humanoid == nil then
		panel.Visible = false
		return
	end
	local target: Model = model
	local targetHumanoid: Humanoid = humanoid

	local function updateName(): ()
		local name = target:GetAttribute(ReplicatedAttributes.DISPLAY_NAME)
		local level = target:GetAttribute(ReplicatedAttributes.LEVEL)
		local displayName = if typeof(name) == "string" then name else target.Name
		nameLabel.Text = if typeof(level) == "number"
			then string.format('%s  <font color="#FF7A1A">Nv.%d</font>', displayName, level)
			else displayName
	end
	local function updateHealth(): ()
		health:SetValue(targetHumanoid.Health, targetHumanoid.MaxHealth)
	end
	local function updatePosture(): ()
		local value = target:GetAttribute(ReplicatedAttributes.POSTURE)
		local max = target:GetAttribute(ReplicatedAttributes.MAX_POSTURE)
		if typeof(value) == "number" and typeof(max) == "number" then
			posture:SetValue(value, max)
			posture:SetColor(if value >= max then Theme.Colors.PostureFull else Theme.Colors.Posture)
		end
	end

	table.insert(connections, targetHumanoid.HealthChanged:Connect(updateHealth))
	table.insert(connections, target:GetAttributeChangedSignal(ReplicatedAttributes.POSTURE):Connect(updatePosture))
	table.insert(connections, target:GetAttributeChangedSignal(ReplicatedAttributes.LEVEL):Connect(updateName))
	updateName()
	updateHealth()
	posture:SetValue(0, 1)
	updatePosture()
	panel.Visible = true
end

local TargetFrameController = {
	Name = "TargetFrameController",
}

function TargetFrameController:Start(): ()
	local gui = UIUtil.create("ScreenGui", {
		Name = "TargetFrame",
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	panel = UIUtil.create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	}, {
		UIUtil.create("UIStroke", { Color = Theme.Colors.Telegraph, Thickness = 1, Transparency = 0.4 }),
		UIUtil.create("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	})
	nameLabel = UIUtil.label({
		Text = "",
		RichText = true,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 1,
		Parent = panel,
	})
	health =
		StatBar.new({ Parent = panel, Color = Theme.Colors.Health, Height = 14, LayoutOrder = 2, ShowValue = true })
	posture = StatBar.new({ Parent = panel, Color = Theme.Colors.Posture, Height = 6, LayoutOrder = 3 })

	LockOnController.TargetChanged:Connect(bind)
end

return TargetFrameController
