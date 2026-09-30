--!strict

-- Valores de balance del combate (no IP). Provisionales hasta BALANCE.md.

local CombatConfig = {
	-- Primeros segundos de un bloqueo en los que un golpe se convierte en parry.
	ParryWindowSeconds = 0.3,
	-- Tiempo mínimo entre ventanas de parry: bloquear repetidamente sigue
	-- bloqueando, pero sin encadenar parries (D-009).
	ParryRetrySeconds = 0.8,
	-- Aturdimiento del atacante al recibir un parry.
	ParryStunSeconds = 0.8,
	-- Aturdimiento al llenarse la postura o al romperse la guardia.
	PostureBreakStunSeconds = 1.5,
	-- Bloquear reduce el daño y aumenta el daño a la postura.
	BlockDamageMultiplier = 0.25,
	BlockPostureMultiplier = 1.5,
	-- Fracción del daño que pasa cuando un ataque rompe la guardia.
	GuardBreakDamageMultiplier = 0.5,
	-- Aturdimiento breve al recibir un golpe limpio (hitstun, §16).
	HitStunSeconds = 0.3,
	-- Componente vertical del empuje, para despegar ligeramente al objetivo.
	KnockbackLift = 8,
	-- Duración del empuje de un golpe con Knockback.
	KnockbackSeconds = 0.2,
	-- Tras terminar un golpe de la cadena M1, tiempo para pedir el siguiente.
	ComboWindowSeconds = 0.8,
	-- Recuperación pasiva de postura fuera de Blocking y Stunned.
	PostureDecayPerSecond = 10,
	-- Tick de regeneración de recursos y postura (D-008).
	RegenTickSeconds = 0.25,
}

return CombatConfig
