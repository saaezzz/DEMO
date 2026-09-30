--!strict

-- Traduce las acciones de input en intents de combate para el servidor. Las
-- animaciones las pone CharacterAnimationController a partir del estado
-- autoritativo replicado (D-021, D-022).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

local ClientNetwork = require(script.Parent.Parent.Network.ClientNetwork)
local InputController = require(script.Parent.InputController)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)

type CombatIntent = GameTypes.CombatIntent
type CombatIntentType = GameTypes.CombatIntentType
type ServerCombatResponse = GameTypes.ServerCombatResponse
type ActionName = InputBindings.ActionName

-- Provisional hasta el framework de habilidades (M2), que asignará el combo
-- según el arma/kit equipado.
local ATTACK_COMBO_ID = "BasicSlash"

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

-- Los handlers de Signal no deben ceder: cada petición al servidor va en su propio hilo.
local function onActionBegan(action: ActionName): ()
	if action == "LightAttack" then
		task.spawn(function()
			sendIntent("Attack", ATTACK_COMBO_ID, nil)
		end)
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
	InputController.ActionBegan:Connect(onActionBegan)
	InputController.ActionEnded:Connect(onActionEnded)
end

return CombatController
