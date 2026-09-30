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
local Movesets = require(ReplicatedStorage.Shared.Content.Movesets)
local TrainingDummies = require(ServerScriptService.Server.Content.TrainingDummies)
local Enemies = require(ServerScriptService.Server.Content.Enemies)
local EnemySpawns = require(ServerScriptService.Server.Content.EnemySpawns)
local Quests = require(ReplicatedStorage.Shared.Content.Quests)
local Weapons = require(ReplicatedStorage.Shared.Content.Weapons)
local Items = require(ReplicatedStorage.Shared.Content.Items)
local Effects = require(ReplicatedStorage.Shared.Content.Effects)
local AbilityInfo = require(ReplicatedStorage.Shared.Content.AbilityInfo)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)
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

	["los muñecos de entrenamiento usan habilidades existentes y datos válidos"] = function()
		local ids = {}
		for _, ability in Abilities do
			ids[ability.Id] = true
		end
		for _, dummy in TrainingDummies do
			expect(dummy.MaxHealth > 0).toBe(true)
			if dummy.Behavior == "Attacker" and not ids[dummy.AttackAbility] then
				error(`muñeco {dummy.Id}: habilidad de ataque desconocida`)
			end
		end
	end,

	["los enemigos tienen Id único, ataques existentes y datos válidos"] = function()
		local abilityIds = {}
		for _, ability in Abilities do
			abilityIds[ability.Id] = true
		end
		local seen = {}
		for _, enemy in Enemies do
			if seen[enemy.Id] then
				error(`enemigo duplicado: {enemy.Id}`)
			end
			seen[enemy.Id] = true
			expect(enemy.MaxHealth > 0 and enemy.Experience >= 0).toBe(true)
			expect(#enemy.Attacks > 0).toBe(true)
			for _, attack in enemy.Attacks do
				if not abilityIds[attack.Ability] then
					error(`enemigo {enemy.Id}: habilidad desconocida "{attack.Ability}"`)
				end
			end
			local aggro = enemy.Aggro
			if not (aggro.DetectionRange <= aggro.LoseRange and aggro.LoseRange <= aggro.LeashRange) then
				error(`enemigo {enemy.Id}: alcances de aggro incoherentes`)
			end
			if string.match(enemy.Appearance.BodyColor, "^#%x%x%x%x%x%x$") == nil then
				error(`enemigo {enemy.Id}: color inválido`)
			end
		end
	end,

	["las apariciones usan enemigos existentes"] = function()
		local ids = {}
		for _, enemy in Enemies do
			ids[enemy.Id] = true
		end
		for _, spawn in EnemySpawns do
			if not ids[spawn.Enemy] then
				error(`aparición de enemigo desconocido "{spawn.Enemy}"`)
			end
			expect(spawn.Count > 0 and spawn.RespawnSeconds > 0).toBe(true)
		end
	end,

	["las misiones usan enemigos existentes y encadenan misiones existentes"] = function()
		local enemyIds = {}
		for _, enemy in Enemies do
			enemyIds[enemy.Id] = true
		end
		if Quests.Definitions[Quests.Starting] == nil then
			error(`la misión inicial "{Quests.Starting}" no existe`)
		end
		for key, quest in Quests.Definitions do
			expect(quest.Id).toBe(key)
			expect(#quest.Objectives > 0).toBe(true)
			for _, objective in quest.Objectives do
				if objective.Kind == "Kill" and not enemyIds[objective.Target] then
					error(`misión {key}: enemigo desconocido "{objective.Target}"`)
				end
				expect(objective.Count > 0).toBe(true)
			end
			if quest.Next ~= nil and Quests.Definitions[quest.Next] == nil then
				error(`misión {key}: siguiente misión desconocida "{quest.Next}"`)
			end
		end
	end,

	["la cadena de misiones no tiene ciclos"] = function()
		for key in Quests.Definitions do
			local visited = {}
			local current = key
			while current ~= nil do
				if visited[current] then
					error(`ciclo en la cadena de misiones desde {key}`)
				end
				visited[current] = true
				current = Quests.Definitions[current].Next
			end
		end
	end,

	["los kits de raza usan movesets, armas y objetos existentes"] = function()
		for key, race in Races.Definitions do
			if Movesets[race.Kit.Moveset] == nil then
				error(`raza {key}: moveset desconocido "{race.Kit.Moveset}"`)
			end
			if race.Kit.Weapon ~= nil and Weapons[race.Kit.Weapon] == nil then
				error(`raza {key}: arma desconocida "{race.Kit.Weapon}"`)
			end
			for _, starting in race.Kit.StartingItems do
				if Items[starting.Item] == nil then
					error(`raza {key}: objeto inicial desconocido "{starting.Item}"`)
				end
			end
		end
	end,

	["las armas usan un modelo del manifiesto"] = function()
		for key, weapon in Weapons do
			expect(weapon.Id).toBe(key)
			local asset = AssetRegistry.Get(weapon.Model)
			if asset == nil or asset.Category ~= "Model" then
				error(`arma {key}: "{weapon.Model}" no es un modelo del manifiesto`)
			end
		end
	end,

	["los modelos de enemigo están en el manifiesto"] = function()
		for _, enemy in Enemies do
			local model = enemy.Model
			if model ~= nil and (AssetRegistry.Get(model) == nil or AssetRegistry.Get(model).Category ~= "Model") then
				error(`enemigo {enemy.Id}: "{model}" no es un modelo del manifiesto`)
			end
		end
	end,

	["los efectos usan assets VFX del manifiesto y colores válidos"] = function()
		for key, effect in Effects do
			if
				effect.Asset ~= nil
				and (AssetRegistry.Get(effect.Asset) == nil or AssetRegistry.Get(effect.Asset).Category ~= "VFX")
			then
				error(`efecto {key}: "{effect.Asset}" no es un VFX del manifiesto`)
			end
			if string.match(effect.Color, "^#%x%x%x%x%x%x$") == nil then
				error(`efecto {key}: color inválido`)
			end
			expect(effect.Duration > 0).toBe(true)
		end
	end,

	["la presentación de habilidades apunta a habilidades y efectos existentes"] = function()
		local ids = {}
		for _, ability in Abilities do
			ids[ability.Id] = true
		end
		for key, info in AbilityInfo do
			if not ids[key] then
				error(`AbilityInfo: habilidad desconocida "{key}"`)
			end
			for _, effect in info.Effects or {} do
				if Effects[effect.Effect] == nil then
					error(`AbilityInfo {key}: efecto desconocido "{effect.Effect}"`)
				end
			end
		end
		-- Toda técnica de un moveset necesita nombre para la barra de acciones.
		for name, moveset in Movesets do
			for _, skill in moveset.Skills do
				if AbilityInfo[skill] == nil then
					error(`moveset {name}: la técnica "{skill}" no tiene AbilityInfo`)
				end
			end
		end
	end,

	["los objetos tienen rareza válida y los consumibles un efecto real"] = function()
		for key, item in Items do
			expect(item.Id).toBe(key)
			expect(item.MaxStack >= 1).toBe(true)
			if ItemConfig.Rarities[item.Rarity] == nil then
				error(`objeto {key}: rareza desconocida "{item.Rarity}"`)
			end
			local use = item.Use
			if item.Category == "Consumable" and (use == nil or (use.Heal == nil and use.Restore == nil)) then
				error(`objeto {key}: un consumible necesita Use con Heal o Restore`)
			end
			if use ~= nil and use.Restore ~= nil then
				expectResource(use.Restore.Resource, `objeto {key}`)
			end
		end
	end,

	["el botín de los enemigos usa objetos existentes"] = function()
		for _, enemy in Enemies do
			for _, drop in enemy.Drops or {} do
				if Items[drop.Item] == nil then
					error(`enemigo {enemy.Id}: botín desconocido "{drop.Item}"`)
				end
				expect(drop.Chance > 0 and drop.Chance <= 1).toBe(true)
				expect(drop.Min >= 1 and drop.Max >= drop.Min).toBe(true)
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
			local named = { moveset.HeavyAttack, moveset.Dodge, moveset.Dash }
			for _, skill in moveset.Skills do
				table.insert(named, skill)
			end
			expect(#moveset.Skills <= 4).toBe(true)
			for _, id in named do
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
