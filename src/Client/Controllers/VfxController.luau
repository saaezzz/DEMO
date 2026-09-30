--!strict

-- Efectos visuales de las habilidades y avisos de área (§17 VFXService, D-035).
-- Escucha los atributos replicados de cada personaje (D-021): al empezar una
-- habilidad reproduce sus efectos (Content/AbilityInfo) y, ante un aviso de
-- ataque en área, dibuja el círculo en el suelo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityInfo = require(ReplicatedStorage.Shared.Content.AbilityInfo)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

local CharacterWatcher = require(script.Parent.Parent.Utils.CharacterWatcher)
local EffectPlayer = require(script.Parent.Parent.Vfx.EffectPlayer)

local AREA_TELEGRAPH_EFFECT = "Telegraph.Area"

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function onAbilityStarted(model: Model): ()
	local abilityId = model:GetAttribute(ReplicatedAttributes.ACTION_ID)
	local info = if typeof(abilityId) == "string" then AbilityInfo[abilityId] else nil
	if info == nil or info.Effects == nil then
		return
	end
	for _, effect in info.Effects do
		task.delay(effect.Delay, function()
			-- Desde donde esté y hacia donde mire en ese momento.
			local root = getRoot(model)
			if root ~= nil then
				EffectPlayer.Play(effect.Effect, root.CFrame, { Attach = model })
			end
		end)
	end
end

local function onTelegraph(model: Model): ()
	local radius = model:GetAttribute(ReplicatedAttributes.TELEGRAPH_RADIUS)
	local seconds = model:GetAttribute(ReplicatedAttributes.TELEGRAPH_SECONDS)
	local root = getRoot(model)
	if root == nil or typeof(radius) ~= "number" or radius <= 0 then
		return
	end
	EffectPlayer.Play(AREA_TELEGRAPH_EFFECT, root.CFrame, {
		Radius = radius,
		Duration = if typeof(seconds) == "number" then seconds else nil,
		Ignore = { model :: Instance },
	})
end

local function onCharacter(_player: Player?, model: Model): CharacterWatcher.Cleanup?
	local connections = {
		model:GetAttributeChangedSignal(ReplicatedAttributes.ACTION_SEQ):Connect(function()
			onAbilityStarted(model)
		end),
		model:GetAttributeChangedSignal(ReplicatedAttributes.TELEGRAPH):Connect(function()
			onTelegraph(model)
		end),
	}
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end
end

local VfxController = {
	Name = "VfxController",
}

function VfxController:Start(): ()
	CharacterWatcher.Observe(onCharacter)
end

return VfxController
