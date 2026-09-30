--!strict

-- Traduce las acciones de input en intents de combate para el servidor (D-025).
-- El cliente pide acciones; el servidor decide la habilidad y el resultado.
-- Las animaciones las pone CharacterAnimationController a partir del estado
-- replicado (D-021, D-022).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

local ClientNetwork = require(script.Parent.Parent.Network.ClientNetwork)
local InputController = require(script.Parent.InputController)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)
local MovementController = require(script.Parent.MovementController)

type CombatAction = GameTypes.CombatAction
type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ActionName = InputBindings.ActionName

-- Reintentos de una acción mantenida en cooldown (cubren BlockCooldownSeconds).
local HOLD_RETRY_SECONDS = 0.15
local HOLD_RETRY_ATTEMPTS = 5

-- Acciones que se envían al pulsar.
local PRESS_ACTIONS: { [ActionName]: CombatAction } = {
	LightAttack = "LightAttack",
	HeavyAttack = "HeavyAttack",
	Dodge = "Dodge",
	Dash = "Dash",
	Ability1 = "Ability1",
	Ability2 = "Ability2",
	Ability3 = "Ability3",
	Ability4 = "Ability4",
}

-- Acciones que se mantienen: se envían al pulsar (Active = true) y al soltar.
local HOLD_ACTIONS: { [ActionName]: CombatAction } = {
	Block = "Block",
	Sprint = "Sprint",
}

local CombatController = {
	Name = "CombatController",
	-- (acción, segundos) cuando el servidor acepta una habilidad con cooldown.
	CooldownStarted = Signal.new() :: Signal.Signal<CombatAction, number>,
}

-- Cede el hilo mientras espera al servidor: no llamar directamente desde un
-- handler de Signal (D-013), usar task.spawn.
local function sendIntent(action: CombatAction, active: boolean?): ServerCombatResponse?
	local intent: CombatIntent = { Action = action, Active = active }
	-- nil = rechazado por la capa de red (rate limit, payload inválido) o fallo de comunicación.
	local response: ServerCombatResponse? = ClientNetwork.Invoke("CombatIntent", intent)
	if response ~= nil and response.Status == "Accepted" then
		if response.Movement ~= nil then
			MovementController:Apply(response.Movement)
		end
		local cooldown = response.Cooldown
		if cooldown ~= nil then
			CombatController.CooldownStarted:Fire(action, cooldown)
		end
	end
	return response
end

-- Pulsar una acción mantenida (guardia, sprint). Si el servidor aún no la
-- permite (la guardia tiene cooldown tras soltarla) y se sigue manteniendo,
-- se reintenta para que entre en cuanto se pueda sin volver a pulsar.
local function beginHold(inputAction: ActionName, action: CombatAction): ()
	for _ = 1, HOLD_RETRY_ATTEMPTS do
		local response = sendIntent(action, true)
		if response == nil or response.Status ~= "OnCooldown" then
			return
		end
		task.wait(HOLD_RETRY_SECONDS)
		if not InputController:IsDown(inputAction) then
			return
		end
	end
end

-- Los handlers de Signal no deben ceder: cada petición al servidor va en su propio hilo.
local function onActionBegan(action: ActionName): ()
	local pressAction: CombatAction? = PRESS_ACTIONS[action]
	local holdAction: CombatAction? = HOLD_ACTIONS[action]
	if pressAction ~= nil then
		local pressed: CombatAction = pressAction
		task.spawn(function()
			sendIntent(pressed, nil)
		end)
	elseif holdAction ~= nil then
		local held: CombatAction = holdAction
		task.spawn(function()
			beginHold(action, held)
		end)
	end
end

local function onActionEnded(action: ActionName): ()
	local holdAction: CombatAction? = HOLD_ACTIONS[action]
	if holdAction ~= nil then
		local released: CombatAction = holdAction
		task.spawn(function()
			sendIntent(released, false)
		end)
	end
end

function CombatController:Start(): ()
	InputController.ActionBegan:Connect(onActionBegan)
	InputController.ActionEnded:Connect(onActionEnded)
end

return CombatController
