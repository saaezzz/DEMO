--!strict

-- Contenido: efectos visuales (capa IP, §4, D-035). Cada efecto tiene una
-- versión provisional (Kind + color + tamaño). Cuando Arte coloque el suyo en
-- Studio (Assets/VFX/<Asset>), se usa ese en su lugar sin tocar código.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type EffectDefinition = ContentTypes.EffectDefinition

local Effects: { [string]: EffectDefinition } = {
	["Kido.Byakurai"] = {
		Kind = "Beam",
		Asset = "VFX_Kido_Byakurai",
		Color = "#BFE6FF",
		Duration = 0.3,
		Length = 40,
		Width = 0.8,
		Offset = CFrame.new(0, 0.5, -1),
	},
	["Kido.Sai"] = {
		Kind = "Burst",
		Asset = "VFX_Kido_Sai",
		Color = "#FFE38A",
		Duration = 0.4,
		Radius = 4,
		Offset = CFrame.new(0, 0, -7),
	},
	["Movement.Shunpo"] = {
		Kind = "Burst",
		Asset = "VFX_Movement_Shunpo",
		Color = "#FFFFFF",
		Duration = 0.25,
		Radius = 3,
	},
	-- Aviso de un ataque en área (el radio lo da el ataque).
	["Telegraph.Area"] = {
		Kind = "Ring",
		Asset = "VFX_Telegraph_Area",
		Color = "#FF2020",
		Duration = 1,
		Radius = 10,
	},
}

return Effects
