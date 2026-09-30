--!strict

-- Estadísticas e hitos de raza (D-039). Cuenta en el perfil los enemigos
-- derrotados con golpes que llevan KillStat (los muñecos de entrenamiento no
-- cuentan, para que no se pueda progresar sin riesgo) y, cuando el jugador cumple los
-- requisitos de un hito de su raza (nivel + estadísticas), lo alcanza para
-- siempre: sus técnicas aparecen en la barra (KitLogic). El perfil replica al
-- dueño, que muestra el aviso y la barra nueva.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local KitLogic = require(ReplicatedStorage.Shared.Modules.KitLogic)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local DamageService = require(script.Parent.Parent.Combat.DamageService)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local ProgressionService = require(script.Parent.ProgressionService)

type AbilityHit = AbilityTypes.AbilityHit
type CombatEntity = CombatRegistry.CombatEntity

local log = Logger.new("MilestoneService")

-- Alcanza los hitos que el jugador ya cumple y aún no tenía.
local function evaluate(player: Player): ()
	local data = DataService:GetData(player)
	local race = if data ~= nil then Races.Definitions[data.Race] else nil
	if data == nil or race == nil then
		return
	end
	local newMilestones = KitLogic.NewMilestones(race, data.Level, data.Stats, data.Milestones)
	if #newMilestones == 0 then
		return
	end
	local reached = table.clone(data.Milestones)
	for _, milestone in newMilestones do
		table.insert(reached, milestone.Id)
		log:Info("%s alcanza el hito %s", player.Name, milestone.Id)
	end
	DataService:SetValue(player, "Milestones", reached)
end

local function addStat(player: Player, stat: string, amount: number): ()
	local data = DataService:GetData(player)
	if data == nil then
		return
	end
	local stats = table.clone(data.Stats)
	stats[stat] = (stats[stat] or 0) + amount
	DataService:SetValue(player, "Stats", stats)
	evaluate(player)
end

local function onKilled(attacker: CombatEntity, defender: CombatEntity, hit: AbilityHit): ()
	local player = attacker.Player
	local stat = hit.KillStat
	if player ~= nil and stat ~= nil and EnemyService:IsEnemy(defender.Model) then
		addStat(player, stat, 1)
	end
end

local MilestoneService = {
	Name = "MilestoneService",
}

function MilestoneService:Start(): ()
	DamageService.Killed:Connect(onKilled)
	ProgressionService.LeveledUp:Connect(evaluate)
	-- Al cargar: un hito añadido al contenido después también llega a quien ya lo cumplía.
	DataService.ProfileLoaded:Connect(evaluate)
	for _, player in Players:GetPlayers() do
		if DataService:IsLoaded(player) then
			evaluate(player)
		end
	end
end

return MilestoneService
