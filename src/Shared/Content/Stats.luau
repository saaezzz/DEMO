--!strict

-- Contenido: estadísticas que se cuentan en el perfil (capa IP, §4, D-039).
-- Las suman los golpes con KillStat (Server/Content/Abilities) y las piden
-- los hitos de raza (Content/Races).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type StatDefinition = ContentTypes.StatDefinition

local Stats: { [string]: StatDefinition } = {
	-- Enemigos rematados con Devorar (progresión Hollow, §29).
	Devoured = { DisplayName = "Almas devoradas" },
	-- Enemigos derrotados con flechas de Heilig Pfeil (progresión Quincy, §31).
	ArrowKills = { DisplayName = "Enemigos abatidos con flechas" },
}

return Stats
