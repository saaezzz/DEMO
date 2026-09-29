-- Integridad referencial de la capa de contenido: todo ID referenciado existe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Races = require(ReplicatedStorage.Shared.Content.Races)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local ComboAnimations = require(ReplicatedStorage.Shared.Content.ComboAnimations)
local Combos = require(ServerScriptService.Server.Content.Combos)
local CombatActions = require(ServerScriptService.Server.Content.CombatActions)

local function expectResource(resourceId, context)
	if Resources[resourceId] == nil then
		error(`{context}: recurso desconocido "{resourceId}"`)
	end
end

return {
	["cada recurso tiene Id igual a su clave y valores válidos"] = function()
		for key, definition in Resources do
			expect(definition.Id).toBe(key)
			expect(definition.DefaultMax > 0).toBe(true)
			expect(definition.RegenPerSecond >= 0).toBe(true)
		end
	end,

	["cada raza tiene Id igual a su clave y recursos existentes"] = function()
		for key, race in Races.Definitions do
			expect(race.Id).toBe(key)
			for _, resourceId in race.Resources do
				expectResource(resourceId, `raza {key}`)
			end
		end
	end,

	["la raza por defecto existe"] = function()
		expect(Races.Definitions[Races.Default] ~= nil).toBe(true)
	end,

	["hay al menos una raza jugable"] = function()
		local playable = 0
		for _, race in Races.Definitions do
			if race.Playable then
				playable += 1
			end
		end
		expect(playable > 0).toBe(true)
	end,

	["los combos tienen Id único, golpes válidos y coste con recurso existente"] = function()
		local seen = {}
		for _, combo in Combos do
			expect(seen[combo.Id]).toBeNil()
			seen[combo.Id] = true
			expect(#combo.Hits > 0).toBe(true)
			for _, hit in combo.Hits do
				expect(hit.EndTime >= hit.StartTime).toBe(true)
			end
			if combo.Cost ~= nil then
				expectResource(combo.Cost.Resource, `combo {combo.Id}`)
			end
		end
	end,

	["las animaciones de combo apuntan a combos existentes"] = function()
		local comboIds = {}
		for _, combo in Combos do
			comboIds[combo.Id] = true
		end
		for comboId in ComboAnimations do
			expect(comboIds[comboId]).toBe(true)
		end
	end,

	["el coste del dash usa un recurso existente"] = function()
		local cost = CombatActions.Dash.Cost
		if cost ~= nil then
			expectResource(cost.Resource, "Dash")
		end
	end,
}
