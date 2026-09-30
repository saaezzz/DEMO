--!strict

-- Contenido: misiones (capa IP, §4, §40). Compartido: el cliente lo usa para
-- el seguimiento en pantalla; el progreso y las recompensas los decide el
-- servidor. Pauta D-023: una cadena corta para el primer build.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestTypes = require(ReplicatedStorage.Shared.Types.QuestTypes)

type QuestDefinition = QuestTypes.QuestDefinition

local Definitions: { [string]: QuestDefinition } = {
	FirstHunt = {
		Id = "FirstHunt",
		Title = "Primera cacería",
		Type = "Hunt",
		Description = "Unos Hollows débiles merodean al norte. Acaba con ellos.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "WeakHollow",
				Count = 3,
				Description = "Derrota Hollows débiles",
				Location = Vector3.new(-25, 4, -90),
			},
		},
		Rewards = { Experience = 60 },
		Next = "GrowingThreat",
	},
	GrowingThreat = {
		Id = "GrowingThreat",
		Title = "Amenaza creciente",
		Type = "Hunt",
		Description = "Han aparecido Hollows más fuertes. Cuidado con sus embestidas.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "StandardHollow",
				Count = 2,
				Description = "Derrota Hollows",
				Location = Vector3.new(25, 4, -110),
			},
		},
		Rewards = { Experience = 150 },
		Next = "EliteHunt",
	},
	EliteHunt = {
		Id = "EliteHunt",
		Title = "El Hollow élite",
		Type = "BossHunt",
		Description = "Un Hollow élite domina la zona. Su golpe más lento rompe la guardia: esquívalo o haz parry.",
		Objectives = {
			{
				Kind = "Kill",
				Target = "EliteHollow",
				Count = 1,
				Description = "Derrota al Hollow élite",
				Location = Vector3.new(0, 4, -160),
			},
		},
		Rewards = { Experience = 300 },
	},
}

return {
	-- Misión con la que empieza un personaje nuevo.
	Starting = "FirstHunt",
	Definitions = Definitions,
}
