--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local ComboAnimations = require(ReplicatedStorage.Shared.Content.ComboAnimations)

local ClientNetwork = require(script.Parent.Parent.Network.ClientNetwork)
local InputController = require(script.Parent.InputController)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)

type CombatIntent = GameTypes.CombatIntent
type CombatIntentType = GameTypes.CombatIntentType
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ActionName = InputBindings.ActionName

local ANIMATOR_TIMEOUT_SECONDS = 5

-- Provisional hasta el framework de habilidades (M2), que asignará el combo
-- según el arma/kit equipado.
local ATTACK_COMBO_ID = "BasicSlash"

local player = Players.LocalPlayer
local animator: Animator? = nil
-- Tracks cargados en el Animator actual, por combo. Se vacía al cambiar de personaje.
local comboTracks: { [string]: AnimationTrack } = {}
local currentTrack: AnimationTrack? = nil

-- Cede el hilo mientras espera al servidor: no llamar directamente desde un
-- handler de Signal (D-013), usar task.spawn.
local function sendIntent(intentType: CombatIntentType, comboId: string?, active: boolean?): ServerCombatResponse
	local intent: CombatIntent = {
		Type = intentType,
		ComboId = comboId,
		Active = active,
	}

	-- nil = rechazado por la capa de red (rate limit, payload inválido) o fallo de comunicación.
	local response: ServerCombatResponse? = ClientNetwork.Invoke("CombatIntent", intent)
	if response == nil then
		return { Status = "Rejected", Message = nil }
	end
	return response
end

local function getComboTrack(currentAnimator: Animator, comboId: string): AnimationTrack?
	local cached: AnimationTrack? = comboTracks[comboId]
	if cached ~= nil then
		return cached
	end

	local animationId: string? = ComboAnimations[comboId]
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

-- Los handlers de Signal no deben ceder: cada petición al servidor va en su propio hilo.
local function onActionBegan(action: ActionName): ()
	if action == "LightAttack" then
		task.spawn(onAttackInput)
	elseif action == "Block" then
		task.spawn(function()
			sendIntent("Block", nil, true)
		end)
	elseif action == "Dash" then
		task.spawn(function()
			sendIntent("Dash", nil, nil)
		end)
	end
end

local function onActionEnded(action: ActionName): ()
	if action == "Block" then
		task.spawn(function()
			sendIntent("Block", nil, false)
		end)
	end
end

local CombatController = {
	Name = "CombatController",
}

function CombatController:Start(): ()
	player.CharacterAdded:Connect(bindCharacter)
	InputController.ActionBegan:Connect(onActionBegan)
	InputController.ActionEnded:Connect(onActionEnded)

	local existingModel = player.Character
	if existingModel ~= nil then
		task.spawn(bindCharacter, existingModel)
	end
end

return CombatController
