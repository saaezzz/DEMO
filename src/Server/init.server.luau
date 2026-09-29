--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatRemotes = require(ReplicatedStorage.Shared.Network.CombatRemotes)
local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)

local CombatService = require(script.Services.CombatService)
local CharacterService = require(script.Services.CharacterService)
local ExampleCombos = require(script.Combos.ExampleCombos)

type ServerCombatResponse = GameTypes.ServerCombatResponse

for _, combo in ipairs(ExampleCombos) do
	CombatService:RegisterCombo(combo)
end

CombatService:Init()
CharacterService:Init()

-- El payload llega sin tipar desde el cliente: CombatService lo valida antes de usarlo.
CombatRemotes.CombatIntent.OnServerInvoke = function(player: Player, payload: unknown): ServerCombatResponse
	return CombatService:ProcessIntent(player, payload)
end

print("[Server] Demo_RPG combat bootstrap listo.")
