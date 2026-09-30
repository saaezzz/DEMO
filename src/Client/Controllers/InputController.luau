--!strict

-- Capa de input (constitución §51, D-019). Traduce teclado/ratón, mando y
-- botones táctiles a acciones abstractas (InputBindings) y las emite como
-- señales. Los controladores de juego escuchan acciones, nunca teclas.
--
-- Usa ContextActionService: respeta los TextBox enfocados y la UI que
-- consume el input, y crea botones táctiles en móvil.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local InputBindings = require(script.Parent.Parent.Input.InputBindings)

type ActionName = InputBindings.ActionName
type InputBinding = InputBindings.InputBinding

export type InputMode = "KeyboardMouse" | "Gamepad" | "Touch"

-- Prefijo para no chocar con acciones de otros sistemas en ContextActionService.
local ACTION_PREFIX = "Game."

local GAMEPAD_INPUT_TYPES: { Enum.UserInputType } = {
	Enum.UserInputType.Gamepad1,
	Enum.UserInputType.Gamepad2,
	Enum.UserInputType.Gamepad3,
	Enum.UserInputType.Gamepad4,
	Enum.UserInputType.Gamepad5,
	Enum.UserInputType.Gamepad6,
	Enum.UserInputType.Gamepad7,
	Enum.UserInputType.Gamepad8,
}

local KEYBOARD_MOUSE_INPUT_TYPES: { Enum.UserInputType } = {
	Enum.UserInputType.Keyboard,
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3,
	Enum.UserInputType.MouseMovement,
	Enum.UserInputType.MouseWheel,
}

local pressed: { [ActionName]: boolean } = {}
local inputMode: InputMode = "KeyboardMouse"

local InputController = {
	Name = "InputController",
	ActionBegan = Signal.new() :: Signal.Signal<ActionName>,
	ActionEnded = Signal.new() :: Signal.Signal<ActionName>,
	InputModeChanged = Signal.new() :: Signal.Signal<InputMode>,
}

local function toInputMode(inputType: Enum.UserInputType): InputMode?
	if inputType == Enum.UserInputType.Touch then
		return "Touch"
	elseif table.find(GAMEPAD_INPUT_TYPES, inputType) then
		return "Gamepad"
	elseif table.find(KEYBOARD_MOUSE_INPUT_TYPES, inputType) then
		return "KeyboardMouse"
	end
	return nil
end

local function setInputMode(inputType: Enum.UserInputType): ()
	local mode: InputMode? = toInputMode(inputType)
	if mode ~= nil and mode ~= inputMode then
		inputMode = mode
		InputController.InputModeChanged:Fire(mode)
	end
end

local function onAction(action: ActionName, inputState: Enum.UserInputState): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin then
		pressed[action] = true
		InputController.ActionBegan:Fire(action)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		-- Cancel llega, por ejemplo, al perder el foco la ventana con la tecla pulsada.
		if pressed[action] then
			pressed[action] = false
			InputController.ActionEnded:Fire(action)
		end
	end
	-- Solo observamos: no se consume el input para otros sistemas.
	return Enum.ContextActionResult.Pass
end

-- Las acciones con botón táctil se enlazan primero y en TouchOrder, para que
-- los botones aparezcan en un orden estable. (Se ordena como string: el
-- analizador pierde el tipo literal de los elementos al pasar por table.sort.)
local function getBindingOrder(): { string }
	local actions: { string } = {}
	for action in InputBindings do
		table.insert(actions, action)
	end
	table.sort(actions, function(a: string, b: string)
		local orderA = InputBindings[a :: ActionName].TouchOrder or math.huge
		local orderB = InputBindings[b :: ActionName].TouchOrder or math.huge
		if orderA ~= orderB then
			return orderA < orderB
		end
		return a < b
	end)
	return actions
end

local function bindAction(action: ActionName, binding: InputBinding): ()
	local inputs: { any } = {}
	for _, input in binding.KeyboardMouse do
		table.insert(inputs, input)
	end
	for _, input in binding.Gamepad do
		table.insert(inputs, input)
	end

	local actionName = ACTION_PREFIX .. action
	local createTouchButton = binding.TouchTitle ~= nil
	ContextActionService:BindAction(actionName, function(_, inputState)
		return onAction(action, inputState)
	end, createTouchButton, table.unpack(inputs))

	if binding.TouchTitle ~= nil then
		ContextActionService:SetTitle(actionName, binding.TouchTitle)
	end
end

function InputController:Start(): ()
	for _, name in getBindingOrder() do
		local action: ActionName = name :: ActionName
		bindAction(action, InputBindings[action])
	end

	-- Hasta el primer input, suponer el modo por las capacidades del dispositivo.
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		inputMode = "Touch"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		inputMode = "Gamepad"
	end
	setInputMode(UserInputService:GetLastInputType())
	UserInputService.LastInputTypeChanged:Connect(setInputMode)
end

-- Pulsa una acción desde la UI (p. ej. una casilla de la barra de acciones),
-- como si se hubiera pulsado y soltado su control.
function InputController:Trigger(action: ActionName): ()
	InputController.ActionBegan:Fire(action)
	InputController.ActionEnded:Fire(action)
end

function InputController:IsDown(action: ActionName): boolean
	return pressed[action] == true
end

-- Modo de input más reciente, para mostrar los iconos de controles correctos.
function InputController:GetInputMode(): InputMode
	return inputMode
end

return InputController
