--!strict

-- Placas propias sobre los demás jugadores (D-022): nombre, nivel, vida y
-- postura. Oculta el nombre y la barra de vida por defecto de Roblox.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local CharacterWatcher = require(script.Parent.Parent.Utils.CharacterWatcher)
local StatBar = require(script.Parent.Parent.UI.StatBar)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

local PARTS_TIMEOUT_SECONDS = 5
local MAX_DISTANCE_STUDS = 90

local localPlayer = Players.LocalPlayer

local function onCharacter(player: Player, model: Model): CharacterWatcher.Cleanup?
	local humanoid = model:WaitForChild("Humanoid", PARTS_TIMEOUT_SECONDS) :: Humanoid?
	local head = model:WaitForChild("Head", PARTS_TIMEOUT_SECONDS) :: BasePart?
	if humanoid == nil or head == nil then
		return nil
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	-- El propio jugador ya tiene el HUD.
	if player == localPlayer then
		return nil
	end

	local billboard = UIUtil.create("BillboardGui", {
		Name = `Nameplate_{player.Name}`,
		Adornee = head,
		Size = UDim2.fromOffset(150, 42),
		StudsOffset = Vector3.new(0, 2.4, 0),
		MaxDistance = MAX_DISTANCE_STUDS,
		LightInfluence = 0,
		ResetOnSpawn = false,
		Parent = localPlayer:WaitForChild("PlayerGui"),
	}, {
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
	})
	local nameLabel = UIUtil.label({
		Text = player.DisplayName,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
		Parent = billboard,
	})
	local health = StatBar.new({ Parent = billboard, Color = Theme.Colors.Health, Height = 7, LayoutOrder = 2 })
	local posture = StatBar.new({ Parent = billboard, Color = Theme.Colors.Posture, Height = 3, LayoutOrder = 3 })

	local function updateName(): ()
		local level = model:GetAttribute(ReplicatedAttributes.LEVEL)
		nameLabel.Text = if typeof(level) == "number"
			then string.format('%s  <font color="#FF7A1A">Nv.%d</font>', player.DisplayName, level)
			else player.DisplayName
	end
	nameLabel.RichText = true

	local function updateHealth(): ()
		health:SetValue(humanoid.Health, humanoid.MaxHealth)
	end

	local function updatePosture(): ()
		local value = model:GetAttribute(ReplicatedAttributes.POSTURE)
		local max = model:GetAttribute(ReplicatedAttributes.MAX_POSTURE)
		if typeof(value) == "number" and typeof(max) == "number" then
			posture:SetValue(value, max)
			posture.Frame.Visible = value > 0
		end
	end

	local connections = {
		humanoid.HealthChanged:Connect(updateHealth),
		model:GetAttributeChangedSignal(ReplicatedAttributes.LEVEL):Connect(updateName),
		model:GetAttributeChangedSignal(ReplicatedAttributes.POSTURE):Connect(updatePosture),
	}
	updateName()
	updateHealth()
	posture.Frame.Visible = false
	updatePosture()

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		billboard:Destroy()
	end
end

local NameplateController = {
	Name = "NameplateController",
}

function NameplateController:Start(): ()
	CharacterWatcher.Observe(onCharacter)
end

return NameplateController
