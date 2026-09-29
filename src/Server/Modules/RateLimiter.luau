--!strict

-- Rate limiter tipo token bucket, por clave (normalmente un Player).
-- Luau puro: no depende de `game` para poder testearse fuera de Studio.

export type Clock = () -> number

type Bucket = {
	Tokens: number,
	LastRefill: number,
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

type RateLimiterData = {
	_capacity: number,
	_refillPerSecond: number,
	_clock: Clock,
	_buckets: { [unknown]: Bucket },
}

export type RateLimiter = typeof(setmetatable({} :: RateLimiterData, RateLimiter))

-- capacity: ráfaga máxima permitida. refillPerSecond: ritmo sostenido permitido.
function RateLimiter.new(capacity: number, refillPerSecond: number, clock: Clock?): RateLimiter
	assert(capacity > 0, "capacity debe ser > 0")
	assert(refillPerSecond > 0, "refillPerSecond debe ser > 0")

	return setmetatable({
		_capacity = capacity,
		_refillPerSecond = refillPerSecond,
		_clock = clock or os.clock,
		_buckets = {},
	}, RateLimiter)
end

-- Devuelve el bucket de la clave con los tokens recargados hasta `now`.
local function getRefilledBucket(self: RateLimiter, key: unknown, now: number): Bucket
	local bucket: Bucket? = self._buckets[key]
	if bucket == nil then
		local newBucket: Bucket = { Tokens = self._capacity, LastRefill = now }
		self._buckets[key] = newBucket
		return newBucket
	end

	local elapsed = math.max(now - bucket.LastRefill, 0)
	bucket.Tokens = math.min(self._capacity, bucket.Tokens + elapsed * self._refillPerSecond)
	bucket.LastRefill = now
	return bucket
end

function RateLimiter.Consume(self: RateLimiter, key: unknown, cost: number?): boolean
	local amount = cost or 1
	local bucket = getRefilledBucket(self, key, self._clock())

	if bucket.Tokens < amount then
		return false
	end

	bucket.Tokens -= amount
	return true
end

function RateLimiter.Remove(self: RateLimiter, key: unknown): ()
	self._buckets[key] = nil
end

function RateLimiter.Clear(self: RateLimiter): ()
	table.clear(self._buckets)
end

return RateLimiter
