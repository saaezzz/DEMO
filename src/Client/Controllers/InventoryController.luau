--!strict

-- Mochila (§46, §52, D-036): casillas con el color de su rareza (pauta D-023),
-- detalle del objeto seleccionado y botón "Usar" para los consumibles. Se abre
-- con la acción Inventory (B) o con el botón "MOCHILA" de la pantalla (táctil
-- y mando). Solo muestra lo que replica el servidor y le pide usar objetos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerDataTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)
local Items = require(ReplicatedStorage.Shared.Content.Items)
local AssetLibrary = require(ReplicatedStorage.Shared.Modules.AssetLibrary)

local ClientNetwork = require(script.Parent.Parent.Network.ClientNetwork)
local InputController = require(script.Parent.InputController)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)
local PlayerDataController = require(script.Parent.PlayerDataController)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type RequestResponse = GameTypes.RequestResponse
type InventoryItem = PlayerDataTypes.InventoryItem
type ActionName = InputBindings.ActionName

local SLOT_SIZE = 64

-- Nombres de categoría para el detalle.
local CATEGORY_NAMES: { [string]: string } = {
	Weapon = "Arma",
	Consumable = "Consumible",
	QuestItem = "Objeto de misión",
	Material = "Material",
	Accessory = "Accesorio",
	Cosmetic = "Cosmético",
	TransformationItem = "Objeto de transformación",
}

local panel: Frame
local grid: ScrollingFrame
local detailName: TextLabel
local detailInfo: TextLabel
local detailDescription: TextLabel
local useButton: TextButton
local status: TextLabel
local selectedItem: string? = nil

-- "Bálsamo curativo" → "BC": se muestra mientras la casilla no tenga icono.
local function initials(name: string): string
	local letters = ""
	for word in string.gmatch(name, "%S+") do
		if #letters < 2 and #word > 2 then
			letters ..= string.upper(string.sub(word, 1, 1))
		end
	end
	return letters
end

local function rarityColor(itemId: string): Color3
	local item = Items[itemId]
	local rarity = if item ~= nil then ItemConfig.Rarities[item.Rarity] else nil
	return Color3.fromHex(if rarity ~= nil then rarity.Color else "#FFFFFF")
end

local function showDetails(itemId: string?): ()
	selectedItem = itemId
	status.Text = ""
	local item = if itemId ~= nil then Items[itemId] else nil
	if item == nil then
		detailName.Text = "Selecciona un objeto"
		detailName.TextColor3 = Theme.Colors.TextDim
		detailInfo.Text = ""
		detailDescription.Text = ""
		useButton.Visible = false
		return
	end
	local rarity = ItemConfig.Rarities[item.Rarity]
	detailName.Text = item.DisplayName
	detailName.TextColor3 = rarityColor(item.Id)
	detailInfo.Text = `{rarity.DisplayName} · {CATEGORY_NAMES[item.Category] or item.Category}`
	detailDescription.Text = item.Description
	useButton.Visible = item.Use ~= nil
end

local function buildSlot(itemId: string, quantity: number, order: number): ()
	local item = Items[itemId]
	local slot = UIUtil.create("TextButton", {
		Name = itemId,
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Theme.Colors.BarBack,
		LayoutOrder = order,
		Parent = grid,
	}, {
		UIUtil.create("UIStroke", { Color = rarityColor(itemId), Thickness = 2 }),
	})
	local icon = if item ~= nil and item.Icon ~= nil then AssetLibrary.GetContentId(item.Icon) else nil
	if icon ~= nil then
		UIUtil.create("ImageLabel", {
			Image = icon,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = slot,
		})
	else
		UIUtil.label({
			Text = initials(if item ~= nil then item.DisplayName else itemId),
			TextSize = 24,
			TextColor3 = rarityColor(itemId),
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = slot,
		})
	end
	UIUtil.label({
		Text = if quantity > 1 then `x{quantity}` else "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -1),
		Size = UDim2.new(1, 0, 0, 16),
		Parent = slot,
	})
	slot.Activated:Connect(function()
		showDetails(itemId)
	end)
end

