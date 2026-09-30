-- Integridad referencial de la capa de contenido: todo ID referenciado existe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Races = require(ReplicatedStorage.Shared.Content.Races)
local Resources = require(ReplicatedStorage.Shared.Content.Resources)
local Animations = require(ReplicatedStorage.Shared.Content.Animations)
local Assets = require(ReplicatedStorage.Shared.Content.Assets)
local AssetRegistry = require(ReplicatedStorage.Shared.Modules.AssetRegistry)
local AnimationRegistry = require(ReplicatedStorage.Shared.Modules.AnimationRegistry)
local Abilities = require(ServerScriptService.Server.Content.Abilities)
local Movesets = require(ServerScriptService.Server.Content.Movesets)
local Character = require(ReplicatedStorage.Shared.Modules.Character)
local StateMachine = require(ReplicatedStorage.Shared.Modules.StateMachine)
local StateAnimations = require(ReplicatedStorage.Shared.Content.StateAnimations)
local LocomotionAnimations = require(ReplicatedStorage.Shared.Content.LocomotionAnimations)
local PlaceholderAnimations =
	require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Animation.PlaceholderAnimations)

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

	["las habilidades tienen Id único y datos coherentes"] = function()
		local seen = {}
		for _, ability in Abilities do
			if seen[ability.Id] then
				error(`habilidad duplicada: {ability.Id}`)
			end
			seen[ability.Id] = true
			expect(ability.Duration > 0).toBe(true)
			expect(ability.Cooldown >= 0).toBe(true)
			expect(#ability.Requirements.StartStates > 0).toBe(true)
			if ability.Cost ~= nil then
				expectResource(ability.Cost.Resource, `habilidad {ability.Id}`)
			end
			for _, hit in ability.Hits or {} do
				if hit.StartTime < 0 or hit.StartTime > ability.Duration then
					error(`habilidad {ability.Id}: golpe fuera de la duración`)
				end
			end
			local iframes = ability.IFrames
			if iframes ~= nil and (iframes.Start > iframes.End or iframes.End > ability.Duration) then
				error(`habilidad {ability.Id}: i-frames inválidos`)
			end
			local movement = ability.Movement
			if movement ~= nil and (movement.Distance <= 0 or movement.Duration <= 0) then
				error(`habilidad {ability.Id}: movimiento inválido`)
			end
		end
	end,

	["cada habilidad puede empezar: su estado es alcanzable desde sus StartStates"] = function()
		for _, ability in Abilities do
			for _, startState in ability.Requirements.StartStates do
				local machine = StateMachine.new(startState, Character.TRANSITIONS)
				if not machine:CanTransition(ability.State) then
					error(`habilidad {ability.Id}: no se puede pasar de {startState} a {ability.State}`)
				end
			end
		end
	end,

	["las animaciones de las habilidades existen y tienen los markers de sus golpes"] = function()
		for _, ability in Abilities do
			local key = ability.Animation
			if key ~= nil then
				local animation = Animations[key]
				if animation == nil then
					error(`habilidad {ability.Id}: animación desconocida "{key}"`)
				end
				for _, hit in ability.Hits or {} do
					if not table.find(animation.Markers, hit.MarkerName) then
						error(`habilidad {ability.Id}: marker "{hit.MarkerName}" no está en {key}`)
					end
				end
			end
		end
	end,

	["los movesets usan habilidades existentes"] = function()
		local ids = {}
		for _, ability in Abilities do
			ids[ability.Id] = true
		end
		for name, moveset in Movesets do
			expect(#moveset.LightAttack > 0).toBe(true)
			for _, id in moveset.LightAttack do
				expect(ids[id]).toBe(true)
			end
			for _, id in { moveset.HeavyAttack, moveset.Dodge, moveset.Dash } do
				if not ids[id] then
					error(`moveset {name}: habilidad desconocida "{id}"`)
				end
			end
		end
	end,

	["cada asset cumple la convención de nombres y tiene datos válidos"] = function()
		local validStatus = { "TODO", "BLOCKED", "IN_PROGRESS", "REVIEW", "APPROVED", "INTEGRATED" }
		for _, entry in Assets do
			if not AssetRegistry.IsValidName(entry.Name, entry.Category) then
				error(`nombre de asset inválido: {entry.Name} ({entry.Category})`)
			end
			expect(table.find(validStatus, entry.Status) ~= nil).toBe(true)
			expect(entry.Version >= 0 and entry.Version % 1 == 0).toBe(true)
			expect(#entry.Owner > 0).toBe(true)
			if entry.AssetId ~= nil then
				expect(entry.AssetId > 0 and entry.AssetId % 1 == 0).toBe(true)
			end
		end
	end,

	["un asset aprobado o integrado ya tiene AssetId"] = function()
		for _, entry in Assets do
			if (entry.Status == "APPROVED" or entry.Status == "INTEGRATED") and entry.AssetId == nil then
				error(`{entry.Name} está {entry.Status} pero no tiene AssetId`)
			end
		end
	end,

	["las dependencias de los assets existen"] = function()
		for _, entry in Assets do
			for _, dependency in entry.Dependencies do
				if AssetRegistry.Get(dependency) == nil then
					error(`{entry.Name}: dependencia desconocida {dependency}`)
				end
			end
		end
	end,

	["cada animación usa un asset de categoría Animation y markers estándar"] = function()
		for key, animation in Animations do
			local asset = AssetRegistry.Get(animation.Asset)
			if asset == nil or asset.Category ~= "Animation" then
				error(`{key}: asset "{animation.Asset}" inexistente o no es Animation`)
			end
			for _, marker in animation.Markers do
				if not AnimationRegistry.IsValidMarker(marker) then
					error(`{key}: marker no estándar "{marker}"`)
				end
			end
		end
	end,

	["cada recurso tiene un color hexadecimal"] = function()
		for key, definition in Resources do
			if string.match(definition.Color, "^#%x%x%x%x%x%x$") == nil then
				error(`recurso {key}: color inválido "{definition.Color}"`)
			end
		end
	end,

	["las animaciones de estado y de locomoción existen"] = function()
		for state, key in StateAnimations do
			if Animations[key] == nil then
				error(`estado {state}: animación desconocida "{key}"`)
			end
		end
		for folder, values in LocomotionAnimations do
			for valueName, key in values do
				if AnimationRegistry.GetContentId(key) == nil then
					error(`locomoción {folder}.{valueName}: "{key}" no existe o no tiene AssetId`)
				end
			end
		end
	end,

	["los placeholders usan claves de animación existentes"] = function()
		for key in PlaceholderAnimations do
			if Animations[key] == nil then
				error(`placeholder de animación desconocida "{key}"`)
			end
		end
	end,

	["toda animación de acción sin asset subido tiene placeholder"] = function()
		local actionKeys = {}
		for _, key in StateAnimations do
			actionKeys[key] = true
		end
		for _, ability in Abilities do
			if ability.Animation ~= nil then
				actionKeys[ability.Animation] = true
			end
		end
		for key in actionKeys do
			if AnimationRegistry.GetContentId(key) == nil and PlaceholderAnimations[key] == nil then
				error(`{key} no tiene asset ni placeholder: no se vería nada`)
			end
		end
	end,
}
