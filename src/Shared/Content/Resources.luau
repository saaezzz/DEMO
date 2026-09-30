--!strict

-- Contenido: recursos de combate/espirituales (capa IP, §4).
-- Valores provisionales hasta BALANCE.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type ResourceDefinition = ContentTypes.ResourceDefinition

local Resources: { [string]: ResourceDefinition } = {
	-- GAMEPLAY ADAPTATION: presión espiritual como recurso para técnicas.
	Reiatsu = {
		Id = "Reiatsu",
		DisplayName = "Reiatsu",
		DefaultMax = 100,
		RegenPerSecond = 5,
		Color = "#4FA3FF",
	},
	-- Recurso físico común a todas las razas: esquiva, ataque pesado y sprint.
	Stamina = {
		Id = "Stamina",
		DisplayName = "Stamina",
		DefaultMax = 100,
		RegenPerSecond = 25,
		RegenDelaySeconds = 1,
		Color = "#57D163",
	},
}

return Resources