local function render(): ()
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	local data = PlayerDataController:GetData()
	local inventory: { InventoryItem } = if data ~= nil then data.Inventory else {}
	local stillHasSelected = false
	for order, slot in inventory do
		buildSlot(slot.Id, slot.Quantity, order)
		stillHasSelected = stillHasSelected or slot.Id == selectedItem
	end
	if not stillHasSelected then
		showDetails(nil)
	end
end

local function useSelected(): ()
	local itemId = selectedItem
	if itemId == nil then
		return
	end
	local response: RequestResponse? = ClientNetwork.Invoke("UseItem", { ItemId = itemId })
	if response == nil or response.Status ~= "Accepted" then
		status.Text = if response ~= nil and response.Message ~= nil then response.Message else "No se pudo usar"
	else
		status.Text = "¡Usado!"
	end
end

local function toggle(): ()
	panel.Visible = not panel.Visible
	if panel.Visible then
		render()
	end
end

local function buildPanel(gui: ScreenGui): ()
	panel = UIUtil.create("Frame", {
		Name = "Inventory",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 380),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.08,
		Visible = false,
		Parent = gui,
	}, {
		UIUtil.create("UIStroke", { Color = Theme.Colors.Accent, Thickness = 2 }),
	})
	UIUtil.label({
		Text = "MOCHILA",
		TextSize = 26,
		TextColor3 = Theme.Colors.Accent,
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -60, 0, 32),
		Parent = panel,
	})
	local close = UIUtil.create("TextButton", {
		Text = "X",
		FontFace = Theme.FontBold,
		TextSize = 22,
		TextColor3 = Theme.Colors.Text,
		BackgroundColor3 = Theme.Colors.BarBack,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(32, 32),
		Parent = panel,
	})
	close.Activated:Connect(toggle)

	grid = UIUtil.create("ScrollingFrame", {
		Name = "Grid",
		Position = UDim2.fromOffset(16, 48),
		Size = UDim2.new(0, 370, 1, -64),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		UIUtil.create("UIGridLayout", {
			CellSize = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local details = UIUtil.create("Frame", {
		Name = "Details",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 48),
		Size = UDim2.new(0, 190, 1, -64),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	detailName = UIUtil.label({
		Text = "",
		TextSize = 22,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = details,
	})
	detailInfo = UIUtil.label({
		Text = "",
		TextSize = 14,
		FontFace = Theme.FontRegular,
		TextColor3 = Theme.Colors.TextDim,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = details,
	})
	detailDescription = UIUtil.label({
		Text = "",
		TextSize = 16,
		FontFace = Theme.FontRegular,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 1, -170),
		Parent = details,
	})
	useButton = UIUtil.create("TextButton", {
		Text = "USAR",
		FontFace = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Theme.Colors.Panel,
		BackgroundColor3 = Theme.Colors.Accent,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -28),
		Size = UDim2.new(1, 0, 0, 40),
		Visible = false,
		Parent = details,
	})
	useButton.Activated:Connect(function()
		task.spawn(useSelected)
	end)
	status = UIUtil.label({
		Text = "",
		TextSize = 14,
		FontFace = Theme.FontRegular,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 22),
		Parent = details,
	})
	showDetails(nil)
end

local InventoryController = {
	Name = "InventoryController",
}

function InventoryController:Start(): ()
	local gui = UIUtil.create("ScreenGui", {
		Name = "Inventory",
		ResetOnSpawn = false,
		DisplayOrder = 8,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	buildPanel(gui)

	-- Botón en pantalla para táctil y mando (y también con ratón).
	local openButton = UIUtil.create("TextButton", {
		Name = "OpenInventory",
		Text = "MOCHILA",
		FontFace = Theme.FontBold,
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.2,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.6, 0),
		Size = UDim2.fromOffset(96, 34),
		Parent = gui,
	}, {
		UIUtil.create("UIStroke", { Color = Theme.Colors.Accent, Thickness = 1.5 }),
	})
	openButton.Activated:Connect(toggle)

	InputController.ActionBegan:Connect(function(action: ActionName)
		if action == "Inventory" then
			toggle()
		end
	end)
	PlayerDataController.Changed:Connect(function(key)
		if key == "Inventory" and panel.Visible then
			render()
		end
	end)
end

return InventoryController
