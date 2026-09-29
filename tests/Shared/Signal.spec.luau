local Signal = require(game:GetService("ReplicatedStorage").Shared.Utils.Signal)

return {
	["Fire llama a los handlers en orden y con los argumentos"] = function()
		local signal = Signal.new()
		local calls = {}
		signal:Connect(function(a, b)
			table.insert(calls, "first:" .. a .. b)
		end)
		signal:Connect(function(a, b)
			table.insert(calls, "second:" .. a .. b)
		end)

		signal:Fire("x", "y")

		expect(calls).toEqual({ "first:xy", "second:xy" })
	end,

	["Fire es síncrono"] = function()
		local signal = Signal.new()
		local fired = false
		signal:Connect(function()
			fired = true
		end)

		signal:Fire()

		expect(fired).toBe(true)
	end,

	["Disconnect deja de recibir emisiones"] = function()
		local signal = Signal.new()
		local count = 0
		local connection = signal:Connect(function()
			count += 1
		end)

		signal:Fire()
		connection:Disconnect()
		signal:Fire()

		expect(count).toBe(1)
		expect(connection.Connected).toBe(false)
	end,

	["Disconnect dos veces no falla"] = function()
		local connection = Signal.new():Connect(function() end)
		connection:Disconnect()
		connection:Disconnect()
		expect(connection.Connected).toBe(false)
	end,

	["Once se ejecuta una sola vez"] = function()
		local signal = Signal.new()
		local count = 0
		signal:Once(function()
			count += 1
		end)

		signal:Fire()
		signal:Fire()

		expect(count).toBe(1)
	end,

	["un handler desconectado durante Fire antes de su turno no se llama"] = function()
		local signal = Signal.new()
		local secondCalled = false
		local second
		signal:Connect(function()
			second:Disconnect()
		end)
		second = signal:Connect(function()
			secondCalled = true
		end)

		signal:Fire()

		expect(secondCalled).toBe(false)
	end,

	["conectar durante Fire no afecta a esa emisión"] = function()
		local signal = Signal.new()
		local lateCalls = 0
		signal:Connect(function()
			signal:Connect(function()
				lateCalls += 1
			end)
		end)

		signal:Fire()

		expect(lateCalls).toBe(0)
	end,

	["DisconnectAll desconecta todo"] = function()
		local signal = Signal.new()
		local count = 0
		local connection = signal:Connect(function()
			count += 1
		end)

		signal:DisconnectAll()
		signal:Fire()

		expect(count).toBe(0)
		expect(connection.Connected).toBe(false)
	end,

	["el error de un handler se propaga a Fire"] = function()
		local signal = Signal.new()
		signal:Connect(function()
			error("boom")
		end)

		expect(function()
			signal:Fire()
		end).toThrow("boom")
	end,
}
