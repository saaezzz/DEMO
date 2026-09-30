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
	}
end

local DamageResolver = {}

function DamageResolver.Resolve(input: HitInput, config: ResolverConfig): HitOutcome
	if input.DefenderInvulnerable then
		return outcome("Evaded", 0, 0, false, 0)
	end

	if input.DefenderBlocking then
		-- El parry gana incluso a un ataque que rompe guardias: premia el timing.
		if input.DefenderInParryWindow then
			return outcome("Parried", 0, 0, false, 0)
		end
		if input.GuardBreak then
			return outcome("GuardBroken", input.Damage * config.GuardBreakDamageMultiplier, 0, true, input.Knockback)
		end
		local posture = input.PostureDamage * config.BlockPostureMultiplier
		local breaks = input.DefenderPosture + posture >= input.DefenderMaxPosture
		return outcome("Blocked", input.Damage * config.BlockDamageMultiplier, posture, breaks, 0)
	end

	local breaks = input.DefenderPosture + input.PostureDamage >= input.DefenderMaxPosture
	return outcome("Hit", input.Damage, input.PostureDamage, breaks, input.Knockback)
end

return DamageResolver
