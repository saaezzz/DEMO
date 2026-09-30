--!strict

-- Barra de acciones abajo al centro (§52 habilidades y cooldowns, D-031): una
-- casilla por acción del moveset (pesado, esquiva, movimiento y técnicas), con
-- su tecla o botón según el mando y el cooldown restante. Las casillas se
-- pueden pulsar: en táctil son la forma de lanzar estas acciones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local AbilityInfo = require(ReplicatedStorage.Shared.Content.AbilityInfo)
local Movesets = require(ReplicatedStorage.Shared.Content.Movesets)
local Races = require(ReplicatedStorage.Shared.Content.Races)

local CombatController = require(script.Parent.CombatController)
local PlayerDataController = require(script.Parent.PlayerDataController)
local InputController = require(script.Parent.InputController)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type CombatAction = GameTypes.CombatAction
type ActionName = InputBindings.ActionName

local SLOT_SIZE = 58

type SlotDefinition = {
	Action: ActionName,
	Label: string,
}

-- Acciones de las técnicas, en el orden de Moveset.Skills.
local SKILL_ACTIONS: { ActionName } = { "Ability1", "Ability2", "Ability3", "Ability4" }

-- Nombres cortos de teclas y botones.
local SHORT_NAMES: { [string]: string } = {
	LeftControl = "Ctrl",
	RightControl = "Ctrl",
	LeftShift = "Shift",
	ButtonL1 = "L1",
	ButtonR1 = "R1",
	ButtonL2 = "L2",
	ButtonR2 = "R2",
	ButtonL3 = "L3",
	ButtonR3 = "R3",
	ButtonX = "X",
	ButtonY = "Y",
	ButtonB = "B",
	MouseButton1 = "Clic",
	MouseButton2 = "Clic der.",
}

type Slot = {
	Frame: TextButton,
	Key: TextLabel,
	Overlay: Frame,
	Timer: TextLabel,
	ReadyAt: number,
	Duration: number,
}

local gui: ScreenGui
local bar: Frame
local slots: { [ActionName]: Slot } = {}

local function keyName(action: ActionName): string
	local binding = InputBindings[action]
	local inputs: { any } = if InputController:GetInputMode() == "Gamepad"
		then binding.Gamepad
		else binding.KeyboardMouse
	local input = inputs[1]
	if input == nil then
		return ""
	end
	return SHORT_NAMES[input.Name] or input.Name
end

local function refreshKeys(): ()
	for action: ActionName, slot in slots do
		slot.Key.Text = keyName(action)
	end
end

local function buildSlot(parent: Instance, definition: SlotDefinition, order: number): Slot
	local frame = UIUtil.create("TextButton", {
		Name = definition.Action,
		Text = "",
		AutoButtonColor = true,
		Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.2,
		LayoutOrder = order,
		ClipsDescendants = true,
		Parent = parent,
	}, {
		UIUtil.create("UIStroke", { Color = Theme.Colors.Accent, Thickness = 1.5, Transparency = 0.3 }),
	})
	UIUtil.label({
		Text = definition.Label,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 14),
		ZIndex = 3,
		Parent = frame,
	})
	local key = UIUtil.label({
		Text = "",
		TextSize = 20,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = 3,
		Parent = frame,
	})
	-- Oscurece la casilla de abajo arriba mientras dura el cooldown.
	local overlay = UIUtil.create("Frame", {
		Name = "Cooldown",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = frame,
	})
	local timer = UIUtil.label({
		Text = "",
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = frame,
	})
	frame.Activated:Connect(function()
		InputController:Trigger(definition.Action)
	end)
	return { Frame = frame, Key = key, Overlay = overlay, Timer = timer, ReadyAt = 0, Duration = 0 }
end

local function onCooldownStarted(action: CombatAction, seconds: number): ()
	local slot = slots[action :: ActionName]
	if slot ~= nil then
		slot.ReadyAt = os.clock() + seconds
		slot.Duration = seconds
	end
end

local function update(): ()
	local now = os.clock()
	for _, slot in slots do
		local remaining = slot.ReadyAt - now
		if remaining > 0 and slot.Duration > 0 then
			slot.Overlay.Size = UDim2.fromScale(1, remaining / slot.Duration)
			slot.Timer.Text = string.format("%.1f", remaining)
		elseif slot.Timer.Text ~= "" then
			slot.Overlay.Size = UDim2.fromScale(1, 0)
			slot.Timer.Text = ""
		end
	end
end

-- Casillas según el moveset de la raza del jugador: pesado, esquiva, movimiento
-- y sus técnicas (D-034). El nombre sale de Content/AbilityInfo.
local function currentSlots(): { SlotDefinition }
	local data = PlayerDataController:GetData()
	local race = if data ~= nil then Races.Definitions[data.Race] else nil
	local moveset = Movesets[if race ~= nil then race.Kit.Moveset else "Default"]
	if moveset == nil then
		return {}
	end

	local result: { SlotDefinition } = {}
	local function add(action: ActionName, abilityId: string?): ()
		if abilityId ~= nil then
			local info = AbilityInfo[abilityId]
			local label = if info ~= nil then info.DisplayName else abilityId
			table.insert(result, { Action = action, Label = string.upper(label) })
		end
	end
	add("HeavyAttack", moveset.HeavyAttack)
	add("Dodge", moveset.Dodge)
	add("Dash", moveset.Dash)
	for index, skill in moveset.Skills do
		local action: ActionName? = SKILL_ACTIONS[index]
		if action ~= nil then
			add(action, skill)
		end
	end
	return result
end

local function rebuildSlots(): ()
	for _, slot in slots do
		slot.Frame:Destroy()
	end
	table.clear(slots)
	for order, definition in currentSlots() do
		slots[definition.Action] = buildSlot(bar, definition, order)
	end
	refreshKeys()
end

local ActionBarController = {
	Name = "ActionBarController",
}

function ActionBarController:Start(): ()
	gui = UIUtil.create("ScreenGui", {
		Name = "ActionBar",
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	bar = UIUtil.create("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(0, SLOT_SIZE),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UIUtil.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})
	rebuildSlots()
	PlayerDataController.Loaded:Connect(rebuildSlots)
	PlayerDataController.Changed:Connect(function(key)
		if key == "Race" then
			rebuildSlots()
		end
	end)
	InputController.InputModeChanged:Connect(refreshKeys)
	CombatController.CooldownStarted:Connect(onCooldownStarted)
	RunService.Heartbeat:Connect(update)
end

return ActionBarController
