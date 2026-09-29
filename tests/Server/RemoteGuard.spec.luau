local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteGuard = require(ServerScriptService.Server.Network.RemoteGuard)
local RateLimiter = require(ServerScriptService.Server.Modules.RateLimiter)
local Schema = require(ReplicatedStorage.Shared.Network.Schema)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local validate = Schema.record({ Value = Schema.number(0, 10) })

local function setup(handler, capacity)
	local logs = {}
	Logger.SetLevel("Debug")
	Logger.SetSink(function(level, message)
		table.insert(logs, { level, message })
	end)
	local limiter = RateLimiter.new(capacity or 10, 1, function()
		return 0
	end)
	local guarded = RemoteGuard.wrap("Test", limiter, validate, handler, Logger.new("Test"))
	return guarded, logs
end

return {
	["pasa al handler el payload saneado y devuelve su respuesta"] = function()
		local received
		local guarded = setup(function(player, payload)
			received = { player, payload }
			return "ok"
		end)

		local payload = { Value = 3 }
		expect(guarded("player1", payload)).toBe("ok")
		expect(received[1]).toBe("player1")
		expect(received[2].Value).toBe(3)
		expect(received[2] == payload).toBe(false)
	end,

	["un payload inválido no llega al handler y devuelve nil"] = function()
		local called = false
		local guarded, logs = setup(function()
			called = true
		end)

		expect(guarded("player1", { Value = 99 })).toBeNil()
		expect(called).toBe(false)
		expect(logs[1][1]).toBe("Debug")
	end,

	["aplica rate limit por jugador"] = function()
		local calls = 0
		local guarded = setup(function()
			calls += 1
			return true
		end, 2)

		guarded("a", { Value = 1 })
		guarded("a", { Value = 1 })
		expect(guarded("a", { Value = 1 })).toBeNil()
		expect(guarded("b", { Value = 1 })).toBe(true)
		expect(calls).toBe(3)
	end,

	["un error del handler se registra y devuelve nil sin propagarse"] = function()
		local guarded, logs = setup(function()
			error("fallo interno")
		end)

		expect(guarded("player1", { Value = 1 })).toBeNil()
		expect(logs[#logs][1]).toBe("Error")
		expect(string.find(logs[#logs][2], "fallo interno", 1, true) ~= nil).toBe(true)
	end,
}
