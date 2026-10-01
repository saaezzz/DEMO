--!strict

-- Ambiente (D-044): duración del día y de la noche e iluminación por hora.
-- El servidor avanza la hora (Lighting.ClockTime) y cada cliente interpola
-- la iluminación entre los preajustes más cercanos.

export type LightingPreset = {
	-- Hora del día (0-24) en la que se aplica tal cual.
	Hour: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	Brightness: number,
	ExposureCompensation: number,
	AtmosphereColor: Color3,
	AtmosphereDecay: Color3,
	AtmosphereDensity: number,
	AtmosphereHaze: number,
	Tint: Color3,
	Saturation: number,
	Contrast: number,
	BloomIntensity: number,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local EnvironmentConfig = {
	-- Minutos reales que dura cada parte del día.
	DayMinutes = 18,
	NightMinutes = 8,
	-- Hora de amanecer y de anochecer (el día va de una a otra).
	SunriseHour = 6,
	SunsetHour = 19,
	-- Hora al arrancar el servidor.
	StartHour = 9,
	-- Las luces de la ciudad se encienden entre estas horas.
	LightsOnHour = 18.3,
	LightsOffHour = 6.4,
	-- Cada cuánto actualiza el servidor la hora (segundos).
	ServerTickSeconds = 0.5,
	-- Agua de Terrain de los ríos y el mar.
	WaterColor = rgb(45, 104, 112),
	WaterTransparency = 0.55,
	WaterReflectance = 0.6,
	WaterWaveSize = 0.08,
	WaterWaveSpeed = 6,
	CloudCover = 0.55,
	CloudDensity = 0.45,
}

-- Ordenados por hora. Entre dos preajustes se interpola; de 21 h a 4 h, noche.
EnvironmentConfig.Presets = {
	{
		Hour = 0,
		Ambient = rgb(28, 32, 52),
		OutdoorAmbient = rgb(48, 56, 90),
		Brightness = 0.4,
		ExposureCompensation = 0.1,
		AtmosphereColor = rgb(40, 48, 78),
		AtmosphereDecay = rgb(24, 28, 50),
		AtmosphereDensity = 0.36,
		AtmosphereHaze = 1.2,
		Tint = rgb(190, 205, 255),
		Saturation = -0.1,
		Contrast = 0.1,
		BloomIntensity = 0.9,
	},
	{
		Hour = 4.5,
		Ambient = rgb(30, 34, 55),
		OutdoorAmbient = rgb(52, 60, 95),
		Brightness = 0.5,
		ExposureCompensation = 0.1,
		AtmosphereColor = rgb(45, 52, 85),
		AtmosphereDecay = rgb(30, 34, 60),
		AtmosphereDensity = 0.36,
		AtmosphereHaze = 1.4,
		Tint = rgb(195, 208, 255),
		Saturation = -0.1,
		Contrast = 0.1,
		BloomIntensity = 0.9,
	},
	{
		Hour = 6.2,
		Ambient = rgb(90, 80, 90),
		OutdoorAmbient = rgb(150, 120, 120),
		Brightness = 1.6,
		ExposureCompensation = 0,
		AtmosphereColor = rgb(235, 170, 150),
		AtmosphereDecay = rgb(200, 120, 110),
		AtmosphereDensity = 0.34,
		AtmosphereHaze = 2.2,
		Tint = rgb(255, 225, 215),
		Saturation = 0.05,
		Contrast = 0.05,
		BloomIntensity = 0.5,
	},
	{
		Hour = 9,
		Ambient = rgb(110, 110, 115),
		OutdoorAmbient = rgb(140, 140, 145),
		Brightness = 2.6,
		ExposureCompensation = 0,
		AtmosphereColor = rgb(205, 220, 235),
		AtmosphereDecay = rgb(140, 170, 205),
		AtmosphereDensity = 0.3,
		AtmosphereHaze = 1.6,
		Tint = rgb(255, 252, 245),
		Saturation = 0.08,
		Contrast = 0.04,
		BloomIntensity = 0.35,
	},
	{
		Hour = 15,
		Ambient = rgb(115, 112, 110),
		OutdoorAmbient = rgb(145, 140, 135),
		Brightness = 2.6,
		ExposureCompensation = 0,
		AtmosphereColor = rgb(215, 220, 230),
		AtmosphereDecay = rgb(150, 170, 200),
		AtmosphereDensity = 0.3,
		AtmosphereHaze = 1.7,
		Tint = rgb(255, 248, 238),
		Saturation = 0.08,
		Contrast = 0.04,
		BloomIntensity = 0.35,
	},
	{
		Hour = 18,
		Ambient = rgb(110, 85, 80),
		OutdoorAmbient = rgb(170, 120, 100),
		Brightness = 1.8,
		ExposureCompensation = 0,
		AtmosphereColor = rgb(245, 165, 120),
		AtmosphereDecay = rgb(210, 110, 90),
		AtmosphereDensity = 0.36,
		AtmosphereHaze = 2.4,
		Tint = rgb(255, 215, 190),
		Saturation = 0.12,
		Contrast = 0.08,
		BloomIntensity = 0.6,
	},
	{
		Hour = 19.6,
		Ambient = rgb(55, 50, 75),
		OutdoorAmbient = rgb(80, 70, 110),
		Brightness = 0.8,
		ExposureCompensation = 0.05,
		AtmosphereColor = rgb(95, 75, 120),
		AtmosphereDecay = rgb(60, 45, 90),
		AtmosphereDensity = 0.36,
		AtmosphereHaze = 1.8,
		Tint = rgb(215, 205, 255),
		Saturation = 0,
		Contrast = 0.1,
		BloomIntensity = 0.8,
	},
	{
		Hour = 21,
		Ambient = rgb(28, 32, 52),
		OutdoorAmbient = rgb(48, 56, 90),
		Brightness = 0.4,
		ExposureCompensation = 0.1,
		AtmosphereColor = rgb(40, 48, 78),
		AtmosphereDecay = rgb(24, 28, 50),
		AtmosphereDensity = 0.36,
		AtmosphereHaze = 1.2,
		Tint = rgb(190, 205, 255),
		Saturation = -0.1,
		Contrast = 0.1,
		BloomIntensity = 0.9,
	},
} :: { LightingPreset }

return EnvironmentConfig
