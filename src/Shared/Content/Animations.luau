--!strict

-- Contenido: animaciones de juego (§53, D-020). La clave es la que usan los
-- sistemas; el asset (y su ID de Roblox) se resuelve en Content/Assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type AnimationDefinition = ContentTypes.AnimationDefinition

-- Animación de una sola pasada de una habilidad.
local function action(asset: string, markers: { string }): AnimationDefinition
	return { Asset = asset, Priority = "Action", Looped = false, Markers = markers }
end

local function locomotion(asset: string, looped: boolean): AnimationDefinition
	return { Asset = asset, Priority = "Core", Looped = looped, Markers = {} }
end

local Animations: { [string]: AnimationDefinition } = {
	["Combat.Slash1"] = action("ANIM_Sword_Slash1", { "Hit" }),
	["Combat.Slash2"] = action("ANIM_Sword_Slash2", { "Hit" }),
	["Combat.Slash3"] = action("ANIM_Sword_Slash3", { "Hit" }),
	["Combat.HeavySlash"] = action("ANIM_Sword_HeavySlash", { "Hit" }),
	["Combat.Dodge"] = action("ANIM_Combat_Dodge", {}),
	["Combat.Block"] = {
		Asset = "ANIM_Combat_Block",
		Priority = "Action",
		Looped = true,
		Markers = {},
	},
	["Combat.Dash"] = action("ANIM_Combat_Dash", {}),
	["Reaction.Stun"] = {
		Asset = "ANIM_Reaction_Stun",
		Priority = "Action",
		Looped = true,
		Markers = {},
	},

	["Locomotion.Idle"] = locomotion("ANIM_Locomotion_Idle", true),
	["Locomotion.LookAround"] = locomotion("ANIM_Locomotion_LookAround", true),
	["Locomotion.Walk"] = locomotion("ANIM_Locomotion_Walk", true),
	["Locomotion.Run"] = locomotion("ANIM_Locomotion_Run", true),
	["Locomotion.Jump"] = locomotion("ANIM_Locomotion_Jump", false),
	["Locomotion.Fall"] = locomotion("ANIM_Locomotion_Fall", true),
	["Locomotion.Climb"] = locomotion("ANIM_Locomotion_Climb", true),
	["Locomotion.Swim"] = locomotion("ANIM_Locomotion_Swim", true),
	["Locomotion.SwimIdle"] = locomotion("ANIM_Locomotion_SwimIdle", true),
}

return Animations
