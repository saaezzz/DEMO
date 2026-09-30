--!strict

-- Contenido: cómo se presenta cada habilidad al jugador (capa IP, §4, D-035):
-- nombre, descripción y efectos visuales. La mecánica está en el servidor
-- (Server/Content/Abilities); esto solo es lo que se ve.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type AbilityInfo = ContentTypes.AbilityInfo

local AbilityInfo: { [string]: AbilityInfo } = {
	HeavySlash = { DisplayName = "Pesado", Description = "Golpe lento que rompe la guardia." },
	Dodge = { DisplayName = "Esquiva", Description = "Paso con invulnerabilidad." },
	Step = { DisplayName = "Paso", Description = "Paso rápido." },
	Shunpo = {
		DisplayName = "Shunpo",
		Description = "Paso instantáneo, también en el aire.",
		Effects = { { Effect = "Movement.Shunpo", Delay = 0 } },
	},
	Byakurai = {
		DisplayName = "Byakurai",
		Description = "Hado #4: rayo de largo alcance.",
		Effects = { { Effect = "Kido.Byakurai", Delay = 0.35 } },
	},
	Sai = {
		DisplayName = "Sai",
		Description = "Bakudo #1: inmoviliza a un enemigo cercano. Ignora la guardia.",
		Effects = { { Effect = "Kido.Sai", Delay = 0.3 } },
	},

	-- Hollow
	ClawRend = { DisplayName = "Desgarro", Description = "Zarpazo con las dos garras que rompe la guardia." },
	Devour = {
		DisplayName = "Devorar",
		Description = "Muerde, cura lo que hace y remata a un enemigo debilitado. Ignora la guardia.",
		Effects = { { Effect = "Hollow.Devour", Delay = 0.45 } },
	},
	Cero = {
		DisplayName = "Cero",
		Description = "Carga y dispara un rayo devastador.",
		Effects = {
			{ Effect = "Hollow.CeroCharge", Delay = 0 },
			{ Effect = "Hollow.Cero", Delay = 0.8 },
		},
	},
	Bala = {
		DisplayName = "Bala",
		Description = "Disparo rápido de Reiatsu.",
		Effects = { { Effect = "Hollow.Bala", Delay = 0.35 } },
	},
	Hierro = {
		DisplayName = "Hierro",
		Description = "Endurece la piel: recibes un 30 % menos de daño durante 10 s.",
		Effects = { { Effect = "Hollow.Hierro", Delay = 0 } },
	},
	Sonido = {
		DisplayName = "Sonido",
		Description = "Desplazamiento rápido, también en el aire.",
		Effects = { { Effect = "Movement.Sonido", Delay = 0 } },
	},

	-- Quincy
	Pfeil1 = {
		DisplayName = "Heilig Pfeil",
		Description = "Flecha de Reishi.",
		Effects = { { Effect = "Quincy.Pfeil", Delay = 0.25 } },
	},
	Pfeil2 = {
		DisplayName = "Heilig Pfeil",
		Description = "Flecha de Reishi.",
		Effects = { { Effect = "Quincy.Pfeil", Delay = 0.25 } },
	},
	Pfeil3 = {
		DisplayName = "Heilig Pfeil",
		Description = "Flecha de Reishi que empuja.",
		Effects = { { Effect = "Quincy.Pfeil", Delay = 0.25 } },
	},
	ChargedPfeil = {
		DisplayName = "Carga",
		Description = "Flecha cargada que atraviesa y rompe la guardia.",
		Effects = { { Effect = "Quincy.ChargedPfeil", Delay = 0.6 } },
	},
	LichtRegen = {
		DisplayName = "Licht Regen",
		Description = "Lluvia de flechas sobre una zona por delante.",
		Effects = { { Effect = "Quincy.LichtRegen", Delay = 0.7 } },
	},
	BlutVene = {
		DisplayName = "Blut Vene",
		Description = "Endurece la sangre: recibes un 40 % menos de daño durante 8 s.",
		Effects = { { Effect = "Quincy.BlutVene", Delay = 0 } },
	},
	BlutArterie = {
		DisplayName = "Blut Arterie",
		Description = "Refuerza la sangre: haces un 35 % más de daño durante 8 s.",
		Effects = { { Effect = "Quincy.BlutArterie", Delay = 0 } },
	},
	Hirenkyaku = {
		DisplayName = "Hirenkyaku",
		Description = "Paso sobre Reishi, el más largo. También en el aire.",
		Effects = { { Effect = "Movement.Hirenkyaku", Delay = 0 } },
	},
}

return AbilityInfo
