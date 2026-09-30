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

-- Remate (D-038): si al objetivo le queda como mucho HealthFraction de su vida
-- máxima y no más de MaxDamage de vida, el golpe lo derrota. MaxDamage impide
-- rematar de un golpe a enemigos con mucha vida (jefes).
export type ExecuteSpec = {
	HealthFraction: number,
	MaxDamage: number,
}

-- Modificador temporal sobre el propio personaje (D-040). Los multiplicadores
-- se aplican al daño (0,6 = recibe un 40 % menos; 1,3 = hace un 30 % más).
-- Dos modificadores con el mismo Id no se acumulan: el nuevo sustituye al viejo.
export type ModifierSpec = {
	Id: string,
	Duration: number,
	DamageTaken: number?,
	DamageDealt: number?,
}

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
	-- Fracción del daño hecho que recupera el atacante como vida (D-038).
	Drain: number?,
	Execute: ExecuteSpec?,
	-- Estadística del perfil (Content/Stats) que suma 1 si este golpe derrota
	-- al objetivo. La usan los hitos de raza (D-039).
	KillStat: string?,
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
	-- Se aplica al propio personaje al empezar la habilidad (D-040).
	SelfModifier: ModifierSpec?,
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
