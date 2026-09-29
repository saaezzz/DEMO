--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRemotes = require(ReplicatedStorage.Shared.Network.CombatRemotes)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

local CombatService = require(script.Services.CombatService)
local CharacterService = require(script.Services.CharacterService)
local ExampleCombos = require(script.Combos.ExampleCombos)

type CombatIntent = GameTypes.CombatIntent
type ServerCombatResponse = GameTypes.ServerCombatResponse

for _, combo in ipairs(ExampleCombos) do
	CombatService:RegisterCombo(combo)
end

CombatService:Init()
CharacterService:Init()

CombatRemotes.CombatIntent.OnServerInvoke = function(player: Player, intent: CombatIntent): ServerCombatResponse
	return CombatService:ProcessIntent(player, intent)
end

print("[Server] Demo_RPG combat bootstrap listo.")
