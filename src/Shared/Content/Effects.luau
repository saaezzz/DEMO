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
	-- Hollow -------------------------------------------------------------------
	-- Carga del Cero: esfera roja delante de la boca mientras se prepara.
	["Hollow.CeroCharge"] = {
		Kind = "Burst",
		Asset = "VFX_Hollow_CeroCharge",
		Color = "#FF2E4D",
		Duration = 0.8,
		Radius = 1.5,
		Offset = CFrame.new(0, 1.5, -1.5),
	},
	["Hollow.Cero"] = {
		Kind = "Beam",
		Asset = "VFX_Hollow_Cero",
		Color = "#FF2E4D",
		Duration = 0.45,
		Length = 50,
		Width = 2.4,
		Offset = CFrame.new(0, 0.5, -1),
	},
	["Hollow.Bala"] = {
		Kind = "Beam",
		Asset = "VFX_Hollow_Bala",
		Color = "#FF7A7A",
		Duration = 0.2,
		Length = 35,
		Width = 0.7,
		Offset = CFrame.new(0, 0.5, -1),
	},
	["Hollow.Devour"] = {
		Kind = "Burst",
		Asset = "VFX_Hollow_Devour",
		Color = "#7A1030",
		Duration = 0.35,
		Radius = 3,
		Offset = CFrame.new(0, 0, -4),
	},
	-- Duración igual a la del modificador de Hierro (10 s).
	["Hollow.Hierro"] = {
		Kind = "Aura",
		Asset = "VFX_Hollow_Hierro",
		Color = "#C9CCD6",
		Duration = 10,
	},
	["Movement.Sonido"] = {
		Kind = "Burst",
		Asset = "VFX_Movement_Sonido",
		Color = "#2A0A14",
		Duration = 0.25,
		Radius = 3,
	},

	-- Quincy -------------------------------------------------------------------
	["Quincy.Pfeil"] = {
		Kind = "Beam",
		Asset = "VFX_Quincy_Pfeil",
		Color = "#8FE3FF",
		Duration = 0.15,
		Length = 36,
		Width = 0.25,
		Offset = CFrame.new(0, 0.5, -1),
	},
	["Quincy.ChargedPfeil"] = {
		Kind = "Beam",
		Asset = "VFX_Quincy_ChargedPfeil",
		Color = "#CFF6FF",
		Duration = 0.3,
		Length = 45,
		Width = 0.8,
		Offset = CFrame.new(0, 0.5, -1),
	},
	-- Mismo radio (9) y distancia (18) que la hitbox de Licht Regen.
	["Quincy.LichtRegen"] = {
		Kind = "Burst",
		Asset = "VFX_Quincy_LichtRegen",
		Color = "#9FE8FF",
		Duration = 0.6,
		Radius = 9,
		Offset = CFrame.new(0, 0, -18),
	},
	-- Duración igual a la de sus modificadores (8 s).
	["Quincy.BlutVene"] = {
		Kind = "Aura",
		Asset = "VFX_Quincy_BlutVene",
		Color = "#3FA9FF",
		Duration = 8,
	},
	["Quincy.BlutArterie"] = {
		Kind = "Aura",
		Asset = "VFX_Quincy_BlutArterie",
		Color = "#FF4050",
		Duration = 8,
	},
	["Movement.Hirenkyaku"] = {
		Kind = "Burst",
		Asset = "VFX_Movement_Hirenkyaku",
		Color = "#CFF6FF",
		Duration = 0.25,
		Radius = 2.5,
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
