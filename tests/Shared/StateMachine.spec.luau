local StateMachine = require(game:GetService("ReplicatedStorage").Shared.Modules.StateMachine)

local TRANSITIONS = {
	Idle = { "Attacking", "Stunned" },
	Attacking = { "Idle", "Stunned" },
	Stunned = { "Idle" },
}

return {
	["empieza en el estado inicial"] = function()
		local machine = StateMachine.new("Idle", TRANSITIONS)
		expect(machine:GetState()).toBe("Idle")
	end,

	["permite transiciones de la tabla"] = function()
		local machine = StateMachine.new("Idle", TRANSITIONS)
		local ok = machine:TransitionTo("Attacking")
		expect(ok).toBe(true)
		expect(machine:GetState()).toBe("Attacking")
	end,

	["rechaza transiciones fuera de la tabla"] = function()
		local machine = StateMachine.new("Stunned", TRANSITIONS)
		expect(machine:CanTransition("Attacking")).toBe(false)
		local ok, reason = machine:TransitionTo("Attacking")
		expect(ok).toBe(false)
		expect(reason).toBeTruthy()
		expect(machine:GetState()).toBe("Stunned")
	end,

	["rechaza transicionar al mismo estado"] = function()
		local machine = StateMachine.new("Idle", TRANSITIONS)
		expect((machine:TransitionTo("Idle"))).toBe(false)
	end,

	["notifica los cambios de estado con estado anterior y nuevo"] = function()
		local machine = StateMachine.new("Idle", TRANSITIONS)
		local seen = {}
		machine:OnStateChanged(function(oldState, newState)
			table.insert(seen, oldState .. "->" .. newState)
		end)

		machine:TransitionTo("Attacking")
		machine:TransitionTo("Stunned")

		expect(seen).toEqual({ "Idle->Attacking", "Attacking->Stunned" })
	end,

	["tras Destroy no transiciona ni notifica"] = function()
		local machine = StateMachine.new("Idle", TRANSITIONS)
		local notified = false
		machine:OnStateChanged(function()
			notified = true
		end)

		machine:Destroy()

		expect((machine:TransitionTo("Attacking"))).toBe(false)
		expect(machine:GetState()).toBe("Idle")
		expect(notified).toBe(false)
	end,
}
