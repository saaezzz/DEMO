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
}

return AbilityInfo
