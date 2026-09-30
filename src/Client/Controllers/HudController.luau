--!strict

-- HUD propio (constitución §52, D-022): sustituye la barra de vida de Roblox
-- por un panel con vida, postura, recursos, nivel/raza y estado de acción, y
-- muestra una pantalla de muerte con la cuenta atrás de reaparición.
-- Arriba a la izquierda para no chocar con los controles táctiles.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CharacterConfig = require(ReplicatedStorage.Shared.Config.CharacterConfig)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local StatBar = require(script.Parent.Parent.UI.StatBar)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type StatBar = StatBar.StatBar

local PARTS_TIMEOUT_SECONDS = 5
-- Alto de pantalla de referencia para el escalado (en móvil se reduce).
local REFERENCE_VIEWPORT_HEIGHT = 820

-- Texto del indicador para los estados que merece la pena señalar.
local STATE_LABELS: { [string]: string } = {
	Blocking = "GUARDIA",
	Parrying = "PARRY",
	Dashing = "DASH",
	Casting = "CANALIZANDO",
	Transforming = "TRANSFORMANDO",
	Stunned = "ATURDIDO",
	Knocked = "DERRIBADO",
	Ragdolled = "DERRIBADO",
	Disabled = "INCAPACITADO",
}

local player = Players.LocalPlayer

type HudElements = {
	Name: TextLabel,
	Info: TextLabel,
	StatePill: TextLabel,
	Health: StatBar,
	Posture: StatBar,
	ResourceList: Frame,
	Scale: UIScale,
}

type DeathScreen = {
	Gui: ScreenGui,
	Backdrop: Frame,
	Countdown: TextLabel,
}

local hud: HudElements
local deathScreen: DeathScreen
local resourceBars: { [string]: StatBar } = {}
local characterConnections: { RBXScriptConnection } = {}
-- Se incrementa en cada muerte/aparición para cancelar la cuenta atrás anterior.
local deathToken = 0

local function buildHud(playerGui: Instance): HudElements
	local gui = UIUtil.create("ScreenGui", {
		Name = "Hud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	local scale = UIUtil.create("UIScale", { Parent = gui })

	local panel = UIUtil.create("Frame", {
		Name = "Panel",
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		UIUtil.create("UIGradient", {
			Transparency = NumberSequence.new(0, 0.55),
		}),
		UIUtil.create("Frame", {
			Name = "Accent",
			Size = UDim2.new(0, 4, 1, 0),
			BackgroundColor3 = Theme.Colors.Accent,
			BorderSizePixel = 0,
		}),
	})

	local content = UIUtil.create("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		UIUtil.create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 10),
		}),
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),
	})

	local header = UIUtil.create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = content,
	})
	local nameLabel = UIUtil.label({
		Name = "PlayerName",
		Text = player.DisplayName,
		TextSize = 24,
		Size = UDim2.fromScale(0.65, 1),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	local statePill = UIUtil.label({
		Name = "State",
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.Colors.Panel,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = Theme.Colors.Accent,
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		Parent = header,
	})
	UIUtil.create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = statePill,
	})

	local infoLabel = UIUtil.label({
		Name = "Info",
		Text = "",
		TextSize = 14,
		FontFace = Theme.FontRegular,
		TextColor3 = Theme.Colors.Accent,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 2,
		Parent = content,
	})

	local health = StatBar.new({
		Parent = content,
		Color = Theme.Colors.Health,
		Height = 18,
		LayoutOrder = 3,
		Label = "PV",
		ShowValue = true,
	})
	local posture = StatBar.new({
		Parent = content,
		Color = Theme.Colors.Posture,
		Height = 12,
		LayoutOrder = 4,
		Label = "POSTURA",
	})
	posture:SetValue(0, 1)

	local resourceList = UIUtil.create("Frame", {
		Name = "Resources",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Parent = content,
	}, {
		UIUtil.create("UIListLayout", {
			SortOrder = Enum.SortOrder.Name,
			Padding = UDim.new(0, 5),
		}),
	})

	return {
		Name = nameLabel,
		Info = infoLabel,
		StatePill = statePill,
		Health = health,
		Posture = posture,
		ResourceList = resourceList,
		Scale = scale,
	}
end

local function buildDeathScreen(playerGui: Instance): DeathScreen
	local gui = UIUtil.create("ScreenGui", {
		Name = "DeathScreen",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Enabled = false,
		Parent = playerGui,
	})
	local backdrop = UIUtil.create("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(35, 0, 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		-- Viñeta: más opaco en los bordes que en el centro.
		UIUtil.create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.45),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Rotation = 90,
		}),
	})
	UIUtil.label({
		Text = "HAS CAÍDO",
		TextSize = 64,
		TextColor3 = Theme.Colors.HealthLow,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(1, 0, 0, 70),
		Parent = gui,
	})
	local countdown = UIUtil.label({
		Text = "",
		TextSize = 22,
		FontFace = Theme.FontRegular,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = gui,
	})
	return { Gui = gui, Backdrop = backdrop, Countdown = countdown }
end

local function updateScale(): ()
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		hud.Scale.Scale = math.clamp(camera.ViewportSize.Y / REFERENCE_VIEWPORT_HEIGHT, 0.65, 1.1)
	end
