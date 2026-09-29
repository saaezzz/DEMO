local RateLimiter = require(game:GetService("ServerScriptService").Server.Modules.RateLimiter)

local function withClock()
	local clock = { now = 0 }
	return clock, function()
		return clock.now
	end
end

return {
	["permite una ráfaga hasta la capacidad"] = function()
		local _, now = withClock()
		local limiter = RateLimiter.new(3, 1, now)
		expect(limiter:Consume("p")).toBe(true)
		expect(limiter:Consume("p")).toBe(true)
		expect(limiter:Consume("p")).toBe(true)
		expect(limiter:Consume("p")).toBe(false)
	end,

	["recarga tokens con el tiempo"] = function()
		local clock, now = withClock()
		local limiter = RateLimiter.new(2, 2, now)
		limiter:Consume("p")
		limiter:Consume("p")

		clock.now = 0.5

		expect(limiter:Consume("p")).toBe(true)
		expect(limiter:Consume("p")).toBe(false)
	end,

	["la recarga no supera la capacidad"] = function()
		local clock, now = withClock()
		local limiter = RateLimiter.new(2, 10, now)
		limiter:Consume("p")

		clock.now = 100

		expect(limiter:Consume("p")).toBe(true)
		expect(limiter:Consume("p")).toBe(true)
		expect(limiter:Consume("p")).toBe(false)
	end,

	["cada clave tiene su propio bucket"] = function()
		local _, now = withClock()
		local limiter = RateLimiter.new(1, 1, now)
		expect(limiter:Consume("a")).toBe(true)
		expect(limiter:Consume("b")).toBe(true)
		expect(limiter:Consume("a")).toBe(false)
	end,

	["Remove y Clear reinician los buckets"] = function()
		local _, now = withClock()
		local limiter = RateLimiter.new(1, 1, now)
		limiter:Consume("a")
		limiter:Consume("b")

		limiter:Remove("a")
		expect(limiter:Consume("a")).toBe(true)

		limiter:Clear()
		expect(limiter:Consume("b")).toBe(true)
	end,

	["admite coste personalizado"] = function()
		local _, now = withClock()
		local limiter = RateLimiter.new(5, 1, now)
		expect(limiter:Consume("p", 4)).toBe(true)
		expect(limiter:Consume("p", 2)).toBe(false)
	end,

	["rechaza configuraciones inválidas"] = function()
		expect(function()
			RateLimiter.new(0, 1)
		end).toThrow("capacity")
		expect(function()
			RateLimiter.new(1, 0)
		end).toThrow("refillPerSecond")
	end,
}
