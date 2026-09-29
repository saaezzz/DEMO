--!strict

-- Rate limiter tipo token bucket, por clave (normalmente un Player).
-- Luau puro: no depende de `game` para poder testearse fuera de Studio.

export type Clock = () -> number

export type RateLimiter<K> = {
	Consume: (self: RateLimiter<K>, key: K, cost: number?) -> boolean,
	Remove: (self: RateLimiter<K>, key: K) -> (),
	Clear: (self: RateLimiter<K>) -> (),
}

type Bucket = {
	Tokens: number,
	LastRefill: number,
}

type RateLimiterInternal<K> = RateLimiter<K> & {
	_capacity: number,
	_refillPerSecond: number,
	_clock: Clock,
	_buckets: { [K]: Bucket },
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

-- capacity: ráfaga máxima permitida. refillPerSecond: ritmo sostenido permitido.
function RateLimiter.new<K>(capacity: number, refillPerSecond: number, clock: Clock?): RateLimiter<K>
	assert(capacity > 0, "capacity debe ser > 0")
	assert(refillPerSecond > 0, "refillPerSecond debe ser > 0")

	local self = setmetatable({
		_capacity = capacity,
		_refillPerSecond = refillPerSecond,
		_clock = clock or os.clock,
		_buckets = {},
	}, RateLimiter)

	return (self :: any) :: RateLimiter<K>
end

function RateLimiter:Consume<K>(key: K, cost: number?): boolean
	local self = (self :: any) :: RateLimiterInternal<K>
	local amount = cost or 1
	local now = self._clock()

	local bucket = self._buckets[key]
	if bucket == nil then
		bucket = { Tokens = self._capacity, LastRefill = now }
		self._buckets[key] = bucket
	else
		local elapsed = math.max(now - bucket.LastRefill, 0)
		bucket.Tokens = math.min(self._capacity, bucket.Tokens + elapsed * self._refillPerSecond)
		bucket.LastRefill = now
	end

	if bucket.Tokens < amount then
		return false
	end

	bucket.Tokens -= amount
	return true
end

function RateLimiter:Remove<K>(key: K): ()
	local self = (self :: any) :: RateLimiterInternal<K>
	self._buckets[key] = nil
end

function RateLimiter:Clear<K>(): ()
	local self = (self :: any) :: RateLimiterInternal<K>
	table.clear(self._buckets)
end

return RateLimiter
