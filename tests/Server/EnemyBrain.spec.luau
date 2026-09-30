local EnemyBrain = require(game:GetService("ServerScriptService").Server.Npc.EnemyBrain)

local AGGRO = { DetectionRange = 30, LoseRange = 60, LeashRange = 80 }

local function situation(overrides)
	local base = {
		State = "Idle",
		Returning = false,
		HomeDistance = 0,
		TargetDistance = nil,
		AttackReady = true,
		ReadyRange = 7,
		MinRange = 7,
		Aggro = AGGRO,
	}
	for key, value in overrides or {} do
		base[key] = value
	end
	return EnemyBrain.Decide(base)
end

local ATTACKS = {
	{ Ability = "Swipe", Range = 7, TelegraphSeconds = 0.5 },
	{ Ability = "Lunge", Range = 16, TelegraphSeconds = 0.5 },
}

local function allReady()
	return true
end

return {
	["sin objetivo se queda quieto"] = function()
		expect(situation()).toBe("Idle")
	end,

	["persigue a un objetivo fuera de alcance"] = function()
		expect(situation({ TargetDistance = 20 })).toBe("Chase")
	end,

	["ataca si está a alcance y puede"] = function()
		expect(situation({ TargetDistance = 5 })).toBe("Attack")
	end,

	["a alcance pero sin poder atacar, espera"] = function()
		expect(situation({ TargetDistance = 5, AttackReady = false })).toBe("Hold")
		-- Solo tiene listo un ataque que no llega (alcance 3).
		expect(situation({ TargetDistance = 5, ReadyRange = 3 })).toBe("Hold")
	end,

	["si solo el ataque largo está en cooldown, se acerca para el corto"] = function()
		expect(situation({ TargetDistance = 12, ReadyRange = 7, MinRange = 7 })).toBe("Chase")
	end,

	["ocupado (atacando o aturdido) no hace nada"] = function()
		expect(situation({ TargetDistance = 5, State = "Stunned" })).toBe("Busy")
	end,

	["lejos de casa vuelve aunque tenga objetivo"] = function()
		expect(situation({ TargetDistance = 5, HomeDistance = 81 })).toBe("Return")
	end,

	["volviendo, sigue hasta llegar a casa"] = function()
		expect(situation({ Returning = true, HomeDistance = 30, TargetDistance = 2 })).toBe("Return")
		expect(situation({ Returning = true, HomeDistance = 2 })).toBe("Idle")
	end,

	["PickAttack elige entre los que alcanzan y están listos"] = function()
		expect(EnemyBrain.PickAttack(ATTACKS, 12, 0, allReady).Ability).toBe("Lunge")
		expect(EnemyBrain.PickAttack(ATTACKS, 5, 0, allReady).Ability).toBe("Swipe")
		expect(EnemyBrain.PickAttack(ATTACKS, 5, 0.99, allReady).Ability).toBe("Lunge")
		local onlySwipe = function(id)
			return id == "Swipe"
		end
		expect(EnemyBrain.PickAttack(ATTACKS, 5, 0.99, onlySwipe).Ability).toBe("Swipe")
		expect(EnemyBrain.PickAttack(ATTACKS, 30, 0, allReady)).toBeNil()
	end,

	["Ranges da el mayor alcance listo y el menor de todos"] = function()
		local readyRange, minRange = EnemyBrain.Ranges(ATTACKS, allReady)
		expect(readyRange).toBe(16)
		expect(minRange).toBe(7)
		local noneReady, minimum = EnemyBrain.Ranges(ATTACKS, function()
			return false
		end)
		expect(noneReady).toBeNil()
		expect(minimum).toBe(7)
	end,

	["PhaseIndex elige la última fase cuyo umbral se ha cruzado"] = function()
		local boss = {
			Attacks = ATTACKS,
			AttackIntervalSeconds = 2,
			WalkSpeed = 10,
			Phases = { { HealthBelow = 0.6 }, { HealthBelow = 0.25 } },
		}
		expect(EnemyBrain.PhaseIndex(boss, 1)).toBe(0)
		expect(EnemyBrain.PhaseIndex(boss, 0.6)).toBe(1)
		expect(EnemyBrain.PhaseIndex(boss, 0.3)).toBe(1)
		expect(EnemyBrain.PhaseIndex(boss, 0.1)).toBe(2)
		expect(EnemyBrain.PhaseIndex({ Attacks = ATTACKS }, 0.1)).toBe(0)
	end,

	["PhaseSettings hereda lo que una fase no cambia"] = function()
		local fury = { { Ability = "Charge", Range = 30, TelegraphSeconds = 1 } }
		local boss = {
			Attacks = ATTACKS,
			AttackIntervalSeconds = 2,
			WalkSpeed = 10,
			Phases = {
				{ HealthBelow = 0.6, Attacks = fury, WalkSpeed = 15 },
				{ HealthBelow = 0.25, AttackIntervalSeconds = 1 },
			},
		}
		local base = EnemyBrain.PhaseSettings(boss, 0)
		expect(base.WalkSpeed).toBe(10)
		local last = EnemyBrain.PhaseSettings(boss, 2)
		expect(last.Attacks).toBe(fury)
		expect(last.WalkSpeed).toBe(15)
		expect(last.AttackIntervalSeconds).toBe(1)
	end,
}
