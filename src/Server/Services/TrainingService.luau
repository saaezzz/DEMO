--!strict

-- Muñecos de entrenamiento (M2): NPCs que usan exactamente el mismo sistema
-- de combate que los jugadores (Character, CombatService, habilidades).
-- Reaparecen al morir.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local TrainingDummies = require(script.Parent.Parent.Content.TrainingDummies)
local CharacterReplicator = require(script.Parent.Parent.Modules.CharacterReplicator)
local CombatService = require(script.Parent.CombatService)

type Character = CharacterModule.Character
type DummyDefinition = TrainingDummies.DummyDefinition

local FOLDER_NAME = "TrainingDummies"
local RESPAWN_SECONDS = 3
local THINK_SECONDS = 0.25

type Dummy = {
	Definition: DummyDefinition,
	Model: Model,
	Character: Character,
	NextAttackAt: number,
	-- Hay un ataque avisado en curso.
	Winding: boolean,
}

local log = Logger.new("TrainingService")
local folder: Folder
local dummies: { [Model]: Dummy } = {}

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

local function faceTowards(model: Model, target: Vector3): ()
	local root = model.PrimaryPart
	if root == nil then
		return
	end
	local flatTarget = Vector3.new(target.X, root.Position.Y, target.Z)
	if (flatTarget - root.Position).Magnitude > 1e-3 then
		root.CFrame = CFrame.lookAt(root.Position, flatTarget)
	end
end

-- Aviso visible (el cliente lo resalta en rojo) y, tras TelegraphSeconds, el ataque.
local function tryAttack(dummy: Dummy, now: number): ()
	local definition = dummy.Definition
	local ability = definition.AttackAbility
	local root = dummy.Model.PrimaryPart
	if ability == nil or root == nil or dummy.Winding or now < dummy.NextAttackAt then
		return
	end
	local target = findNearestPlayer(root.Position, definition.AttackRange or 8)
	if target == nil then
		return
	end

	dummy.Winding = true
	dummy.NextAttackAt = now + (definition.AttackIntervalSeconds or 2.5)
	faceTowards(dummy.Model, target.Position)
	dummy.Model:SetAttribute(ReplicatedAttributes.TELEGRAPH, now)

	task.delay(definition.TelegraphSeconds or 0.5, function()
		dummy.Winding = false
		if dummies[dummy.Model] ~= dummy or dummy.Character:GetState() ~= "Idle" then
			return
		end
		if target.Parent ~= nil then
			faceTowards(dummy.Model, target.Position)
		end
		CombatService:ActivateAbility(dummy.Model, ability)
	end)
end

local function think(dummy: Dummy, now: number): ()
	if not dummy.Character:IsAlive() then
		return
	end
	local behavior = dummy.Definition.Behavior
	if behavior == "Attacker" and dummy.Character:GetState() == "Idle" then
		tryAttack(dummy, now)
	elseif behavior == "Guard" and dummy.Character:GetState() == "Idle" then
		CombatService:SetBlocking(dummy.Model, true)
	end
end

local function buildModel(definition: DummyDefinition): Model
	local model =
		Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	model.Name = `Dummy_{definition.Id}`
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	humanoid.MaxHealth = definition.MaxHealth
	humanoid.Health = definition.MaxHealth
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	-- Mira hacia el origen, donde aparecen los jugadores.
	local lookTarget = Vector3.new(0, definition.Position.Y, 0)
	model:PivotTo(CFrame.lookAt(definition.Position, lookTarget))
	model:SetAttribute(ReplicatedAttributes.DISPLAY_NAME, definition.DisplayName)
	return model
end

local function releaseDummy(model: Model): ()
	local dummy = dummies[model]
	if dummy == nil then
		return
	end
	dummies[model] = nil
	CombatService:UnregisterCharacter(model)
	dummy.Character:Destroy()
end

spawnDummy = function(definition: DummyDefinition): ()
	local model = buildModel(definition)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local character = CharacterModule.new({
		Race = Races.Default,
		Level = 1,
		MaxHealth = definition.MaxHealth,
		MaxPosture = definition.MaxPosture,
		Resources = {},
	})

	local dummy: Dummy = {
		Definition = definition,
		Model = model,
		Character = character,
		NextAttackAt = 0,
		Winding = false,
	}
	dummies[model] = dummy

	-- La vida autoritativa vive en Character; el Humanoid solo la refleja.
	character.HealthChanged:Connect(function(health: number)
		humanoid.Health = math.clamp(health, 0, humanoid.MaxHealth)
	end)
	character.Died:Connect(function()
		task.delay(RESPAWN_SECONDS, function()
			releaseDummy(model)
			model:Destroy()
			spawnDummy(definition)
		end)
	end)

	CollectionService:AddTag(model, ReplicatedAttributes.NPC_TAG)
	CharacterReplicator.Bind(model, character)
	model.Parent = folder

	local root = model:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		-- El servidor simula su física: el empuje de los golpes se aplica aquí.
		root:SetNetworkOwner(nil)
	end
	CombatService:RegisterCharacter(nil, model, character)
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
			for _, dummy in dummies do
				think(dummy, now)
			end
		end
	end)
end

return TrainingService
