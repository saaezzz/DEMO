--!strict

-- Barra de estadística (vida, postura, recursos) con relleno animado y una
-- "barra fantasma" que muestra durante un momento lo que se acaba de perder.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local UIUtil = require(script.Parent.UIUtil)

local FILL_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GHOST_TWEEN = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.3)

export type StatBarOptions = {
	Parent: Instance,
	Color: Color3,
	Height: number,
	LayoutOrder: number?,
	-- Texto a la izquierda (p. ej. "PV"); nil = sin textos.
	Label: string?,
	-- Muestra "actual / máximo" a la derecha.
	ShowValue: boolean?,
}

local StatBar = {}
StatBar.__index = StatBar

type StatBarData = {
	Frame: Frame,
	_fill: Frame,
	_ghost: Frame,
	_valueLabel: TextLabel?,
	_ratio: number,
}

export type StatBar = typeof(setmetatable({} :: StatBarData, StatBar))

function StatBar.new(options: StatBarOptions): StatBar
	local ghost = UIUtil.create("Frame", {
		Name = "Ghost",
		BackgroundColor3 = Theme.Colors.Ghost,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	})
	local fill = UIUtil.create("Frame", {
		Name = "Fill",
		BackgroundColor3 = options.Color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	}, {
		-- Brillo superior para que no parezca un rectángulo plano.
		UIUtil.create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)),
		}),
	})

	local frame = UIUtil.create("Frame", {
		Name = "StatBar",
		BackgroundColor3 = Theme.Colors.BarBack,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, options.Height),
		LayoutOrder = options.LayoutOrder or 0,
		ClipsDescendants = true,
		Parent = options.Parent,
	}, {
		ghost,
		fill,
		UIUtil.create("UIStroke", { Color = Theme.Colors.Stroke, Thickness = 1, Transparency = 0.2 }),
	})

	local valueLabel: TextLabel? = nil
	if options.Label ~= nil then
		UIUtil.label({
			Text = options.Label,
			TextSize = options.Height - 2,
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			ZIndex = 3,
			Parent = frame,
		})
	end
	if options.ShowValue then
		valueLabel = UIUtil.label({
			Text = "",
			TextSize = options.Height - 2,
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(0.5, -6, 1, 0),
			Position = UDim2.fromScale(0.5, 0),
			ZIndex = 3,
			Parent = frame,
		})
	end

	return setmetatable({
		Frame = frame,
		_fill = fill,
		_ghost = ghost,
		_valueLabel = valueLabel,
		_ratio = 1,
	}, StatBar)
end

function StatBar.SetValue(self: StatBar, current: number, max: number): ()
	local ratio = if max > 0 then math.clamp(current / max, 0, 1) else 0
	local size = UDim2.fromScale(ratio, 1)
	TweenService:Create(self._fill, FILL_TWEEN, { Size = size }):Play()
	if ratio < self._ratio then
		TweenService:Create(self._ghost, GHOST_TWEEN, { Size = size }):Play()
	else
		self._ghost.Size = size
	end
	self._ratio = ratio

	local valueLabel = self._valueLabel
	if valueLabel ~= nil then
		valueLabel.Text = string.format("%d / %d", math.ceil(current), math.ceil(max))
	end
end

function StatBar.SetColor(self: StatBar, color: Color3): ()
	self._fill.BackgroundColor3 = color
end

function StatBar.GetRatio(self: StatBar): number
	return self._ratio
end

function StatBar.Destroy(self: StatBar): ()
	self.Frame:Destroy()
end

return StatBar
