--!strict

-- Contenido: razas (capa IP, §4, §21). Cada raza define su kit inicial
-- (D-034): moveset, arma y objetos. Para abrir una raza basta con completar
-- su kit y poner Playable = true.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type RaceDefinition = ContentTypes.RaceDefinition

local Definitions: { [string]: RaceDefinition } = {
	-- Estado previo a elegir raza; base de Fullbring (§36, futuro).
	Human = {
		Id = "Human",
		DisplayName = "Humano",
		Description = "Todavía no has despertado tu poder.",
		Playable = false,
		Resources = { "Reiatsu", "Stamina" },
		Kit = { Moveset = "Default", StartingItems = {} },
	},
	Shinigami = {
		Id = "Shinigami",
		DisplayName = "Shinigami",
		Description = "Guardianes de las almas. Combaten con su Zanpakuto, se mueven con Shunpo y lanzan Kido.",
		Playable = true,
		Resources = { "Reiatsu", "Stamina" },
		Kit = {
			Moveset = "Shinigami",
			Weapon = "Asauchi",
			StartingItems = {
				{ Item = "HealingBalm", Quantity = 3 },
				{ Item = "ReiatsuTonic", Quantity = 2 },
			},
		},
	},
	-- M5 (vertical slice 0.2).
	Hollow = {
		Id = "Hollow",
		DisplayName = "Hollow",
		Description = "Almas devoradas por el hambre. Garras, devorar y Cero.",
		Playable = false,
		Resources = { "Reiatsu", "Stamina" },
		Kit = { Moveset = "Default", StartingItems = {} },
	},
	-- M5. El Reishi ambiental (§32) se añadirá como recurso propio de la raza.
	Quincy = {
		Id = "Quincy",
		DisplayName = "Quincy",
		Description = "Arqueros que absorben el Reishi del entorno.",
		Playable = false,
		Resources = { "Reiatsu", "Stamina" },
		Kit = { Moveset = "Default", StartingItems = {} },
	},
}

return {
	-- Raza con la que se crea un personaje antes de elegir.
	Default = "Human",
	Definitions = Definitions,
}
