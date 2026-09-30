--!strict

-- Contenido: manifiesto de assets (§54, D-020). Única fuente de verdad de los
-- IDs de Roblox. Convención de nombres y flujo de estados en docs/ASSETS.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type AssetEntry = ContentTypes.AssetEntry

-- Animación de acción aún sin crear: mientras no tenga AssetId se usa su
-- placeholder procedural del cliente (D-022).
local function actionAnimation(name: string, usedBy: string, notes: string): AssetEntry
	return {
		Name = name,
		Category = "Animation",
		AssetId = nil,
		Owner = "Animación/Visual",
		Status = "TODO",
		Version = 0,
		Dependencies = {},
		UsedBy = { usedBy },
		Notes = notes,
	}
end

-- Locomoción provisional: pack "Ninja" del catálogo de Roblox (creador Roblox,
-- uso libre en cualquier experiencia). Se sustituirá por animaciones propias (D-022).
local function catalogLocomotion(name: string, assetId: number): AssetEntry
	return {
		Name = name,
		Category = "Animation",
		AssetId = assetId,
		Owner = "Roblox (catálogo)",
		Status = "INTEGRATED",
		Version = 1,
		Dependencies = {},
		UsedBy = { "Locomotion" },
		Notes = "Provisional (pack Ninja, R15). Sustituir por locomoción propia.",
	}
end

local Assets: { AssetEntry } = {
	actionAnimation(
		"ANIM_Sword_BasicSlash",
		"Combo:BasicSlash",
		"Tajo horizontal de una mano. Marker 'Hit' en el frame del impacto (~0,2 s)."
	),
	actionAnimation(
		"ANIM_Combat_Block",
		"State:Blocking",
		"Guardia con el arma delante. En bucle mientras se bloquea."
	),
	actionAnimation("ANIM_Combat_Dash", "State:Dashing", "Impulso inclinado hacia delante, ~0,4 s."),
	actionAnimation("ANIM_Reaction_Stun", "State:Stunned", "Tambaleo tras parry o rotura de postura. En bucle."),

	catalogLocomotion("ANIM_Locomotion_Idle", 656117400),
	catalogLocomotion("ANIM_Locomotion_LookAround", 656118341),
	catalogLocomotion("ANIM_Locomotion_Walk", 656121766),
	catalogLocomotion("ANIM_Locomotion_Run", 656118852),
	catalogLocomotion("ANIM_Locomotion_Jump", 656117878),
	catalogLocomotion("ANIM_Locomotion_Fall", 656115606),
	catalogLocomotion("ANIM_Locomotion_Climb", 656114359),
	catalogLocomotion("ANIM_Locomotion_Swim", 656119721),
	catalogLocomotion("ANIM_Locomotion_SwimIdle", 656121397),
}

return Assets
