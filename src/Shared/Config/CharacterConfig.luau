--!strict

-- Valores base de personaje (balance, no IP). Provisionales hasta BALANCE.md;
-- la progresión por nivel será data-driven (§14).

local CharacterConfig = {
	BaseMaxHealth = 100,
	MaxPosture = 100,
	-- Segundos entre la muerte y la reaparición.
	RespawnSeconds = 5,
}

return CharacterConfig
