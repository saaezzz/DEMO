--!strict

-- Contenido: misiones (capa IP, §4, §40). Compartido: el cliente lo usa para
-- el seguimiento en pantalla; el progreso y las recompensas los decide el
-- servidor. Pauta D-023: una cadena corta para el primer build.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldMap = require(ReplicatedStorage.Shared.Modules.WorldMap)
local QuestTypes = require(ReplicatedStorage.Shared.Types.QuestTypes)

type QuestDefinition = QuestTypes.QuestDefinition

local Definitions: { [string]: QuestDefinition } = {
	FirstHunt = {
		Id = "FirstHunt",
		Title = "Primera cacería",
		Type = "Hunt",
		Description = "Unos Hollows débiles merodean por el parque Tsubakidai. Acaba con ellos.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "WeakHollow",
				Count = 3,
				Description = "Derrota Hollows débiles",
				Location = WorldMap.Anchor("TsubakidaiPark", Vector3.new(0, 4, 0)),
			},
		},
		Rewards = { Experience = 60 },
		Next = "GrowingThreat",
	},
	GrowingThreat = {
		Id = "GrowingThreat",
		Title = "Amenaza creciente",
		Type = "Hunt",
		Description = "Han aparecido Hollows más fuertes en las ruinas del Hospital Matsukura. Cuidado con sus embestidas.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "StandardHollow",
				Count = 2,
				Description = "Derrota Hollows",
				Location = WorldMap.Anchor("MatsukuraRuins", Vector3.new(0, 4, 0)),
			},
		},
		Rewards = { Experience = 150 },
		Next = "EliteHunt",
	},
	EliteHunt = {
		Id = "EliteHunt",
		Title = "El Hollow élite",
		Type = "BossHunt",
		Description = "Un Hollow élite se ha instalado en los restos del edificio de carreras. Su golpe más lento rompe la guardia: esquívalo o haz parry.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "EliteHollow",
				Count = 1,
				Description = "Derrota al Hollow élite",
				Location = WorldMap.Anchor("RacecourseRuins", Vector3.new(0, 4, 0)),
			},
		},
		Rewards = { Experience = 300 },
		Next = "GreatHollowHunt",
	},
	GreatHollowHunt = {
		Id = "GreatHollowHunt",
		Title = "El Gran Hollow",
		Type = "BossHunt",
		Description = "Algo enorme acecha en la orilla del río Karasu. Id en grupo si podéis: el círculo rojo avisa de su golpe en área.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "GreatHollow",
				Count = 1,
				Description = "Derrota al Gran Hollow",
				Location = WorldMap.Anchor("KarasuRiverside", Vector3.new(0, 6, 0)),
			},
		},
		Rewards = { Experience = 500 },
	},
}

return {
	-- Misión con la que empieza un personaje nuevo.
	Starting = "FirstHunt",
	Definitions = Definitions,
}
