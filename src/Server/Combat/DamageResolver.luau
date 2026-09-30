--!strict

-- Decide qué pasa cuando un golpe alcanza a un objetivo (§16): esquivado,
-- parry, bloqueado, guardia rota o golpe limpio. Lógica pura: DamageService
-- aplica el resultado al personaje.

export type HitOutcomeKind = "Evaded" | "Parried" | "Blocked" | "GuardBroken" | "Hit"

export type HitOutcome = {
	Kind: HitOutcomeKind,
	Damage: number,
	PostureDamage: number,
	-- La postura del defensor se llena: se vacía y queda aturdido.
	PostureBreak: boolean,
	-- Velocidad de empuje sobre el defensor (0 = sin empuje).
	Knockback: number,
	-- El golpe remata al defensor (Damage ya es toda su vida restante).
	Executed: boolean,
}

-- Remate (AbilityTypes.ExecuteSpec, D-038).
export type ExecuteInput = {
	HealthFraction: number,
	MaxDamage: number,
}

export type HitInput = {
	Damage: number,
	PostureDamage: number,
	GuardBreak: boolean,
	Knockback: number,
	DefenderBlocking: boolean,
	DefenderInParryWindow: boolean,
	DefenderInvulnerable: boolean,
	DefenderPosture: number,
	DefenderMaxPosture: number,
	DefenderHealth: number,
	DefenderMaxHealth: number,
	-- Producto de los modificadores (D-040): daño hecho del atacante × daño
	-- recibido del defensor. 1 = sin cambios.
	DamageMultiplier: number,
	Execute: ExecuteInput?,
}

export type ResolverConfig = {
	BlockDamageMultiplier: number,
	BlockPostureMultiplier: number,
	GuardBreakDamageMultiplier: number,
}

local function outcome(
	kind: HitOutcomeKind,
	damage: number,
	posture: number,
	postureBreak: boolean,
	knockback: number
): HitOutcome
	return {
		Kind = kind,
		Damage = damage,
		PostureDamage = posture,
		PostureBreak = postureBreak,
		Knockback = knockback,
		Executed = false,
	}
end

local function canExecute(input: HitInput): boolean
	local execute = input.Execute
	if execute == nil or input.DefenderMaxHealth <= 0 then
		return false
	end
	local health = input.DefenderHealth
	return health <= execute.MaxDamage and health / input.DefenderMaxHealth <= execute.HealthFraction
end

local DamageResolver = {}

function DamageResolver.Resolve(input: HitInput, config: ResolverConfig): HitOutcome
	if input.DefenderInvulnerable then
		return outcome("Evaded", 0, 0, false, 0)
	end
	local damage = input.Damage * input.DamageMultiplier

	if input.DefenderBlocking then
		-- El parry gana incluso a un ataque que rompe guardias: premia el timing.
		if input.DefenderInParryWindow then
			return outcome("Parried", 0, 0, false, 0)
		end
		if input.GuardBreak then
			return outcome("GuardBroken", damage * config.GuardBreakDamageMultiplier, 0, true, input.Knockback)
		end
		local posture = input.PostureDamage * config.BlockPostureMultiplier
		local breaks = input.DefenderPosture + posture >= input.DefenderMaxPosture
		return outcome("Blocked", damage * config.BlockDamageMultiplier, posture, breaks, 0)
	end

	local breaks = input.DefenderPosture + input.PostureDamage >= input.DefenderMaxPosture
	local result = outcome("Hit", damage, input.PostureDamage, breaks, input.Knockback)
	-- El remate solo entra con un golpe limpio: bloquearlo o esquivarlo lo evita.
	if canExecute(input) then
		result.Damage = math.max(damage, input.DefenderHealth)
		result.Executed = true
	end
	return result
end

return DamageResolver
