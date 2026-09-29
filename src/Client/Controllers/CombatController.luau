--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatRemotes = require(ReplicatedStorage.Shared.Network.CombatRemotes)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local ClientComboCatalog = require(ReplicatedStorage.Shared.Combos.ClientComboCatalog)

type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse
type CombatIntentType = "Attack" | "Block" | "Shunpo" | "CastAbility"

export type ComboHitMarkerCallback = (comboId: string, markerName: string) -> ()

export type CombatController = {
	OnComboHitMarker: (self: CombatController, callback: ComboHitMarkerCallback) -> RBXScriptConnection,
	Init: (self: CombatController) -> (),
	Destroy: (self: CombatController) -> (),
}

type CombatControllerInternal = CombatController & {
	_player: Player,
	_humanoid: Humanoid?,
	_animator: Animator?,
	_currentTrack: AnimationTrack?,
	_markerConnection: RBXScriptConnection?,
	_hitMarkerEvent: BindableEvent,
	_isBlocking: boolean,
	_connections: { RBXScriptConnection },
}

local ATTACK_COMBO_ID = "BasicSlash"
local ATTACK_KEY = Enum.UserInputType.MouseButton1
local BLOCK_KEY = Enum.KeyCode.F
local SHUNPO_KEY = Enum.KeyCode.Q

local CombatController: CombatControllerInternal = {} :: CombatControllerInternal
CombatController.__index = CombatController :: any

local hitMarkerEvent = Instance.new("BindableEvent")

CombatController._player = Players.LocalPlayer
CombatController._humanoid = nil
CombatController._animator = nil
CombatController._currentTrack = nil
CombatController._markerConnection = nil
CombatController._hitMarkerEvent = hitMarkerEvent
CombatController._isBlocking = false
CombatController._connections = {}

local function buildIntent(intentType: CombatIntentType, comboId: string?): CombatIntent
	return {
		Type = intentType,
		ComboId = comboId,
		AbilityId = nil,
		TargetDirection = nil,
		ClientTimestamp = os.clock(),
	}
end

local function sendIntent(intent: CombatIntent): ServerCombatResponse
	local ok, result = pcall(function()
		return CombatRemotes.CombatIntent:InvokeServer(intent)
	end)

	if not ok then
		return {
			Status = "Rejected",
			Message = "Fallo de comunicación con el servidor",
			AppliedDamage = nil,
			TargetUserId = nil,
		}
	end

	return result :: ServerCombatResponse
end

local function playComboAnimation(self: CombatControllerInternal, comboId: string)
	local animator = self._animator
	if animator == nil then
		return
	end

	local animationId = ClientComboCatalog[comboId]
	if animationId == nil then
		return
	end

	if self._currentTrack ~= nil then
		self._currentTrack:Stop()
	end
	if self._markerConnection ~= nil then
		self._markerConnection:Disconnect()
		self._markerConnection = nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local track = animator:LoadAnimation(animation)
	self._currentTrack = track

	self._markerConnection = track:GetMarkerReachedSignal("Hit1"):Connect(function()
		self._hitMarkerEvent:Fire(comboId, "Hit1")
	end)

	track:Play()
end

local function onAttackInput(self: CombatControllerInternal)
	local response = sendIntent(buildIntent("Attack", ATTACK_COMBO_ID))
	if response.Status == "Accepted" then
		playComboAnimation(self, ATTACK_COMBO_ID)
	end
end

local function onBlockInput(self: CombatControllerInternal)
	local response = sendIntent(buildIntent("Block", nil))
	if response.Status == "Accepted" then
		self._isBlocking = not self._isBlocking
	end
end

local function onShunpoInput(_self: CombatControllerInternal)
	sendIntent(buildIntent("Shunpo", nil))
end

local function bindCharacter(self: CombatControllerInternal, model: Model)
	local humanoid = model:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid == nil then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator == nil then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	self._humanoid = humanoid
	self._animator = animator
end

function CombatController:OnComboHitMarker(callback: ComboHitMarkerCallback): RBXScriptConnection
	local self = (self :: any) :: CombatControllerInternal
	local connection = self._hitMarkerEvent.Event:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function CombatController:Init(): ()
	local self = (self :: any) :: CombatControllerInternal

	local player = self._player
	if player.Character ~= nil then
		bindCharacter(self, player.Character)
	end
	table.insert(
		self._connections,
		player.CharacterAdded:Connect(function(model)
			bindCharacter(self, model)
		end)
	)

	table.insert(
		self._connections,
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.UserInputType == ATTACK_KEY then
				onAttackInput(self)
			elseif input.KeyCode == BLOCK_KEY then
				onBlockInput(self)
			elseif input.KeyCode == SHUNPO_KEY then
				onShunpoInput(self)
			end
		end)
	)
end

function CombatController:Destroy(): ()
	local self = (self :: any) :: CombatControllerInternal

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._markerConnection ~= nil then
		self._markerConnection:Disconnect()
		self._markerConnection = nil
	end

	if self._currentTrack ~= nil then
		self._currentTrack:Stop()
		self._currentTrack = nil
	end

	self._hitMarkerEvent:Destroy()
end

return (CombatController :: any) :: CombatController
