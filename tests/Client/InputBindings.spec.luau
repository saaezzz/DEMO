local InputBindings = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Input.InputBindings)

-- EnumItem no sirve como clave de tabla en Lune; se compara por su nombre.
local function findDuplicates(scheme)
	local owners = {}
	local duplicates = {}
	for action, binding in InputBindings do
		for _, input in binding[scheme] do
			local key = tostring(input)
			if owners[key] ~= nil then
				table.insert(duplicates, `{key}: {owners[key]} y {action}`)
			end
			owners[key] = action
		end
	end
	return duplicates
end

return {
	["cada acción tiene control en teclado/ratón y en mando"] = function()
		for action, binding in InputBindings do
			if #binding.KeyboardMouse == 0 or #binding.Gamepad == 0 then
				error(`{action} no tiene controles en todas las plataformas`)
			end
		end
	end,

	["ningún control de teclado/ratón se asigna a dos acciones"] = function()
		expect(#findDuplicates("KeyboardMouse")).toBe(0)
	end,

	["ningún botón de mando se asigna a dos acciones"] = function()
		expect(#findDuplicates("Gamepad")).toBe(0)
	end,

	["las acciones básicas de combate tienen botón táctil"] = function()
		for _, action in { "LightAttack", "Block", "Dash" } do
			expect(InputBindings[action].TouchTitle ~= nil).toBe(true)
		end
	end,

	["los botones táctiles tienen orden único"] = function()
		local seen = {}
		for action, binding in InputBindings do
			if binding.TouchTitle ~= nil then
				expect(binding.TouchOrder ~= nil).toBe(true)
				if seen[binding.TouchOrder] ~= nil then
					error(`{action} y {seen[binding.TouchOrder]} comparten TouchOrder`)
				end
				seen[binding.TouchOrder] = action
			end
		end
	end,

	["no se usan los controles reservados por Roblox"] = function()
		local reserved = {
			tostring(Enum.KeyCode.W),
			tostring(Enum.KeyCode.A),
			tostring(Enum.KeyCode.S),
			tostring(Enum.KeyCode.D),
			tostring(Enum.KeyCode.Space),
			tostring(Enum.KeyCode.ButtonA), -- salto en mando
			tostring(Enum.KeyCode.Thumbstick1),
			tostring(Enum.KeyCode.ButtonStart),
			tostring(Enum.KeyCode.ButtonSelect),
		}
		for action, binding in InputBindings do
			for _, scheme in { binding.KeyboardMouse, binding.Gamepad } do
				for _, input in scheme do
					if table.find(reserved, tostring(input)) then
						error(`{action} usa un control reservado: {tostring(input)}`)
					end
				end
			end
		end
	end,
}
