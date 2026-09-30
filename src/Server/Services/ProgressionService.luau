--!strict

-- Experiencia y nivel (§14, §44, D-028). Guarda en el perfil (que replica al
-- dueño) y, al subir de nivel, actualiza el personaje vivo: nivel y vida
-- máxima, con la vida al máximo como recompensa.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Progression = require(ReplicatedStorage.Shared.Modules.Progression)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local DataService = require(script.Parent.DataService)

local log = Logger.new("ProgressionService")

local ProgressionService = {
	Name = "ProgressionService",
	-- (jugador, nuevo nivel) al subir de nivel. Síncrona (D-013).
	LeveledUp = Signal.new() :: Signal.Signal<Player, number>,
}

function ProgressionService:AwardExperience(player: Player, amount: number): ()
	local data = DataService:GetData(player)
	if data == nil or amount <= 0 then
		return
	end

	local result = Progression.AddExperience(data.Level, data.Experience, amount)
	DataService:SetValue(player, "Experience", result.Experience)
	if result.LevelsGained <= 0 then
		return
	end

	DataService:SetValue(player, "Level", result.Level)
	log:Info("%s sube a nivel %d", player.Name, result.Level)

	local entity = CombatRegistry.GetAlive(player)
	if entity ~= nil then
		entity.Character:SetLevel(result.Level)
		entity.Character:SetMaxHealth(Progression.MaxHealthForLevel(result.Level), true)
	end
	ProgressionService.LeveledUp:Fire(player, result.Level)
end

return ProgressionService
