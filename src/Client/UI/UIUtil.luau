--!strict

-- Creación declarativa de instancias de UI.

local Theme = require(script.Parent.Theme)

local UIUtil = {}

-- Crea una instancia con sus propiedades e hijos. `Parent` se asigna al
-- final para no replicar/renderizar estados intermedios.
function UIUtil.create(className: string, properties: { [string]: any }, children: { Instance }?): any
	local instance: any = Instance.new(className)
	local parent = properties.Parent
	for key, value in properties do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	if children ~= nil then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent ~= nil then
		instance.Parent = parent
	end
	return instance
end

-- Texto con la tipografía y el contorno del tema.
function UIUtil.label(properties: { [string]: any }): TextLabel
	local defaults: { [string]: any } = {
		BackgroundTransparency = 1,
		FontFace = Theme.FontBold,
		TextColor3 = Theme.Colors.Text,
		TextStrokeColor3 = Theme.Colors.Stroke,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for key, value in properties do
		defaults[key] = value
	end
	return UIUtil.create("TextLabel", defaults)
end

return UIUtil
