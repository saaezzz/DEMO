local Combat = game:GetService("ServerScriptService").Server.Combat
local Cooldowns = require(Combat.Cooldowns)
local ComboChain = require(Combat.ComboChain)
local DamageResolver = require(Combat.DamageResolver)
local Modifiers = require(Combat.Modifiers)
local AmbientDensity = require(game:GetService("ServerScriptService").Server.Modules.AmbientDensity)
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
		DefenderHealth = 100,
		DefenderMaxHealth = 100,
		DamageMultiplier = 1,
		Execute = nil,
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

	["DamageResolver: el multiplicador de modificadores escala el daño, también bloqueando"] = function()
		expect(hit({ DamageMultiplier = 0.5 }).Damage).toBe(5)
		expect(hit({ DamageMultiplier = 2, DefenderBlocking = true }).Damage).toBe(5)
	end,

	["DamageResolver: el remate derrota a un objetivo debilitado con un golpe limpio"] = function()
		local execute = { HealthFraction = 0.3, MaxDamage = 150 }
		local result = hit({ DefenderHealth = 25, Execute = execute })
		expect(result.Executed).toBe(true)
		expect(result.Damage).toBe(25)
		-- Por encima del umbral, golpe normal.
		local healthy = hit({ DefenderHealth = 40, Execute = execute })
		expect(healthy.Executed).toBe(false)
		expect(healthy.Damage).toBe(10)
	end,

	["DamageResolver: el remate no entra si se bloquea ni contra mucha vida (jefes)"] = function()
		local execute = { HealthFraction = 0.3, MaxDamage = 150 }
		expect(hit({ DefenderHealth = 20, Execute = execute, DefenderBlocking = true }).Executed).toBe(false)
		local boss = hit({ DefenderHealth = 400, DefenderMaxHealth = 1600, Execute = execute })
		expect(boss.Executed).toBe(false)
		expect(boss.Damage).toBe(10)
	end,

	-- Modifiers ----------------------------------------------------------------
	["Modifiers: sin modificadores el multiplicador es 1; se multiplican entre sí"] = function()
		local set = {}
		expect(Modifiers.Multiplier(set, "DamageTaken", 0)).toBe(1)
		Modifiers.Apply(set, { Id = "A", Duration = 5, DamageTaken = 0.5 }, 0)
		Modifiers.Apply(set, { Id = "B", Duration = 5, DamageTaken = 0.8, DamageDealt = 1.5 }, 0)
		expect(math.abs(Modifiers.Multiplier(set, "DamageTaken", 1) - 0.4) < 1e-9).toBe(true)
		expect(Modifiers.Multiplier(set, "DamageDealt", 1)).toBe(1.5)
	end,

	["Modifiers: caducan y el mismo Id se renueva sin acumularse"] = function()
		local set = {}
		Modifiers.Apply(set, { Id = "A", Duration = 5, DamageTaken = 0.5 }, 0)
		Modifiers.Apply(set, { Id = "A", Duration = 5, DamageTaken = 0.5 }, 3)
		expect(Modifiers.Multiplier(set, "DamageTaken", 6)).toBe(0.5)
		expect(Modifiers.Multiplier(set, "DamageTaken", 8)).toBe(1)
		expect(set.A).toBeNil()
	end,

	-- AmbientDensity -------------------------------------------------------------
	["AmbientDensity: fuera de toda zona da la densidad por defecto"] = function()
		local zones = { { Id = "Z", DisplayName = "Z", Center = Vector3.new(0, 0, 0), Radius = 10, Density = 2 } }
		local density, zone = AmbientDensity.At(Vector3.new(50, 0, 0), zones, 1)
		expect(density).toBe(1)
		expect(zone).toBeNil()
	end,

	["AmbientDensity: dentro gana la zona más densa; la altura no cuenta"] = function()
		local zones = {
			{ Id = "A", DisplayName = "A", Center = Vector3.new(0, 0, 0), Radius = 20, Density = 1.5 },
			{ Id = "B", DisplayName = "B", Center = Vector3.new(5, 0, 0), Radius = 10, Density = 2 },
		}
		local density, zone = AmbientDensity.At(Vector3.new(6, 40, 0), zones, 1)
		expect(density).toBe(2)
		expect(zone.Id).toBe("B")
		local onlyA = AmbientDensity.At(Vector3.new(-15, 0, 0), zones, 1)
		expect(onlyA).toBe(1.5)
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
