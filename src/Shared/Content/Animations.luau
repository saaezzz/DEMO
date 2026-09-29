--!strict

-- Contenido: animaciones de juego (§53, D-020). La clave es la que usan los
-- sistemas; el asset (y su ID de Roblox) se resuelve en Content/Assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type AnimationDefinition = ContentTypes.AnimationDefinition

local Animations: { [string]: AnimationDefinition } = {
	["Combat.BasicSlash"] = {
		Asset = "ANIM_Sword_BasicSlash",
		Priority = "Action",
		Looped = false,
		Markers = { "Hit" },
	},
}

return Animations
