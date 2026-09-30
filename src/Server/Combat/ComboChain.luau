--!strict

-- Progresión de una cadena de ataques (M1): pedir el siguiente golpe dentro de
-- la ventana de combo avanza; fuera de ella, o tras el último, vuelve al primero.

export type ChainProgress = {
	-- Índice del último golpe ejecutado.
	Index: number,
	-- Momento en que termina ese golpe.
	EndsAt: number,
}

local ComboChain = {}

-- Índice del golpe que toca ahora en una cadena de `length` golpes.
function ComboChain.NextIndex(progress: ChainProgress?, length: number, now: number, windowSeconds: number): number
	if progress == nil or progress.Index >= length then
		return 1
	end
	if now - progress.EndsAt > windowSeconds then
		return 1
	end
	return progress.Index + 1
end

return ComboChain
