local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DayCycle = require(ReplicatedStorage.Shared.Modules.DayCycle)
local EnvironmentConfig = require(ReplicatedStorage.Shared.Config.EnvironmentConfig)

-- Día de 12 h en 12 min (1 h/min) y noche de 12 h en 6 min (2 h/min).
local CONFIG = {
	DayMinutes = 12,
	NightMinutes = 6,
	SunriseHour = 6,
	SunsetHour = 18,
	StartHour = 9,
	LightsOnHour = 18.5,
	LightsOffHour = 6,
}

local function near(a, b)
	return math.abs(a - b) < 1e-6
end

return {
	["Advance: de día avanza a la velocidad del día"] = function()
		expect(near(DayCycle.Advance(9, 60, CONFIG), 10)).toBe(true)
	end,

	["Advance: de noche avanza a la velocidad de la noche"] = function()
		expect(near(DayCycle.Advance(20, 60, CONFIG), 22)).toBe(true)
	end,

	["Advance: al anochecer cambia de velocidad a mitad del tramo"] = function()
		-- 17 h + 60 s de día = 18 h; los 60 s restantes, de noche = 2 h más.
		expect(near(DayCycle.Advance(17, 120, CONFIG), 20)).toBe(true)
	end,

	["Advance: pasa de medianoche"] = function()
		expect(near(DayCycle.Advance(23, 60, CONFIG), 1)).toBe(true)
	end,

	["LightsOn: encendidas de noche y apagadas de día"] = function()
		expect(DayCycle.LightsOn(20, CONFIG)).toBe(true)
		expect(DayCycle.LightsOn(3, CONFIG)).toBe(true)
		expect(DayCycle.LightsOn(12, CONFIG)).toBe(false)
		expect(DayCycle.LightsOn(18.4, CONFIG)).toBe(false)
	end,

	["Blend: en la hora de un preajuste devuelve sus valores"] = function()
		local presets = {
			{ Hour = 0, Brightness = 1, Tint = Color3.new(0, 0, 0) },
			{ Hour = 12, Brightness = 3, Tint = Color3.new(1, 1, 1) },
		}
		local noon = DayCycle.Blend(presets, 12)
		expect(noon.Brightness).toBe(3)
		expect(noon.Hour).toBeNil()
	end,

	["Blend: interpola números y colores, también cruzando la medianoche"] = function()
		local presets = {
			{ Hour = 6, Brightness = 2, Tint = Color3.new(0, 0, 0) },
			{ Hour = 18, Brightness = 0, Tint = Color3.new(1, 1, 1) },
		}
		local afternoon = DayCycle.Blend(presets, 12)
		expect(near(afternoon.Brightness, 1)).toBe(true)
		expect(near(afternoon.Tint.R, 0.5)).toBe(true)
		-- De 18 h a 6 h (12 h): a medianoche va por la mitad.
		expect(near(DayCycle.Blend(presets, 0).Brightness, 1)).toBe(true)
	end,

	["Format: HH:MM"] = function()
		expect(DayCycle.Format(9.5)).toBe("09:30")
		expect(DayCycle.Format(24.25)).toBe("00:15")
	end,

	["los preajustes de la configuración están ordenados y tienen las mismas claves"] = function()
		local presets = EnvironmentConfig.Presets
		for i = 2, #presets do
			expect(presets[i].Hour > presets[i - 1].Hour).toBe(true)
		end
		for i = 2, #presets do
			for key in presets[1] do
				if presets[i][key] == nil then
					error(`preajuste de las {presets[i].Hour} h: falta {key}`)
				end
			end
		end
		expect(EnvironmentConfig.SunriseHour < EnvironmentConfig.SunsetHour).toBe(true)
	end,
}
