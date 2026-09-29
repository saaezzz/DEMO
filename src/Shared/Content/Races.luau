--!strict

-- Contenido: razas (capa IP, §4). Razas iniciales jugables según §3.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type RaceDefinition = ContentTypes.RaceDefinition

local Definitions: { [string]: RaceDefinition } = {
	-- Estado previo a elegir raza; base de Fullbring (§36, futuro).
	Human = {
		Id = "Human",
		DisplayName = "Humano",
		Playable = false,
		Resources = { "Reiatsu" },
	},
	Shinigami = {
		Id = "Shinigami",
		DisplayName = "Shinigami",
		Playable = true,
		Resources = { "Reiatsu" },
	},
	Hollow = {
		Id = "Hollow",
		DisplayName = "Hollow",
		Playable = true,
		Resources = { "Reiatsu" },
	},
	-- El Reishi ambiental (§32) se añadirá como recurso propio con la raza.
	Quincy = {
		Id = "Quincy",
		DisplayName = "Quincy",
		Playable = true,
		Resources = { "Reiatsu" },
	},
}

return {
	-- Raza con la que se crea un personaje antes de elegir.
	Default = "Human",
	Definitions = Definitions,
}
