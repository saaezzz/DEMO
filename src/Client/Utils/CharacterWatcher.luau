--!strict

-- Llama a una función por cada personaje de jugador que aparece (los ya
-- presentes incluidos) y a la limpieza que devuelve cuando ese modelo se va.

local Players = game:GetService("Players")

export type Cleanup = () -> ()

local CharacterWatcher = {}

-- `onCharacter` puede ceder (p. ej. WaitForChild).
function CharacterWatcher.Observe(onCharacter: (player: Player, model: Model) -> Cleanup?): ()
	local cleanups: { [Model]: Cleanup } = {}

	local function release(model: Model): ()
		local cleanup: Cleanup? = cleanups[model]
		if cleanup ~= nil then
			cleanups[model] = nil
			cleanup()
		end
	end

	local function add(player: Player, model: Model): ()
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
			task.spawn(add, player, current)
		end
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
end

return CharacterWatcher
