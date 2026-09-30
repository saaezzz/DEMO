--!strict

-- Acciones abstractas de input (constitución §51, D-019) y sus controles por
-- plataforma. Los sistemas de juego escuchan acciones, nunca teclas.
-- Tabla de controles para el equipo en docs/INPUT.md (mantener sincronizada).

export type ActionName =
	"LightAttack"
	| "HeavyAttack"
	| "Block"
	| "Dodge"
	| "Dash"
	| "Sprint"
	| "Ability1"
	| "Ability2"
	| "Ability3"
	| "Ability4"
	| "Transform"
	| "LockOn"
	| "Interact"
	| "Inventory"

export type InputBinding = {
	-- Teclas o botones de ratón (Enum.KeyCode o Enum.UserInputType).
	KeyboardMouse: { Enum.KeyCode | Enum.UserInputType },
	Gamepad: { Enum.KeyCode },
	-- Botón táctil en pantalla (solo para las acciones que lo necesitan).
	TouchTitle: string?,
	-- Orden en que se crean los botones táctiles (menor = antes).
	TouchOrder: number?,
	-- Sin botón de mando: se abre con su botón en pantalla (navegación de UI de Roblox).
	GamepadUsesMenuButton: boolean?,
}

local InputBindings: { [ActionName]: InputBinding } = {
	LightAttack = {
		KeyboardMouse = { Enum.UserInputType.MouseButton1 },
		Gamepad = { Enum.KeyCode.ButtonX },
		TouchTitle = "Atacar",
		TouchOrder = 1,
	},
	HeavyAttack = {
		KeyboardMouse = { Enum.KeyCode.R },
		Gamepad = { Enum.KeyCode.ButtonY },
	},
	Block = {
		KeyboardMouse = { Enum.KeyCode.F },
		Gamepad = { Enum.KeyCode.ButtonR1 },
		TouchTitle = "Bloquear",
		TouchOrder = 2,
	},
	Dodge = {
		KeyboardMouse = { Enum.KeyCode.LeftControl },
		Gamepad = { Enum.KeyCode.ButtonB },
	},
	Dash = {
		KeyboardMouse = { Enum.KeyCode.Q },
		Gamepad = { Enum.KeyCode.ButtonL1 },
	},
	-- Mantener pulsado. En táctil no hay botón: se corre a velocidad normal.
	Sprint = {
		KeyboardMouse = { Enum.KeyCode.LeftShift },
		Gamepad = { Enum.KeyCode.ButtonL3 },
	},
	Ability1 = {
		KeyboardMouse = { Enum.KeyCode.Z },
		Gamepad = { Enum.KeyCode.DPadUp },
	},
	Ability2 = {
		KeyboardMouse = { Enum.KeyCode.X },
		Gamepad = { Enum.KeyCode.DPadRight },
	},
	Ability3 = {
		KeyboardMouse = { Enum.KeyCode.C },
		Gamepad = { Enum.KeyCode.DPadDown },
	},
	Ability4 = {
		KeyboardMouse = { Enum.KeyCode.V },
		Gamepad = { Enum.KeyCode.DPadLeft },
	},
	Transform = {
		KeyboardMouse = { Enum.KeyCode.G },
		Gamepad = { Enum.KeyCode.ButtonR2 },
	},
	LockOn = {
		KeyboardMouse = { Enum.KeyCode.T },
		Gamepad = { Enum.KeyCode.ButtonR3 },
		TouchTitle = "Fijar",
		TouchOrder = 3,
	},
	Interact = {
		KeyboardMouse = { Enum.KeyCode.E },
		Gamepad = { Enum.KeyCode.ButtonL2 },
	},
	-- Mochila (D-036). En táctil y mando se abre con el botón de la pantalla.
	Inventory = {
		KeyboardMouse = { Enum.KeyCode.B },
		Gamepad = {},
		GamepadUsesMenuButton = true,
	},
}

return InputBindings
