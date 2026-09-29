--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatRemotes = require(ReplicatedStorage.Shared.Network.CombatRemotes)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local ClientComboCatalog = require(ReplicatedStorage.Shared.Combos.ClientComboCatalog)

type CombatIntent = GameTypes.CombatIntent
type CombatIntentType = GameTypes.CombatIntentType
type ServerCombatResponse = GameTypes.ServerCombatResponse

local ANIMATOR_TIMEOUT_SECONDS = 5

-- Provisional hasta InputService (tarea 10 del roadmap): solo teclado y ratón.
local ATTACK_INPUT = Enum.UserInputType.MouseButton1
local BLOCK_KEY = Enum.KeyCode.F
local SHUNPO_KEY = Enum.KeyCode.Q
local ATTACK_COMBO_ID = "BasicSlash"

local player = Players.LocalPlayer
local animator: Animator? = nil
-- Tracks cargados en el Animator actual, por combo. Se vacía al cambiar de personaje.
local comboTracks: { [string]: AnimationTrack } = {}
local currentTrack: AnimationTrack? = nil
local connections: { RBXScriptConnection } = {}

local function sendIntent(intentType: CombatIntentType, comboId: string?): ServerCombatResponse
	local intent: CombatIntent = {
		Type = intentType,
		ComboId = comboId,
	}

	local ok, result = pcall(function()
		return CombatRemotes.CombatIntent:InvokeServer(intent)
	end)
	if not ok then
		return {
			Status = "Rejected",
			Message = "Fallo de comunicación con el servidor",
		}
	end

	return result :: ServerCombatResponse
end

local function getComboTrack(currentAnimator: Animator, comboId: string): AnimationTrack?
	local cached: AnimationTrack? = comboTracks[comboId]
	if cached ~= nil then
		return cached
	end

	local animationId: string? = ClientComboCatalog[comboId]
	if animationId == nil then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local track = currentAnimator:LoadAnimation(animation)
	comboTracks[comboId] = track
	return track
end

local function playComboAnimation(comboId: string): ()
	local currentAnimator = animator
	if currentAnimator == nil then
		return
	end

	local track = getComboTrack(currentAnimator, comboId)
	if track == nil then
		return
	end

	if currentTrack ~= nil and currentTrack ~= track then
		currentTrack:Stop()
	end
	currentTrack = track
	track:Play()
end

local function onAttackInput(): ()
	local response = sendIntent("Attack", ATTACK_COMBO_ID)
	if response.Status == "Accepted" then
		playComboAnimation(ATTACK_COMBO_ID)
	end
end

local function bindCharacter(model: Model): ()
	-- Los tracks del personaje anterior pertenecen a un Animator destruido.
	table.clear(comboTracks)
	currentTrack = nil
	animator = nil

	local humanoid = model:WaitForChild("Humanoid", ANIMATOR_TIMEOUT_SECONDS) :: Humanoid?
	if humanoid == nil then
		return
	end

	-- El Animator lo crea el servidor; uno creado en el cliente no replicaría las animaciones.
	local foundAnimator = humanoid:WaitForChild("Animator", ANIMATOR_TIMEOUT_SECONDS) :: Animator?
	if foundAnimator ~= nil and player.Character == model then
		animator = foundAnimator
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then
		return
	end

	if input.UserInputType == ATTACK_INPUT then
		onAttackInput()
	elseif input.KeyCode == BLOCK_KEY then
		sendIntent("Block", nil)
	elseif input.KeyCode == SHUNPO_KEY then
		sendIntent("Shunpo", nil)
	end
end

local CombatController = {}

function CombatController:Init(): ()
	table.insert(connections, player.CharacterAdded:Connect(bindCharacter))
	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))

	local existingModel = player.Character
	if existingModel ~= nil then
		task.spawn(bindCharacter, existingModel)
	end
end

function CombatController:Destroy(): ()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	if currentTrack ~= nil then
		currentTrack:Stop()
		currentTrack = nil
	end
	table.clear(comboTracks)
	animator = nil
end

return CombatController
