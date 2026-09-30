local Combat = game:GetService("ServerScriptService").Server.Combat
local Cooldowns = require(Combat.Cooldowns)
local ComboChain = require(Combat.ComboChain)
local DamageResolver = require(Combat.DamageResolver)
local TaskScheduler = require(Combat.TaskScheduler)

local CONFIG = {
	BlockDamageMultiplier = 0.25,
	BlockPostureMultiplier = 1.5,
	GuardBreakDamageMultiplier = 0.5,
}

local function hit(overrides)
	local input = {
		Damage = 10,
		PostureDamage = 10,
		GuardBreak = false,
		Knockback = 0,
		DefenderBlocking = false,
		DefenderInParryWindow = false,
		DefenderInvulnerable = false,
		DefenderPosture = 0,
		DefenderMaxPosture = 100,
	}
	for key, value in overrides or {} do
		input[key] = value
	end
	return DamageResolver.Resolve(input, CONFIG)
end

return {
	-- Cooldowns ----------------------------------------------------------------
	["Cooldowns: lista hasta que empieza y de nuevo al pasar el tiempo"] = function()
		local now = 0
		local cooldowns = Cooldowns.new(function()
			return now
		end)
		expect(cooldowns:IsReady("p", "A")).toBe(true)
		cooldowns:Start("p", "A", 2)
		expect(cooldowns:IsReady("p", "A")).toBe(false)
		expect(cooldowns:GetRemaining("p", "A")).toBe(2)
		now = 1.5
		expect(cooldowns:GetRemaining("p", "A")).toBe(0.5)
		now = 2
		expect(cooldowns:IsReady("p", "A")).toBe(true)
	end,

	["Cooldowns: son por dueño y por habilidad; Clear los borra"] = function()
		local cooldowns = Cooldowns.new(function()
			return 0
		end)
		cooldowns:Start("p1", "A", 5)
		expect(cooldowns:IsReady("p2", "A")).toBe(true)
		expect(cooldowns:IsReady("p1", "B")).toBe(true)
		cooldowns:Clear("p1")
		expect(cooldowns:IsReady("p1", "A")).toBe(true)
	end,

	["Cooldowns: un cooldown de 0 no bloquea"] = function()
		local cooldowns = Cooldowns.new()
		cooldowns:Start("p", "A", 0)
		expect(cooldowns:IsReady("p", "A")).toBe(true)
	end,

	-- ComboChain ---------------------------------------------------------------
	["ComboChain: empieza por el primero y avanza dentro de la ventana"] = function()
		expect(ComboChain.NextIndex(nil, 3, 0, 0.8)).toBe(1)
		expect(ComboChain.NextIndex({ Index = 1, EndsAt = 1 }, 3, 1.5, 0.8)).toBe(2)
		expect(ComboChain.NextIndex({ Index = 2, EndsAt = 1 }, 3, 1.8, 0.8)).toBe(3)
	end,

	["ComboChain: fuera de la ventana o tras el remate vuelve al primero"] = function()
		expect(ComboChain.NextIndex({ Index = 1, EndsAt = 1 }, 3, 1.9, 0.8)).toBe(1)
		expect(ComboChain.NextIndex({ Index = 3, EndsAt = 1 }, 3, 1.1, 0.8)).toBe(1)
	end,

	-- DamageResolver -----------------------------------------------------------
	["DamageResolver: golpe limpio aplica daño, postura y empuje"] = function()
		local outcome = hit({ Knockback = 30 })
		expect(outcome.Kind).toBe("Hit")
		expect(outcome.Damage).toBe(10)
		expect(outcome.PostureDamage).toBe(10)
		expect(outcome.Knockback).toBe(30)
		expect(outcome.PostureBreak).toBe(false)
	end,

	["DamageResolver: la invulnerabilidad evita todo"] = function()
		local outcome = hit({ DefenderInvulnerable = true, DefenderBlocking = true, DefenderInParryWindow = true })
		expect(outcome.Kind).toBe("Evaded")
		expect(outcome.Damage).toBe(0)
	end,

	["DamageResolver: bloquear reduce el daño y aumenta la postura, sin empuje"] = function()
		local outcome = hit({ DefenderBlocking = true, Knockback = 30 })
		expect(outcome.Kind).toBe("Blocked")
		expect(outcome.Damage).toBe(2.5)
		expect(outcome.PostureDamage).toBe(15)
		expect(outcome.Knockback).toBe(0)
	end,

	["DamageResolver: el parry anula el golpe, incluso uno que rompe guardias"] = function()
		local outcome = hit({ DefenderBlocking = true, DefenderInParryWindow = true, GuardBreak = true })
		expect(outcome.Kind).toBe("Parried")
		expect(outcome.Damage).toBe(0)
	end,

	["DamageResolver: romper la guardia hace medio daño y aturde"] = function()
		local outcome = hit({ DefenderBlocking = true, GuardBreak = true, Knockback = 20 })
		expect(outcome.Kind).toBe("GuardBroken")
		expect(outcome.Damage).toBe(5)
		expect(outcome.PostureBreak).toBe(true)
		expect(outcome.Knockback).toBe(20)
	end,

	["DamageResolver: llenar la postura la rompe, bloqueando o no"] = function()
		expect(hit({ DefenderPosture = 90 }).PostureBreak).toBe(true)
		expect(hit({ DefenderPosture = 85, DefenderBlocking = true }).PostureBreak).toBe(true)
		expect(hit({ DefenderPosture = 80 }).PostureBreak).toBe(false)
	end,

	-- TaskScheduler ------------------------------------------------------------
	["TaskScheduler: ejecuta las tareas y las saca de la lista"] = function()
		local scheduler = TaskScheduler.new()
		local ran = false
		scheduler:Schedule("A", 0, function()
			ran = true
		end)
		expect(scheduler:HasPending("A")).toBe(true)
		task.wait(0.05)
		expect(ran).toBe(true)
		expect(scheduler:HasPending("A")).toBe(false)
	end,

	["TaskScheduler: CancelGroup cancela solo ese grupo"] = function()
		local scheduler = TaskScheduler.new()
		local ranA, ranB = false, false
		scheduler:Schedule("A", 0.01, function()
			ranA = true
		end)
		scheduler:Schedule("B", 0.01, function()
			ranB = true
		end)
		scheduler:CancelGroup("A")
		task.wait(0.05)
		expect(ranA).toBe(false)
		expect(ranB).toBe(true)
	end,

	["TaskScheduler: tras Destroy cancela todo y no acepta tareas"] = function()
		local scheduler = TaskScheduler.new()
		local ran = false
		scheduler:Schedule("A", 0.01, function()
			ran = true
		end)
		scheduler:Destroy()
		expect(scheduler:Schedule("A", 0, function() end)).toBeNil()
		task.wait(0.05)
		expect(ran).toBe(false)
	end,

	["TaskScheduler: una tarea puede cancelar su propio grupo"] = function()
		local scheduler = TaskScheduler.new()
		local after = false
		scheduler:Schedule("A", 0, function()
			scheduler:CancelGroup("A")
			after = true
		end)
		task.wait(0.05)
		expect(after).toBe(true)
	end,
}
