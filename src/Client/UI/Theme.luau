--!strict

-- Estilo común de la UI provisional (D-022): paneles oscuros con acento
-- naranja y tipografía condensada. Cambiar aquí cambia toda la UI.

local Theme = {
	FontBold = Font.new(Font.fromEnum(Enum.Font.Oswald).Family, Enum.FontWeight.Bold),
	FontRegular = Font.new(Font.fromEnum(Enum.Font.Oswald).Family, Enum.FontWeight.Medium),

	Colors = {
		Panel = Color3.fromRGB(12, 12, 16),
		BarBack = Color3.fromRGB(28, 28, 36),
		Accent = Color3.fromRGB(255, 122, 26),
		Text = Color3.fromRGB(245, 245, 245),
		TextDim = Color3.fromRGB(170, 170, 185),
		Stroke = Color3.fromRGB(0, 0, 0),
		Health = Color3.fromRGB(224, 58, 58),
		HealthLow = Color3.fromRGB(255, 40, 90),
		Ghost = Color3.fromRGB(255, 236, 220),
		Posture = Color3.fromRGB(242, 193, 78),
		PostureFull = Color3.fromRGB(255, 80, 30),
		DamageSelf = Color3.fromRGB(255, 70, 70),
		DamageOther = Color3.fromRGB(255, 225, 120),
	},

	PanelTransparency = 0.25,
	-- Por debajo de esta fracción de vida la barra cambia de color.
	LowHealthRatio = 0.3,
}

return Theme
