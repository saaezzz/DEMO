--!strict

-- Framework de habilidades (§17, D-025). Toda acción de combate (ataques,
-- esquiva, dash, técnicas futuras) es una AbilityDefinition: añadir una
-- habilidad es añadir datos, no código.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

type CharacterStateName = GameTypes.CharacterStateName
type StateRequirements = GameTypes.StateRequirements
type ResourceCost = GameTypes.ResourceCost
type HitboxDefinition = GameTypes.HitboxDefinition
type MovementSpec = GameTypes.MovementSpec

-- Un golpe dentro de una habilidad. Se comprueba la hitbox en StartTime.
export type AbilityHit = {
	-- Keyframe Marker de la animación que corresponde a este golpe (§53).
	MarkerName: string,
	StartTime: number,
	Damage: number,
	PostureDamage: number,
	Hitbox: HitboxDefinition,
	-- Rompe la guardia de un objetivo que bloquea (no afecta al parry).
	GuardBreak: boolean?,
	-- Velocidad (studs/s) con la que empuja al objetivo si le golpea de lleno.
	Knockback: number?,
	-- Aturde al objetivo estos segundos al alcanzarle (ataduras, D-034).
	Stun: number?,
	-- Ignora el bloqueo y el parry.
	Unblockable: boolean?,
}

-- Invulnerabilidad desde el inicio de la habilidad (segundos).
export type IFrameWindow = {
	Start: number,
	End: number,
}

export type AbilityDefinition = {
	Id: string,
	-- Estado de acción mientras dura (Attacking, Dodging, Dashing...).
	State: CharacterStateName,
	-- Desde qué estados puede empezar (§15).
	Requirements: StateRequirements,
	-- Segundos en State; al terminar vuelve a Idle.
	Duration: number,
	Cooldown: number,
	Cost: ResourceCost?,
	Hits: { AbilityHit }?,
	Movement: MovementSpec?,
	IFrames: IFrameWindow?,
	-- Clave de Content/Animations.
	Animation: string?,
}

-- Qué habilidad ejecuta cada acción de input. LightAttack es una cadena: cada
-- pulsación dentro de la ventana de combo avanza al siguiente golpe.
export type Moveset = {
	LightAttack: { string },
	HeavyAttack: string?,
	Dodge: string?,
	Dash: string?,
	-- Técnicas en Ability1..Ability4 (Z X C V / cruceta), en orden.
	Skills: { string },
}

return {}
