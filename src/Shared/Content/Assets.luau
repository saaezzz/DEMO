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
-- Asset aún sin crear de Arte (modelos) o Visual (efectos).
local function pendingAsset(
	name: string,
	category: ContentTypes.AssetCategory,
	owner: string,
	usedBy: string,
	notes: string
): AssetEntry
	return {
		Name = name,
		Category = category,
		AssetId = nil,
		Owner = owner,
		Status = "TODO",
		Version = 0,
		Dependencies = {},
		UsedBy = { usedBy },
		Notes = notes,
	}
end

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
		"ANIM_Sword_Slash1",
		"Ability:Slash1",
		"Tajo horizontal de derecha a izquierda. Marker 'Hit' en el impacto (0,2 s). Dura 0,45 s."
	),
	actionAnimation(
		"ANIM_Sword_Slash2",
		"Ability:Slash2",
		"Revés de izquierda a derecha. Marker 'Hit' en el impacto (0,2 s). Dura 0,45 s."
	),
	actionAnimation(
		"ANIM_Sword_Slash3",
		"Ability:Slash3",
		"Remate vertical de arriba abajo. Marker 'Hit' en el impacto (0,3 s). Dura 0,65 s."
	),
	actionAnimation(
		"ANIM_Sword_HeavySlash",
		"Ability:HeavySlash",
		"Carga larga y golpe descendente a dos manos. Marker 'Hit' en el impacto (0,5 s). Dura 0,9 s."
	),
	actionAnimation("ANIM_Combat_Dodge", "Ability:Dodge", "Paso rápido agachado, ~0,4 s."),
	actionAnimation(
		"ANIM_Enemy_Swipe",
		"Ability:EnemySwipe",
		"Zarpazo con una mano. Marker 'Hit' a 0,25 s. Dura 0,6 s."
	),
	actionAnimation(
		"ANIM_Enemy_Lunge",
		"Ability:EnemyLunge",
		"Salto hacia delante con las garras. Marker 'Hit' a 0,3 s."
	),
	actionAnimation(
		"ANIM_Enemy_Crush",
		"Ability:EnemyCrush",
		"Carga muy visible con los brazos arriba y golpe al suelo. Marker 'Hit' a 0,45 s. Dura 1 s."
	),
	actionAnimation(
		"ANIM_Combat_Block",
		"State:Blocking",
		"Guardia con el arma delante. En bucle mientras se bloquea."
	),
	actionAnimation("ANIM_Combat_Dash", "Ability:Dash", "Impulso inclinado hacia delante, ~0,4 s."),
	actionAnimation("ANIM_Reaction_Stun", "State:Stunned", "Tambaleo tras parry o rotura de postura. En bucle."),

	actionAnimation(
		"ANIM_Cast_Point",
		"Ability:Byakurai",
		"Brazo derecho extendido apuntando al frente. Marker 'Hit' a 0,35 s."
	),
	actionAnimation("ANIM_Cast_Bind", "Ability:Sai", "Ambas palmas hacia delante. Marker 'Hit' a 0,3 s."),

	-- Modelos (Arte/Builder). Un modelo de personaje debe ser un rig R15 con Humanoid y
	-- HumanoidRootPart; un arma, un Model con una pieza "Handle" (el mango). Ver docs/GUIA_EQUIPO.md.
	pendingAsset(
		"MDL_Weapon_Asauchi",
		"Model",
		"Arte/Builder",
		"Weapon:Asauchi",
		"Katana. Handle en el mango; hoja hacia -Z."
	),
	pendingAsset(
		"MDL_Enemy_WeakHollow",
		"Model",
		"Arte/Builder",
		"Enemy:WeakHollow",
		"Rig R15 algo más bajo que un jugador."
	),
	pendingAsset("MDL_Enemy_StandardHollow", "Model", "Arte/Builder", "Enemy:StandardHollow", "Rig R15 ×1,1."),
	pendingAsset(
		"MDL_Enemy_EliteHollow",
		"Model",
		"Arte/Builder",
		"Enemy:EliteHollow",
		"Rig R15 ×1,45, aspecto más agresivo."
	),

	-- Efectos (Animación/Visual). Un Model o Part con ParticleEmitters; se coloca en
	-- la posición del efecto y se emite. Ver docs/GUIA_EQUIPO.md.
	pendingAsset(
		"VFX_Kido_Byakurai",
		"VFX",
		"Animación/Visual",
		"Effect:Kido.Byakurai",
		"Rayo de 40 studs hacia -Z, ~0,3 s."
	),
	pendingAsset(
		"VFX_Kido_Sai",
		"VFX",
		"Animación/Visual",
		"Effect:Kido.Sai",
		"Destello de atadura sobre el objetivo."
	),
	pendingAsset(
		"VFX_Movement_Shunpo",
		"VFX",
		"Animación/Visual",
		"Effect:Movement.Shunpo",
		"Estela al desaparecer, ~0,25 s."
	),
	pendingAsset(
		"VFX_Telegraph_Area",
		"VFX",
		"Animación/Visual",
		"Effect:Telegraph.Area",
		"Círculo rojo en el suelo; se escala al radio del ataque."
	),

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
