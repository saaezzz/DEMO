--!strict

-- Curva de progresión (§14, §44; no IP). Provisional hasta BALANCE.md.
-- Pauta D-023: subir rápido los primeros niveles.

local ProgressionConfig = {
	MaxLevel = 100,
	-- EXP para pasar del nivel N al N+1 = floor(XpBase * N ^ XpExponent).
	-- Nivel 1 → 60, nivel 5 → 670, nivel 20 → 5366, nivel 99 → 59 102.
	XpBase = 60,
	XpExponent = 1.5,
	-- Vida máxima = CharacterConfig.BaseMaxHealth + HealthPerLevel * (nivel - 1).
	-- El nivel no decide todo el poder (§44): el resto vendrá de stats, maestrías y habilidades.
	HealthPerLevel = 4,
}

return ProgressionConfig
