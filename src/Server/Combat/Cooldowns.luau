--!strict

-- Cooldowns por dueño (jugador o personaje) y habilidad (§17 CooldownService).
-- El reloj se inyecta para poder testearlo.

local Cooldowns = {}
Cooldowns.__index = Cooldowns

type CooldownsData = {
	_readyAt: { [any]: { [string]: number } },
	_clock: () -> number,
}

export type Cooldowns = typeof(setmetatable({} :: CooldownsData, Cooldowns))

function Cooldowns.new(clock: (() -> number)?): Cooldowns
	return setmetatable({
		_readyAt = {},
		_clock = clock or os.clock,
	}, Cooldowns)
end

-- Segundos que faltan para poder usarla (0 si ya está lista).
function Cooldowns.GetRemaining(self: Cooldowns, owner: any, abilityId: string): number
	local byOwner = self._readyAt[owner]
	local readyAt = if byOwner ~= nil then byOwner[abilityId] else nil
	if readyAt == nil then
		return 0
	end
	return math.max(0, readyAt - self._clock())
end

function Cooldowns.IsReady(self: Cooldowns, owner: any, abilityId: string): boolean
	return self:GetRemaining(owner, abilityId) <= 0
end

function Cooldowns.Start(self: Cooldowns, owner: any, abilityId: string, seconds: number): ()
	if seconds <= 0 then
		return
	end
	local byOwner = self._readyAt[owner]
	if byOwner == nil then
		byOwner = {}
		self._readyAt[owner] = byOwner
	end
	byOwner[abilityId] = self._clock() + seconds
end

function Cooldowns.Clear(self: Cooldowns, owner: any): ()
	self._readyAt[owner] = nil
end

return Cooldowns
