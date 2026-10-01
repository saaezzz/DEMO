--!strict

-- Números pseudoaleatorios con semilla: la misma semilla genera siempre el
-- mismo mapa (el modelo del repositorio no cambia si no cambian los datos).

export type Rng = {
	Next: (self: Rng) -> number,
	Range: (self: Rng, min: number, max: number) -> number,
	Int: (self: Rng, min: number, max: number) -> number,
	Chance: (self: Rng, probability: number) -> boolean,
	Pick: <T>(self: Rng, list: { T }) -> T,
	_state: number,
}

local MODULUS = 2147483647
local MULTIPLIER = 48271

local Rng = {}
Rng.__index = Rng

function Rng.new(seed: number): Rng
	local state = math.floor(math.abs(seed)) % MODULUS
	if state == 0 then
		state = 1
	end
	return (setmetatable({ _state = state }, Rng) :: any) :: Rng
end

-- [0, 1)
function Rng.Next(self: Rng): number
	self._state = (self._state * MULTIPLIER) % MODULUS
	return (self._state - 1) / (MODULUS - 1)
end

function Rng.Range(self: Rng, min: number, max: number): number
	return min + (max - min) * self:Next()
end

function Rng.Int(self: Rng, min: number, max: number): number
	return math.min(max, min + math.floor(self:Next() * (max - min + 1)))
end

function Rng.Chance(self: Rng, probability: number): boolean
	return self:Next() < probability
end

function Rng.Pick<T>(self: Rng, list: { T }): T
	return list[self:Int(1, #list)]
end

return Rng
