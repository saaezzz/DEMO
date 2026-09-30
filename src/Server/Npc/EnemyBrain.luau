--!strict

-- Decisiones de la IA de enemigos (§42, D-029). Lógica pura: EnemyService
-- reúne la situación, EnemyBrain decide y EnemyService lo ejecuta.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyTypes = require(ReplicatedStorage.Shared.Types.EnemyTypes)

type EnemyAggro = EnemyTypes.EnemyAggro
type EnemyAttack = EnemyTypes.EnemyAttack

export type Decision =
	"Idle" -- sin objetivo: quieto
	| "Chase" -- acercarse al objetivo
	| "Attack" -- atacar ahora
	| "Hold" -- a distancia de ataque, esperando a poder atacar
	| "Return" -- volver a su punto de aparición (y soltar el objetivo)
	| "Busy" -- ocupado (atacando, aturdido...): no hacer nada

export type Situation = {
	-- Estado de acción del enemigo.
	State: string,
	Returning: boolean,
	HomeDistance: number,
	-- nil = sin objetivo.
	TargetDistance: number?,
	-- Ha pasado el intervalo entre ataques.
	AttackReady: boolean,
	-- Alcance máximo entre sus ataques sin cooldown (nil = ninguno listo).
	ReadyRange: number?,
	-- Alcance del ataque más corto: más cerca de esto no hace falta acercarse.
	MinRange: number,
	Aggro: EnemyAggro,
}

-- Distancia a la que se considera que ha llegado a casa.
local HOME_TOLERANCE = 3

local EnemyBrain = {}

function EnemyBrain.Decide(situation: Situation): Decision
	if situation.Returning then
		return if situation.HomeDistance <= HOME_TOLERANCE then "Idle" else "Return"
	end
	if situation.HomeDistance > situation.Aggro.LeashRange then
		return "Return"
	end
	local distance = situation.TargetDistance
	if distance == nil then
		return "Idle"
	end
	if situation.State ~= "Idle" then
		return "Busy"
	end
	local readyRange = situation.ReadyRange
	if situation.AttackReady and readyRange ~= nil and distance <= readyRange then
		return "Attack"
	end
	if distance <= situation.MinRange then
		return "Hold"
	end
	return "Chase"
end

-- Elige al azar (roll en [0, 1)) entre los ataques listos que alcanzan al objetivo.
function EnemyBrain.PickAttack(
	attacks: { EnemyAttack },
	distance: number,
	roll: number,
	isReady: (abilityId: string) -> boolean
): EnemyAttack?
	local candidates: { EnemyAttack } = {}
	for _, attack in attacks do
		if distance <= attack.Range and isReady(attack.Ability) then
			table.insert(candidates, attack)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local index = math.clamp(math.floor(roll * #candidates) + 1, 1, #candidates)
	return candidates[index]
end

-- Alcances de un conjunto de ataques: el mayor entre los listos y el menor de todos.
function EnemyBrain.Ranges(attacks: { EnemyAttack }, isReady: (abilityId: string) -> boolean): (number?, number)
	local readyRange: number? = nil
	local minRange = math.huge
	for _, attack in attacks do
		minRange = math.min(minRange, attack.Range)
		if isReady(attack.Ability) then
			readyRange = math.max(readyRange or 0, attack.Range)
		end
	end
	return readyRange, minRange
end

return EnemyBrain
