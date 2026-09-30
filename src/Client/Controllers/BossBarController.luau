--!strict

-- Barra del jefe (§43, D-037): arriba al centro mientras estés cerca de un
-- jefe (atributo IsBoss), con su vida, su postura (romperla es su punto débil)
-- y un aviso al cambiar de fase. Sirve para cualquier enemigo marcado como jefe.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local CharacterWatcher = require(script.Parent.Parent.Utils.CharacterWatcher)
local NotificationController = require(script.Parent.NotificationController)
local StatBar = require(script.Parent.Parent.UI.StatBar)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type StatBar = StatBar.StatBar

-- Distancia a la que aparece la barra.
local SHOW_DISTANCE = 90
local CHECK_SECONDS = 0.5

local player = Players.LocalPlayer
local panel: Frame
local nameLabel: TextLabel
local health: StatBar
local posture: StatBar
local bosses: { [Model]: boolean } = {}
local shown: Model? = nil
local shownConnections: { RBXScriptConnection } = {}

local function getRoot(model: Model?): BasePart?
	local root = if model ~= nil then model:FindFirstChild("HumanoidRootPart") else nil
	return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function unbind(): ()
	for _, connection in shownConnections do
		connection:Disconnect()
	end
	table.clear(shownConnections)
	shown = nil
	panel.Visible = false
end

local function bind(model: Model): ()
	unbind()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local bossHumanoid: Humanoid = humanoid
	shown = model

	local function updateName(): ()
		local name = model:GetAttribute(ReplicatedAttributes.DISPLAY_NAME)
		local phase = model:GetAttribute(ReplicatedAttributes.ENEMY_PHASE)
		local displayName = string.upper(if typeof(name) == "string" then name else model.Name)
		nameLabel.Text = if typeof(phase) == "number" and phase > 0
			then string.format('%s  <font color="#FF7A1A">FASE %d</font>', displayName, phase + 1)
			else displayName
	end
	local function updateHealth(): ()
		health:SetValue(bossHumanoid.Health, bossHumanoid.MaxHealth)
	end
	local function updatePosture(): ()
		local value = model:GetAttribute(ReplicatedAttributes.POSTURE)
		local max = model:GetAttribute(ReplicatedAttributes.MAX_POSTURE)
		if typeof(value) == "number" and typeof(max) == "number" then
			posture:SetValue(value, max)
		end
	end

	table.insert(shownConnections, bossHumanoid.HealthChanged:Connect(updateHealth))
	table.insert(shownConnections, model:GetAttributeChangedSignal(ReplicatedAttributes.POSTURE):Connect(updatePosture))
	table.insert(
		shownConnections,
		model:GetAttributeChangedSignal(ReplicatedAttributes.ENEMY_PHASE):Connect(updateName)
	)
	updateName()
	updateHealth()
	posture:SetValue(0, 1)
	updatePosture()
	panel.Visible = true
end

-- Muestra el jefe vivo más cercano dentro de SHOW_DISTANCE.
local function refresh(): ()
	local myRoot = getRoot(player.Character)
	local nearest: Model? = nil
	local nearestDistance = SHOW_DISTANCE
	if myRoot ~= nil then
		for model in bosses do
			local root = getRoot(model)
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if root ~= nil and humanoid ~= nil and humanoid.Health > 0 then
				local distance = (root.Position - myRoot.Position).Magnitude
				if distance <= nearestDistance then
					nearest = model
					nearestDistance = distance
				end
			end
		end
	end
	if nearest ~= shown then
		if nearest ~= nil then
			bind(nearest)
		else
			unbind()
		end
	end
end

local function onCharacter(_player: Player?, model: Model): CharacterWatcher.Cleanup?
	if model:GetAttribute(ReplicatedAttributes.IS_BOSS) ~= true then
		return nil
	end
	bosses[model] = true
	-- Aviso de cambio de fase si estás cerca (la barra está mostrando este jefe).
	local connection = model:GetAttributeChangedSignal(ReplicatedAttributes.ANNOUNCEMENT):Connect(function()
		local text = model:GetAttribute(ReplicatedAttributes.ANNOUNCEMENT)
		if shown == model and typeof(text) == "string" then
			NotificationController:Show(text, Theme.Colors.Telegraph, 34)
		end
	end)
	return function()
		connection:Disconnect()
		bosses[model] = nil
		if shown == model then
			unbind()
		end
	end
end

local BossBarController = {
	Name = "BossBarController",
}

function BossBarController:Start(): ()
	local gui = UIUtil.create("ScreenGui", {
		Name = "BossBar",
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	panel = UIUtil.create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(520, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	}, {
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	})
	nameLabel = UIUtil.label({
		Text = "",
		RichText = true,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 1,
		Parent = panel,
	})
	health =
		StatBar.new({ Parent = panel, Color = Theme.Colors.Health, Height = 18, LayoutOrder = 2, ShowValue = true })
	posture = StatBar.new({ Parent = panel, Color = Theme.Colors.Posture, Height = 6, LayoutOrder = 3 })

	CharacterWatcher.Observe(onCharacter)
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			refresh()
		end
	end)
end

-- El jefe cuya barra se muestra (para no duplicarla en el panel del objetivo).
function BossBarController:GetShown(): Model?
	return shown
end

return BossBarController
