--!strict

-- Ciclo de día y noche (D-044). Lógica pura: hora del juego a partir del
-- tiempo real (el día y la noche pueden durar distinto), si es de noche y la
-- iluminación interpolada entre preajustes.

export type CycleConfig = {
	DayMinutes: number,
	NightMinutes: number,
	SunriseHour: number,
	SunsetHour: number,
	StartHour: number,
	LightsOnHour: number,
	LightsOffHour: number,
}

export type Preset = { Hour: number, [string]: any }

local DayCycle = {}

local function wrap(hour: number): number
	return hour % 24
end

-- Horas de juego por segundo real en esta hora del día.
function DayCycle.HoursPerSecond(hour: number, config: CycleConfig): number
	local dayHours = config.SunsetHour - config.SunriseHour
	local nightHours = 24 - dayHours
	local isDay = hour >= config.SunriseHour and hour < config.SunsetHour
	if isDay then
		return dayHours / (config.DayMinutes * 60)
	end
	return nightHours / (config.NightMinutes * 60)
end

-- Hora tras avanzar `seconds` segundos reales desde `hour`. Respeta el cambio
-- de velocidad al cruzar el amanecer o el anochecer.
function DayCycle.Advance(hour: number, seconds: number, config: CycleConfig): number
	local current = wrap(hour)
	local remaining = seconds
	-- Como mucho unos pocos tramos por llamada (una llamada cubre poco tiempo).
	for _ = 1, 8 do
		if remaining <= 0 then
			break
		end
		local rate = DayCycle.HoursPerSecond(current, config)
		local isDay = current >= config.SunriseHour and current < config.SunsetHour
		local boundary = if isDay then config.SunsetHour else config.SunriseHour
		local hoursToBoundary = wrap(boundary - current)
		if hoursToBoundary == 0 then
			hoursToBoundary = 24
		end
		local secondsToBoundary = hoursToBoundary / rate
		if remaining < secondsToBoundary then
			return wrap(current + remaining * rate)
		end
		current = wrap(boundary)
		remaining -= secondsToBoundary
	end
	return current
end

-- ¿Encendidas las luces de la ciudad a esta hora?
function DayCycle.LightsOn(hour: number, config: CycleConfig): boolean
	local h = wrap(hour)
	return h >= config.LightsOnHour or h < config.LightsOffHour
end

local function lerpValue(a: any, b: any, t: number): any
	if typeof(a) == "number" then
		return a + (b - a) * t
	elseif typeof(a) == "Color3" then
		return (a :: Color3):Lerp(b :: Color3, t)
	end
	return if t < 0.5 then a else b
end

-- Preajuste interpolado para la hora `hour` (los preajustes, ordenados por
-- hora; entre el último y el primero se interpola cruzando la medianoche).
function DayCycle.Blend(presets: { Preset }, hour: number): { [string]: any }
	local h = wrap(hour)
	local count = #presets
	local before, after = presets[count], presets[1]
	for i = 1, count do
		if presets[i].Hour <= h then
			before = presets[i]
			after = presets[i % count + 1]
		end
	end
	local span = wrap(after.Hour - before.Hour)
	local t = if span > 0 then wrap(h - before.Hour) / span else 0
	local result: { [string]: any } = {}
	for key, value in before do
		if key ~= "Hour" then
			result[key] = lerpValue(value, after[key], math.clamp(t, 0, 1))
		end
	end
	return result
end

-- "HH:MM" de una hora decimal.
function DayCycle.Format(hour: number): string
	local h = wrap(hour)
	local hours = math.floor(h)
	local minutes = math.floor((h - hours) * 60)
	return string.format("%02d:%02d", hours, minutes)
end

return DayCycle
