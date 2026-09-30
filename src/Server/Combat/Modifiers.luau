--!strict

-- Modificadores temporales de un personaje (D-040): potenciadores como una
-- piel endurecida o una armadura espiritual. Lógica pura: el instante actual
-- llega como parámetro para poder probarla.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)

type ModifierSpec = AbilityTypes.ModifierSpec

export type ActiveModifier = {
	Spec: ModifierSpec,
	EndsAt: number,
}

-- Id del modificador → modificador activo.
export type ModifierSet = { [string]: ActiveModifier }

export type ModifierStat = "DamageTaken" | "DamageDealt"

local Modifiers = {}

-- Aplica `spec`. Si ya había uno con el mismo Id, lo renueva (no se acumulan).
function Modifiers.Apply(set: ModifierSet, spec: ModifierSpec, now: number): ()
	set[spec.Id] = { Spec = spec, EndsAt = now + spec.Duration }
end

-- Producto de los multiplicadores activos de `stat` (1 si no hay ninguno).
-- De paso retira los que han caducado.
function Modifiers.Multiplier(set: ModifierSet, stat: ModifierStat, now: number): number
	local result = 1
	for id, active in set do
		if now >= active.EndsAt then
			set[id] = nil
		else
			local value = if stat == "DamageTaken" then active.Spec.DamageTaken else active.Spec.DamageDealt
			result *= value or 1
		end
	end
	return result
end

return Modifiers
