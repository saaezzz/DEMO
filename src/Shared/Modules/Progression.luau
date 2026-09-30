--!strict

-- Cálculos de nivel y experiencia (§14, §44). Lógica pura a partir de
-- ProgressionConfig: ningún valor por nivel está escrito a mano en el juego.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterConfig = require(ReplicatedStorage.Shared.Config.CharacterConfig)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

export type ExperienceResult = {
	Level: number,
	-- EXP acumulada dentro del nivel actual.
	Experience: number,
	LevelsGained: number,
}

local Progression = {}

-- EXP necesaria para pasar de `level` al siguiente (0 en el nivel máximo).
function Progression.XpToNext(level: number): number
	if level >= ProgressionConfig.MaxLevel then
		return 0
	end
	return math.floor(ProgressionConfig.XpBase * level ^ ProgressionConfig.XpExponent)
end

-- Suma EXP y sube los niveles que correspondan. En el nivel máximo la EXP se descarta.
function Progression.AddExperience(level: number, experience: number, amount: number): ExperienceResult
	local newLevel = level
	local newExperience = experience + math.max(0, amount)
	while newLevel < ProgressionConfig.MaxLevel and newExperience >= Progression.XpToNext(newLevel) do
		newExperience -= Progression.XpToNext(newLevel)
		newLevel += 1
	end
	if newLevel >= ProgressionConfig.MaxLevel then
		newExperience = 0
	end
	return { Level = newLevel, Experience = newExperience, LevelsGained = newLevel - level }
end

function Progression.MaxHealthForLevel(level: number): number
	return CharacterConfig.BaseMaxHealth + ProgressionConfig.HealthPerLevel * (level - 1)
end

return Progression
