--!strict

-- Elección de raza (D-034). Un personaje nuevo empieza con la raza por
-- defecto y elige una sola vez entre las disponibles (Playable). Al elegir,
-- recibe el kit de la raza y reaparece con él.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Schema = require(ReplicatedStorage.Shared.Network.Schema)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local ServerNetwork = require(script.Parent.Parent.Network.ServerNetwork)
local CharacterService = require(script.Parent.CharacterService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

type RequestResponse = GameTypes.RequestResponse

local MAX_RACE_ID_LENGTH = 32

local log = Logger.new("RaceService")

local validateRequest = Schema.record({
	Race = Schema.string(MAX_RACE_ID_LENGTH),
})

local function respond(status: "Accepted" | "Rejected", message: string?): RequestResponse
	return { Status = status, Message = message }
end

local function chooseRace(player: Player, request: { Race: string }): RequestResponse
	local data = DataService:GetData(player)
	if data == nil then
		return respond("Rejected", "Datos no cargados")
	end
	if data.Race ~= Races.Default then
		return respond("Rejected", "Ya has elegido raza")
	end
	local race = Races.Definitions[request.Race]
	if race == nil or not race.Playable or race.Id == Races.Default then
		return respond("Rejected", "Raza no disponible")
	end

	DataService:SetValue(player, "Race", race.Id)
	for _, starting in race.Kit.StartingItems do
		InventoryService:AddItem(player, starting.Item, starting.Quantity)
	end
	log:Info("%s elige %s", player.Name, race.Id)
	CharacterService:Respawn(player)
	return respond("Accepted", nil)
end

local RaceService = {
	Name = "RaceService",
}

function RaceService:Start(): ()
	ServerNetwork:HandleFunction("ChooseRace", validateRequest, chooseRace)
end

return RaceService