end

local function showDeathScreen(): ()
	deathToken += 1
	local token = deathToken
	deathScreen.Gui.Enabled = true
	deathScreen.Backdrop.BackgroundTransparency = 1
	TweenService:Create(deathScreen.Backdrop, TweenInfo.new(0.6), { BackgroundTransparency = 0.25 }):Play()

	task.spawn(function()
		for remaining = CharacterConfig.RespawnSeconds, 1, -1 do
			if token ~= deathToken then
				return
			end
			deathScreen.Countdown.Text = string.format("Reapareciendo en %d...", remaining)
			task.wait(1)
		end
		if token == deathToken then
			deathScreen.Countdown.Text = "Reapareciendo..."
		end
	end)
end

local function hideDeathScreen(): ()
	deathToken += 1
	deathScreen.Gui.Enabled = false
end

local function clearResourceBars(): ()
	for _, bar in resourceBars do
		bar:Destroy()
	end
	table.clear(resourceBars)
end

local function updateResource(model: Model, resourceId: string): ()
	local definition = Resources[resourceId]
	if definition == nil then
		return
	end
	local bar: StatBar? = resourceBars[resourceId]
	if bar == nil then
		local created = StatBar.new({
			Parent = hud.ResourceList,
			Color = Color3.fromHex(definition.Color),
			Height = 12,
			Label = string.upper(definition.DisplayName),
			ShowValue = true,
		})
		created.Frame.Name = resourceId
		resourceBars[resourceId] = created
		bar = created
	end
	local current = model:GetAttribute(ReplicatedAttributes.Resource(resourceId))
	local max = model:GetAttribute(ReplicatedAttributes.ResourceMax(resourceId))
	if typeof(current) == "number" and typeof(max) == "number" then
		(bar :: StatBar):SetValue(current, max)
	end
end

local function updateInfo(model: Model): ()
	local level = model:GetAttribute(ReplicatedAttributes.LEVEL)
	local raceId = model:GetAttribute(ReplicatedAttributes.RACE)
	local race = if typeof(raceId) == "string" then Races.Definitions[raceId] else nil
	local raceName = if race ~= nil then string.upper(race.DisplayName) else ""
	hud.Info.Text = if typeof(level) == "number" then string.format("NV. %d  ·  %s", level, raceName) else raceName
end

local function updatePosture(model: Model): ()
	local posture = model:GetAttribute(ReplicatedAttributes.POSTURE)
	local maxPosture = model:GetAttribute(ReplicatedAttributes.MAX_POSTURE)
	if typeof(posture) == "number" and typeof(maxPosture) == "number" then
		hud.Posture:SetValue(posture, maxPosture)
		hud.Posture:SetColor(if posture >= maxPosture then Theme.Colors.PostureFull else Theme.Colors.Posture)
	end
end

local function updateState(model: Model): ()
	local state = model:GetAttribute(ReplicatedAttributes.STATE)
	local text = if typeof(state) == "string" then STATE_LABELS[state] else nil
	hud.StatePill.Visible = text ~= nil
	hud.StatePill.Text = text or ""
end

local function onAttributeChanged(model: Model, attribute: string): ()
	if attribute == ReplicatedAttributes.POSTURE or attribute == ReplicatedAttributes.MAX_POSTURE then
		updatePosture(model)
	elseif attribute == ReplicatedAttributes.STATE then
		updateState(model)
	elseif attribute == ReplicatedAttributes.LEVEL or attribute == ReplicatedAttributes.RACE then
		updateInfo(model)
	else
		local resourceId = ReplicatedAttributes.ParseResource(attribute)
		if resourceId ~= nil then
			updateResource(model, resourceId)
		end
	end
end

local function updateHealth(humanoid: Humanoid): ()
	hud.Health:SetValue(humanoid.Health, humanoid.MaxHealth)
	local low = humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth <= Theme.LowHealthRatio
	hud.Health:SetColor(if low then Theme.Colors.HealthLow else Theme.Colors.Health)
end

local function bindCharacter(model: Model): ()
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	clearResourceBars()
	hideDeathScreen()

	local humanoid = model:WaitForChild("Humanoid", PARTS_TIMEOUT_SECONDS) :: Humanoid?
	if humanoid == nil or player.Character ~= model then
		return
	end

	table.insert(
		characterConnections,
		humanoid.HealthChanged:Connect(function()
			updateHealth(humanoid)
		end)
	)
	table.insert(characterConnections, humanoid.Died:Connect(showDeathScreen))
	table.insert(
		characterConnections,
		model.AttributeChanged:Connect(function(attribute)
			onAttributeChanged(model, attribute)
		end)
	)

	updateHealth(humanoid)
	for attribute in model:GetAttributes() do
		onAttributeChanged(model, attribute)
	end
	updateInfo(model)
	updateState(model)
end

local HudController = {
	Name = "HudController",
}

function HudController:Start(): ()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	local playerGui = player:WaitForChild("PlayerGui")
	hud = buildHud(playerGui)
	deathScreen = buildDeathScreen(playerGui)

	updateScale()
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	player.CharacterAdded:Connect(bindCharacter)
	local current = player.Character
	if current ~= nil then
		task.spawn(bindCharacter, current)
	end
end

return HudController
