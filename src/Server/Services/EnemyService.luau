--!strict

-- Enemigos (§42, D-029): aparición por zonas, IA y recompensas. Todos los
-- enemigos usan este servicio y la misma IA (EnemyBrain); cada uno es solo
-- datos en Content/Enemies. Un único bucle de baja frecuencia para todos (§58).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemyTypes = require(ReplicatedStorage.Shared.Types.EnemyTypes)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local Enemies = require(script.Parent.Parent.Content.Enemies)
local EnemySpawns = require(script.Parent.Parent.Content.EnemySpawns)
local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local DamageService = require(script.Parent.Parent.Combat.DamageService)
local EnemyBrain = require(script.Parent.Parent.Npc.EnemyBrain)
local NpcActions = require(script.Parent.Parent.Npc.NpcActions)
local NpcFactory = require(script.Parent.Parent.Npc.NpcFactory)
local CombatService = require(script.Parent.CombatService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)

type EnemyDefinition = EnemyTypes.EnemyDefinition
type EnemySpawn = EnemyTypes.EnemySpawn
type CombatEntity = CombatRegistry.CombatEntity
type Npc = NpcFactory.Npc

local FOLDER_NAME = "Enemies"
local THINK_SECONDS = 0.2
-- Tiempo que el cuerpo queda en el suelo antes de desaparecer.
local CORPSE_SECONDS = 2
-- Velocidad al volver a casa, respecto a la normal.
local RETURN_SPEED_MULTIPLIER = 1.4

type Enemy = {
	Definition: EnemyDefinition,
	Spawn: EnemySpawn,
	Home: Vector3,
	Npc: Npc,
	Target: CombatEntity?,
	Returning: boolean,
	Winding: boolean,
	NextAttackAt: number,
	-- Jugadores que le han hecho daño: reciben EXP y cuentan para misiones.
	Contributors: { [Player]: boolean },
}

local log = Logger.new("EnemyService")
local definitions: { [string]: EnemyDefinition } = {}
local enemies: { [Model]: Enemy } = {}
local folder: Folder
local random = Random.new()

local spawnEnemy: (spawn: EnemySpawn) -> ()

local function randomPointAround(center: Vector3, radius: number): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local distance = random:NextNumber(0, radius)
	return center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function isValidTarget(enemy: Enemy, target: CombatEntity): boolean
	return CombatRegistry.Get(target.Model) == target
		and target.Character:IsAlive()
		and flatDistance(target.RootPart.Position, enemy.Npc.RootPart.Position) <= enemy.Definition.Aggro.LoseRange
end

local function findTarget(enemy: Enemy): CombatEntity?
	local origin = enemy.Npc.RootPart.Position
	local best: CombatEntity? = nil
	local bestDistance = enemy.Definition.Aggro.DetectionRange
	for _, entity in CombatRegistry.GetAll() do
		if entity.Player ~= nil and entity.Character:IsAlive() then
			local distance = flatDistance(entity.RootPart.Position, origin)
			if distance <= bestDistance then
				best = entity
				bestDistance = distance
			end
		end
	end
	return best
end

local function stop(enemy: Enemy): ()
	enemy.Npc.Humanoid:MoveTo(enemy.Npc.RootPart.Position)
end

local function finishReturn(enemy: Enemy): ()
	enemy.Returning = false
	table.clear(enemy.Contributors)
	local character = enemy.Npc.Character
	character:Heal(character:GetMaxHealth())
	character:ResetPosture()
	stop(enemy)
end

local function startAttack(enemy: Enemy, target: CombatEntity, distance: number, now: number): ()
	local model = enemy.Npc.Model
	local attack = EnemyBrain.PickAttack(enemy.Definition.Attacks, distance, random:NextNumber(), function(abilityId)
		return CombatService:IsAbilityReady(model, abilityId)
	end)
	if attack == nil then
		return
	end
	enemy.Winding = true
	enemy.NextAttackAt = now + enemy.Definition.AttackIntervalSeconds
	stop(enemy)
	NpcActions.TelegraphAttack(enemy.Npc, attack.Ability, attack.TelegraphSeconds, target.RootPart, function()
		enemy.Winding = false
	end)
end

