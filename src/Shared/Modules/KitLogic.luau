--!strict

-- Kit de una raza a lo largo del juego (D-034, D-039): qué técnicas tiene un
-- personaje según su moveset y los hitos que ha alcanzado, y qué hitos nuevos
-- cumple. Lógica pura y compartida: el servidor decide con ella y el cliente
-- la usa para mostrar la barra de acciones con el mismo cálculo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type Moveset = AbilityTypes.Moveset
type RaceDefinition = ContentTypes.RaceDefinition
type RaceMilestone = ContentTypes.RaceMilestone

local KitLogic = {}

-- Casillas de técnica (Ability1..Ability4).
KitLogic.MAX_SKILLS = 4

-- Técnicas del moveset y, detrás, las que desbloquean los hitos alcanzados.
function KitLogic.GetSkills(race: RaceDefinition?, moveset: Moveset, reached: { string }): { string }
	local skills = table.clone(moveset.Skills)
	if race == nil then
		return skills
	end
	for _, milestone in race.Milestones do
		if table.find(reached, milestone.Id) ~= nil then
			for _, skill in milestone.UnlockSkills do
				if #skills < KitLogic.MAX_SKILLS and table.find(skills, skill) == nil then
					table.insert(skills, skill)
				end
			end
		end
	end
	return skills
end

function KitLogic.MeetsMilestone(milestone: RaceMilestone, level: number, stats: { [string]: number }): boolean
	if level < milestone.RequiredLevel then
		return false
	end
	for stat, required in milestone.RequiredStats do
		if (stats[stat] or 0) < required then
			return false
		end
	end
	return true
end

-- Hitos que se cumplen ahora y aún no estaban alcanzados, en orden.
function KitLogic.NewMilestones(
	race: RaceDefinition,
	level: number,
	stats: { [string]: number },
	reached: { string }
): { RaceMilestone }
	local result: { RaceMilestone } = {}
	for _, milestone in race.Milestones do
		if table.find(reached, milestone.Id) == nil and KitLogic.MeetsMilestone(milestone, level, stats) then
			table.insert(result, milestone)
		end
	end
	return result
end

-- Primer hito aún no alcanzado (el siguiente objetivo del jugador), o nil.
function KitLogic.NextMilestone(race: RaceDefinition, reached: { string }): RaceMilestone?
	for _, milestone in race.Milestones do
		if table.find(reached, milestone.Id) == nil then
			return milestone
		end
	end
	return nil
end

return KitLogic
