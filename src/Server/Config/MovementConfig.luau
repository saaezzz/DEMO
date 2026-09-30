--!strict

-- Valores de movimiento (no IP). Provisionales hasta BALANCE.md.

local MovementConfig = {
	-- WalkSpeed del Humanoid según la situación.
	RunSpeed = 16,
	SprintSpeed = 26,
	-- Mientras ataca, bloquea o canaliza.
	SlowSpeed = 8,
	-- Aturdido o derribado.
	StunnedSpeed = 3,
	-- Recurso que gasta el sprint y cuánto por segundo.
	SprintResource = "Stamina",
	SprintCostPerSecond = 12,
	-- Stamina mínima para empezar a correr (evita un sprint entrecortado al
	-- regenerar tras agotarla). Una vez corriendo, sigue hasta vaciarla.
	SprintMinToStart = 15,
	-- Por debajo de esta magnitud de MoveDirection se considera parado.
	MovingThreshold = 0.1,
	-- Frecuencia con la que se actualizan locomoción y velocidad.
	TickSeconds = 0.1,
}

return MovementConfig