local function think(enemy: Enemy, now: number): ()
	local npc = enemy.Npc
	local character = npc.Character
	if not character:IsAlive() then
		return
	end

	-- Solo se desplaza mientras está libre (no atacando ni aturdido).
	local state = character:GetState()
	local speed = if enemy.Returning
		then enemy.Definition.WalkSpeed * RETURN_SPEED_MULTIPLIER
		else enemy.Definition.WalkSpeed
	npc.Humanoid.WalkSpeed = if state == "Idle" and not enemy.Winding then speed else 0
	if enemy.Winding then
		return
	end

	local target = enemy.Target
	if target ~= nil and not isValidTarget(enemy, target) then
		target = nil
	end
	if target == nil and not enemy.Returning then
		target = findTarget(enemy)
	end
	enemy.Target = target

	local position = npc.RootPart.Position
	local targetDistance = if target ~= nil then flatDistance(target.RootPart.Position, position) else nil
	local model = npc.Model
	local readyRange, minRange = EnemyBrain.Ranges(enemy.Definition.Attacks, function(abilityId)
		return CombatService:IsAbilityReady(model, abilityId)
	end)

	local decision = EnemyBrain.Decide({
		State = state,
		Returning = enemy.Returning,
		HomeDistance = flatDistance(position, enemy.Home),
		TargetDistance = targetDistance,
		AttackReady = now >= enemy.NextAttackAt,
		ReadyRange = readyRange,
		MinRange = minRange,
		Aggro = enemy.Definition.Aggro,
	})

	if decision == "Return" then
		enemy.Target = nil
		enemy.Returning = true
		npc.Humanoid:MoveTo(enemy.Home)
	elseif decision == "Idle" then
		if enemy.Returning then
			finishReturn(enemy)
		end
	elseif decision == "Chase" and target ~= nil then
		npc.Humanoid:MoveTo(target.RootPart.Position)
	elseif decision == "Hold" and target ~= nil then
		stop(enemy)
		NpcActions.FaceTowards(npc, target.RootPart.Position)
	elseif decision == "Attack" and target ~= nil and targetDistance ~= nil then
		startAttack(enemy, target, targetDistance, now)
	end
end

local function onEnemyDied(enemy: Enemy): ()
	local definition = enemy.Definition
	for player in enemy.Contributors do
		if player.Parent == Players then
			ProgressionService:AwardExperience(player, definition.Experience)
			QuestService:RecordKill(player, definition.Id)
		end
	end

	task.delay(CORPSE_SECONDS, function()
		enemies[enemy.Npc.Model] = nil
		NpcFactory.Despawn(enemy.Npc)
	end)
	task.delay(enemy.Spawn.RespawnSeconds, function()
		spawnEnemy(enemy.Spawn)
	end)
end

-- Quien golpea a un enemigo pasa a contar para la recompensa y, si el enemigo
-- no tenía objetivo, se convierte en su objetivo (aunque esté lejos).
local function onHitLanded(attacker: CombatEntity, defender: CombatEntity): ()
	local enemy = enemies[defender.Model]
	local player = attacker.Player
	if enemy == nil or player == nil then
		return
	end
	enemy.Contributors[player] = true
	if enemy.Target == nil and not enemy.Returning then
		enemy.Target = attacker
	end
end

spawnEnemy = function(spawn: EnemySpawn): ()
	local definition = definitions[spawn.Enemy]
	local home = randomPointAround(spawn.Position, spawn.Radius)
	local facing = home + Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1))
	local npc = NpcFactory.Spawn({
		Name = definition.Id,
		DisplayName = definition.DisplayName,
		Level = definition.Level,
		MaxHealth = definition.MaxHealth,
		MaxPosture = definition.MaxPosture,
		CFrame = CFrame.lookAt(home, Vector3.new(facing.X, home.Y, facing.Z)),
		WalkSpeed = definition.WalkSpeed,
		Parent = folder,
		BodyColor = Color3.fromHex(definition.Appearance.BodyColor),
		Scale = definition.Appearance.Scale,
		Mask = definition.Appearance.Mask,
	})

	local enemy: Enemy = {
		Definition = definition,
		Spawn = spawn,
		Home = home,
		Npc = npc,
		Target = nil,
		Returning = false,
		Winding = false,
		NextAttackAt = 0,
		Contributors = {},
	}
	enemies[npc.Model] = enemy
	-- En su propio hilo: Died se emite dentro de un golpe (Signal síncrona, D-013).
	npc.Character.Died:Connect(function()
		task.spawn(function()
			onEnemyDied(enemy)
		end)
	end)
end

local EnemyService = {
	Name = "EnemyService",
}

function EnemyService:Init(): ()
	for _, definition in Enemies do
		assert(definitions[definition.Id] == nil, `[EnemyService] enemigo duplicado: {definition.Id}`)
		definitions[definition.Id] = definition
	end
	for _, spawn in EnemySpawns do
		assert(definitions[spawn.Enemy] ~= nil, `[EnemyService] aparición de enemigo desconocido: {spawn.Enemy}`)
	end
end

function EnemyService:Start(): ()
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace

	DamageService.HitLanded:Connect(onHitLanded)

	for _, spawn in EnemySpawns do
		for _ = 1, spawn.Count do
			local ok, err = pcall(function()
				spawnEnemy(spawn)
			end)
			if not ok then
				log:Warn("No se pudo crear %s: %s", spawn.Enemy, tostring(err))
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(THINK_SECONDS)
			local now = os.clock()
			for _, enemy in enemies do
				think(enemy, now)
			end
		end
	end)
end

return EnemyService
