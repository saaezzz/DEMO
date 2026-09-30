--!strict

-- Contenido: razas (capa IP, §4, §21). Cada raza define su kit inicial
-- (D-034): moveset, arma y objetos; y sus hitos de progresión (D-039), que
-- desbloquean técnicas. Para abrir una raza basta con completar su kit y
-- poner Playable = true.

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
		Milestones = {},
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
		-- El descubrimiento de la Zanpakuto (M6) usará estos hitos.
		Milestones = {},
	},
	-- §29: la evolución no es "mata X y evoluciona": pide nivel y devorar.
	Hollow = {
		Id = "Hollow",
		DisplayName = "Hollow",
		Description = "Almas devoradas por el hambre. Luchan con garras, devoran a sus presas para curarse y evolucionar, y disparan Cero.",
		Playable = true,
		Resources = { "Reiatsu", "Stamina" },
		Kit = {
			Moveset = "Hollow",
			Weapon = "HollowMask",
			StartingItems = {
				{ Item = "HealingBalm", Quantity = 2 },
				{ Item = "ReiatsuTonic", Quantity = 2 },
			},
		},
		Milestones = {
			{
				Id = "Hunger",
				DisplayName = "Hambre insaciable",
				Description = "Tu hambre crece con cada alma devorada.",
				RequiredLevel = 2,
				RequiredStats = { Devoured = 3 },
				UnlockSkills = { "Bala" },
			},
			-- Prototipo del primer paso de la evolución (§29).
			{
				Id = "Gillian",
				DisplayName = "Gillian",
				Description = "Has devorado suficientes almas para empezar a evolucionar.",
				RequiredLevel = 5,
				RequiredStats = { Devoured = 12 },
				UnlockSkills = { "Hierro" },
			},
		},
	},
	Quincy = {
		Id = "Quincy",
		DisplayName = "Quincy",
		Description = "Arqueros que absorben el Reishi del entorno. Disparan Heilig Pfeil a distancia y endurecen su cuerpo con Blut.",
		Playable = true,
		Resources = { "Reishi", "Stamina" },
		Kit = {
			Moveset = "Quincy",
			Weapon = "SpiritBow",
			StartingItems = {
				{ Item = "HealingBalm", Quantity = 3 },
				{ Item = "ReishiVial", Quantity = 2 },
			},
		},
		Milestones = {
			{
				Id = "BlutArterie",
				DisplayName = "Blut Arterie",
				Description = "Tu Reishi fluye por tu sangre y refuerza tus ataques.",
				RequiredLevel = 3,
				RequiredStats = { ArrowKills = 15 },
				UnlockSkills = { "BlutArterie" },
			},
		},
	},
}

return {
	-- Raza con la que se crea un personaje antes de elegir.
	Default = "Human",
	Definitions = Definitions,
}
