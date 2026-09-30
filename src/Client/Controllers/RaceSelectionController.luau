--!strict

-- Pantalla de elección de raza (D-034). Aparece mientras el personaje tenga la
-- raza por defecto. Las razas salen de Content/Races: las que aún no están
-- disponibles (Playable = false) se muestran como "Próximamente".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Races = require(ReplicatedStorage.Shared.Content.Races)

local ClientNetwork = require(script.Parent.Parent.Network.ClientNetwork)
local PlayerDataController = require(script.Parent.PlayerDataController)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

type RequestResponse = GameTypes.RequestResponse

local CARD_WIDTH = 230

local gui: ScreenGui
local status: TextLabel
local choosing = false

local function choose(raceId: string): ()
	if choosing then
		return
	end
	choosing = true
	status.Text = "…"
	local response: RequestResponse? = ClientNetwork.Invoke("ChooseRace", { Race = raceId })
	choosing = false
	if response == nil or response.Status ~= "Accepted" then
		status.Text = if response ~= nil and response.Message ~= nil then response.Message else "No se pudo elegir"
	end
	-- Si se aceptó, el cambio de Race en los datos cierra la pantalla.
end

local function buildCard(parent: Instance, raceId: string, order: number): ()
	local race = Races.Definitions[raceId]
	local card = UIUtil.create("Frame", {
		Name = raceId,
		Size = UDim2.fromOffset(CARD_WIDTH, 300),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.1,
		LayoutOrder = order,
		Parent = parent,
	}, {
		UIUtil.create("UIStroke", {
			Color = if race.Playable then Theme.Colors.Accent else Theme.Colors.TextDim,
			Thickness = 2,
		}),
		UIUtil.create("UIPadding", {
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
	})
	UIUtil.label({
		Text = string.upper(race.DisplayName),
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = if race.Playable then Theme.Colors.Text else Theme.Colors.TextDim,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = card,
	})
	UIUtil.label({
		Text = race.Description,
		TextSize = 16,
		FontFace = Theme.FontRegular,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Theme.Colors.TextDim,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -110),
		Parent = card,
	})
	local button = UIUtil.create("TextButton", {
		Text = if race.Playable then "ELEGIR" else "PRÓXIMAMENTE",
		FontFace = Theme.FontBold,
		TextSize = 20,
		TextColor3 = if race.Playable then Theme.Colors.Panel else Theme.Colors.TextDim,
		BackgroundColor3 = if race.Playable then Theme.Colors.Accent else Theme.Colors.BarBack,
		AutoButtonColor = race.Playable,
		Active = race.Playable,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 44),
		Parent = card,
	})
	if race.Playable then
		button.Activated:Connect(function()
			task.spawn(choose, raceId)
		end)
	end
end

-- Jugables primero y después por nombre, para que el orden no dependa del contenido.
local function sortedRaces(): { string }
	local ids: { string } = {}
	for raceId in Races.Definitions do
		if raceId ~= Races.Default then
			table.insert(ids, raceId)
		end
	end
	table.sort(ids, function(a, b)
		local raceA, raceB = Races.Definitions[a], Races.Definitions[b]
		if raceA.Playable ~= raceB.Playable then
			return raceA.Playable
		end
		return raceA.DisplayName < raceB.DisplayName
	end)
	return ids
end

local function refresh(): ()
	local data = PlayerDataController:GetData()
	gui.Enabled = data ~= nil and data.Race == Races.Default
end

local RaceSelectionController = {
	Name = "RaceSelectionController",
}

function RaceSelectionController:Start(): ()
	gui = UIUtil.create("ScreenGui", {
		Name = "RaceSelection",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		Enabled = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	UIUtil.create("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Parent = gui,
	})
	UIUtil.label({
		Text = "ELIGE TU CAMINO",
		TextSize = 44,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.new(1, 0, 0, 50),
		Parent = gui,
	})
	local row = UIUtil.create("Frame", {
		Name = "Races",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(0, 300),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UIUtil.create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 16),
		}),
	})
	for order, raceId in sortedRaces() do
		buildCard(row, raceId, order)
	end
	status = UIUtil.label({
		Text = "",
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.85),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = gui,
	})
	-- En pantallas estrechas (móvil) las tarjetas se reducen para que quepan.
	local scale = UIUtil.create("UIScale", { Parent = row })
	local function fit(): ()
		local camera = Workspace.CurrentCamera
		local needed = #row:GetChildren() * (CARD_WIDTH + 16)
		if camera ~= nil and needed > 0 then
			scale.Scale = math.min(1, (camera.ViewportSize.X - 32) / needed)
		end
	end
	fit()
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	PlayerDataController.Loaded:Connect(refresh)
	PlayerDataController.Changed:Connect(function(key)
		if key == "Race" then
			refresh()
		end
	end)
	refresh()
end

return RaceSelectionController
