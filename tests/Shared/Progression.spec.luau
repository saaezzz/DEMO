local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Modules.Progression)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)
local CharacterConfig = require(ReplicatedStorage.Shared.Config.CharacterConfig)

return {
	["la EXP por nivel crece y es 0 en el máximo"] = function()
		expect(Progression.XpToNext(1)).toBe(60)
		expect(Progression.XpToNext(5)).toBe(670)
		expect(Progression.XpToNext(10) > Progression.XpToNext(9)).toBe(true)
		expect(Progression.XpToNext(ProgressionConfig.MaxLevel)).toBe(0)
	end,

	["sumar EXP sin llegar al siguiente nivel no sube"] = function()
		local result = Progression.AddExperience(1, 10, 20)
		expect(result).toEqual({ Level = 1, Experience = 30, LevelsGained = 0 })
	end,

	["el sobrante pasa al nivel siguiente"] = function()
		local result = Progression.AddExperience(1, 50, 20)
		expect(result).toEqual({ Level = 2, Experience = 10, LevelsGained = 1 })
	end,

	["puede subir varios niveles de una vez"] = function()
		local total = Progression.XpToNext(1) + Progression.XpToNext(2) + 5
		local result = Progression.AddExperience(1, 0, total)
		expect(result.Level).toBe(3)
		expect(result.Experience).toBe(5)
		expect(result.LevelsGained).toBe(2)
	end,

	["no pasa del nivel máximo y descarta la EXP"] = function()
		local maxLevel = ProgressionConfig.MaxLevel
		local result = Progression.AddExperience(maxLevel - 1, 0, 10 ^ 9)
		expect(result.Level).toBe(maxLevel)
		expect(result.Experience).toBe(0)
		expect(Progression.AddExperience(maxLevel, 0, 500).LevelsGained).toBe(0)
	end,

	["la EXP negativa no resta"] = function()
		expect(Progression.AddExperience(3, 20, -50).Experience).toBe(20)
	end,

	["la vida máxima crece con el nivel desde la base"] = function()
		expect(Progression.MaxHealthForLevel(1)).toBe(CharacterConfig.BaseMaxHealth)
		expect(Progression.MaxHealthForLevel(11)).toBe(
			CharacterConfig.BaseMaxHealth + 10 * ProgressionConfig.HealthPerLevel
		)
	end,
}
