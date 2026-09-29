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
	},
}

return Resources
