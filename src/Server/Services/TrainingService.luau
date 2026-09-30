--!strict

-- Muñecos de entrenamiento (M2, D-027): NPCs que usan exactamente el mismo
-- sistema de combate que los jugadores. Reaparecen al morir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local TrainingDummies = require(script.Parent.Parent.Content.TrainingDummies)
local NpcActions = require(script.Parent.Parent.Npc.NpcActions)
local NpcFactory = require(script.Parent.Parent.Npc.NpcFactory)
local CombatService = require(script.Parent.CombatService)

type DummyDefinition = TrainingDummies.DummyDefinition
type Npc = NpcFactory.Npc

local FOLDER_NAME = "TrainingDummies"
local RESPAWN_SECONDS = 3
local THINK_SECONDS = 0.25

type Dummy = {
	Definition: DummyDefinition,
	Npc: Npc,
	NextAttackAt: number,
	-- Hay un ataque avisado en curso.
	Winding: boolean,
}

local log = Logger.new("TrainingService")
local folder: Folder
local dummies: { [Dummy]: boolean } = {}

local spawnDummy: (definition: DummyDefinition) -> ()

local function findNearestPlayer(origin: Vector3, range: number): BasePart?
	local nearest: BasePart? = nil
	local nearestDistance = range
	for _, player in Players:GetPlayers() do
		local model = player.Character
		local humanoid = if model ~= nil then model:FindFirstChildOfClass("Humanoid") else nil
		local root = if model ~= nil then model:FindFirstChild("HumanoidRootPart") else nil
		if humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart") then
			local distance = (root.Position - origin).Magnitude
			if distance <= nearestDistance then
				nearest = root
				nearestDistance = distance
			end
		end
	end
	return nearest
end

local function tryAttack(dummy: Dummy, now: number): ()
	local definition = dummy.Definition
	local ability = definition.AttackAbility
	if ability == nil or dummy.Winding or now < dummy.NextAttackAt then
		return
	end
	local target = findNearestPlayer(dummy.Npc.RootPart.Position, definition.AttackRange or 8)
	if target == nil then
		return
	end

	dummy.Winding = true
	dummy.NextAttackAt = now + (definition.AttackIntervalSeconds or 2.5)
	NpcActions.TelegraphAttack(dummy.Npc, ability, definition.TelegraphSeconds or 0.5, target, function()
		dummy.Winding = false
	end)
end

local function think(dummy: Dummy, now: number): ()
	local character = dummy.Npc.Character
	if not character:IsAlive() or character:GetState() ~= "Idle" then
		return
	end
	local behavior = dummy.Definition.Behavior
	if behavior == "Attacker" then
		tryAttack(dummy, now)
	elseif behavior == "Guard" then
		CombatService:SetBlocking(dummy.Npc.Model, true)
	end
end

spawnDummy = function(definition: DummyDefinition): ()
	-- Mira hacia el origen, donde aparecen los jugadores.
	local lookTarget = Vector3.new(0, definition.Position.Y, 0)
	local npc = NpcFactory.Spawn({
		Name = `Dummy_{definition.Id}`,
		DisplayName = definition.DisplayName,
		Level = 1,
		MaxHealth = definition.MaxHealth,
		MaxPosture = definition.MaxPosture,
		CFrame = CFrame.lookAt(definition.Position, lookTarget),
		WalkSpeed = 0,
		Parent = folder,
	})
	npc.Humanoid.JumpPower = 0

	local dummy: Dummy = {
		Definition = definition,
		Npc = npc,
		NextAttackAt = 0,
		Winding = false,
	}
	dummies[dummy] = true

	npc.Character.Died:Connect(function()
		task.delay(RESPAWN_SECONDS, function()
			dummies[dummy] = nil
			NpcFactory.Despawn(npc)
			spawnDummy(definition)
		end)
	end)
end

local TrainingService = {
	Name = "TrainingService",
}

function TrainingService:Start(): ()
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace

	for _, definition in TrainingDummies do
		local ok, err = pcall(function()
			spawnDummy(definition)
		end)
		if not ok then
			log:Warn("No se pudo crear el muñeco %s: %s", definition.Id, tostring(err))
		end
	end

	task.spawn(function()
		while true do
			task.wait(THINK_SECONDS)
			local now = os.clock()
			for dummy in dummies do
				think(dummy, now)
			end
		end
	end)
end

return TrainingService
