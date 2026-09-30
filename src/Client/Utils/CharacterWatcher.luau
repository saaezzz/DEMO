--!strict

-- Llama a una función por cada personaje que combate y aparece (jugadores y
-- NPCs con la etiqueta NPC_TAG, los ya presentes incluidos) y a la limpieza
-- que devuelve cuando ese modelo se va.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

export type Cleanup = () -> ()

-- `player` es nil para los NPCs.
export type CharacterCallback = (player: Player?, model: Model) -> Cleanup?

local CharacterWatcher = {}

-- `onCharacter` puede ceder (p. ej. WaitForChild).
function CharacterWatcher.Observe(onCharacter: CharacterCallback): ()
	local cleanups: { [Model]: Cleanup } = {}

	local function release(model: Model): ()
		local cleanup: Cleanup? = cleanups[model]
		if cleanup ~= nil then
			cleanups[model] = nil
			cleanup()
		end
	end

	local function add(player: Player?, model: Model): ()
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(game) then
				release(model)
			end
		end)

		local cleanup = onCharacter(player, model)
		if cleanup == nil then
			return
		end
		-- El modelo pudo desaparecer mientras onCharacter esperaba.
		if model:IsDescendantOf(game) then
			cleanups[model] = cleanup
		else
			cleanup()
		end
	end

	local function watchPlayer(player: Player): ()
		player.CharacterAdded:Connect(function(model)
			add(player, model)
		end)
		player.CharacterRemoving:Connect(release)
		local current = player.Character
		if current ~= nil then
			task.spawn(function()
				add(player, current)
			end)
		end
	end

	local function watchNpc(instance: Instance): ()
		if instance:IsA("Model") then
			task.spawn(function()
				add(nil, instance)
			end)
		end
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	CollectionService:GetInstanceAddedSignal(ReplicatedAttributes.NPC_TAG):Connect(watchNpc)
	CollectionService:GetInstanceRemovedSignal(ReplicatedAttributes.NPC_TAG):Connect(function(instance)
		if instance:IsA("Model") then
			release(instance)
		end
	end)
	for _, instance in CollectionService:GetTagged(ReplicatedAttributes.NPC_TAG) do
		watchNpc(instance)
	end
end

return CharacterWatcher
