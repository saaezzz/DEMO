--!strict

-- Respuesta visual al recibir daño (D-022): destello blanco en el personaje y
-- número de daño flotante; y aviso rojo antes de un ataque enemigo (D-023).
-- Local a cada cliente, a partir de la vida y los atributos replicados.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local CharacterWatcher = require(script.Parent.Parent.Utils.CharacterWatcher)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIUtil = require(script.Parent.Parent.UI.UIUtil)

local PARTS_TIMEOUT_SECONDS = 5
local FLASH_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TELEGRAPH_TWEEN = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local NUMBER_LIFETIME_SECONDS = 0.8
local NUMBER_RISE_STUDS = 2.5
-- Daño por debajo de esto (regeneración, redondeos) no se muestra.
local MIN_DISPLAYED_DAMAGE = 0.5

local localPlayer = Players.LocalPlayer

local function spawnDamageNumber(rootPart: BasePart, amount: number, isSelf: boolean): ()
	-- Desplazamiento lateral aleatorio para que golpes seguidos no se tapen.
	local startOffset = Vector3.new((math.random() - 0.5) * 2, 2, 0)
	local billboard = UIUtil.create("BillboardGui", {
		Name = "DamageNumber",
		Adornee = rootPart,
		Size = UDim2.fromOffset(90, 40),
		StudsOffset = startOffset,
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = localPlayer:FindFirstChildOfClass("PlayerGui"),
	})
	local label = UIUtil.label({
		Text = tostring(math.floor(amount + 0.5)),
		TextSize = if isSelf then 26 else 30,
		TextColor3 = if isSelf then Theme.Colors.DamageSelf else Theme.Colors.DamageOther,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = billboard,
	})

	local tweenInfo = TweenInfo.new(NUMBER_LIFETIME_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, tweenInfo, { StudsOffset = startOffset + Vector3.new(0, NUMBER_RISE_STUDS, 0) })
		:Play()
	TweenService:Create(label, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(NUMBER_LIFETIME_SECONDS, function()
		billboard:Destroy()
	end)
end

local function onCharacter(player: Player?, model: Model): CharacterWatcher.Cleanup?
	local humanoid = model:WaitForChild("Humanoid", PARTS_TIMEOUT_SECONDS) :: Humanoid?
	local rootPart = model:WaitForChild("HumanoidRootPart", PARTS_TIMEOUT_SECONDS) :: BasePart?
	if humanoid == nil or rootPart == nil then
		return nil
	end

	local highlight = UIUtil.create("Highlight", {
		Name = "HitFlash",
		Adornee = model,
		FillColor = Color3.new(1, 1, 1),
		FillTransparency = 1,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Parent = model,
	})

	local isSelf = player == localPlayer
	local lastHealth = humanoid.Health
	local connections = {
		humanoid.HealthChanged:Connect(function(health: number)
			local damage = lastHealth - health
			lastHealth = health
			if damage < MIN_DISPLAYED_DAMAGE then
				return
			end
			highlight.FillColor = Color3.new(1, 1, 1)
			highlight.FillTransparency = 0.3
			highlight.OutlineTransparency = 1
			TweenService:Create(highlight, FLASH_TWEEN, { FillTransparency = 1 }):Play()
			spawnDamageNumber(rootPart, damage, isSelf)
		end),

		-- Aviso de ataque de un enemigo (D-023): contorno rojo que se apaga.
		model:GetAttributeChangedSignal(ReplicatedAttributes.TELEGRAPH):Connect(function()
			highlight.FillColor = Theme.Colors.Telegraph
			highlight.OutlineColor = Theme.Colors.Telegraph
			highlight.FillTransparency = 0.55
			highlight.OutlineTransparency = 0
			TweenService:Create(highlight, TELEGRAPH_TWEEN, { FillTransparency = 1, OutlineTransparency = 1 }):Play()
		end),
	}

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
		highlight:Destroy()
	end
end

local HitFeedbackController = {
	Name = "HitFeedbackController",
}

function HitFeedbackController:Start(): ()
	CharacterWatcher.Observe(onCharacter)
end

return HitFeedbackController
