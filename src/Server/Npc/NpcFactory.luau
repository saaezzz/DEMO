--!strict

-- Crea NPCs de combate (§41: ningún script propio por NPC). Un NPC es un rig
-- R15 con un Character, replicado (D-021), etiquetado (CombatNPC) y
-- registrado en CombatService como cualquier personaje. Lo usan los muñecos
-- de entrenamiento y los enemigos.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local Races = require(ReplicatedStorage.Shared.Content.Races)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local AssetLibrary = require(ReplicatedStorage.Shared.Modules.AssetLibrary)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CharacterReplicator = require(script.Parent.Parent.Modules.CharacterReplicator)
local CombatService = require(script.Parent.Parent.Services.CombatService)

type Character = CharacterModule.Character

local log = Logger.new("NpcFactory")

export type NpcOptions = {
	Name: string,
	DisplayName: string,
	Level: number,
	MaxHealth: number,
	MaxPosture: number,
	CFrame: CFrame,
	WalkSpeed: number,
	Parent: Instance,
	-- Modelo del manifiesto (MDL_...) colocado en Studio. Si falta, se genera un rig
	-- R15 con BodyColor, Scale y Mask.
	ModelAsset: string?,
	BodyColor: Color3?,
	-- 1 = tamaño normal.
	Scale: number?,
	-- Máscara blanca en la cara.
	Mask: boolean?,
	-- Atributos extra del modelo (p. ej. IsBoss), puestos antes de que aparezca.
	Attributes: { [string]: any }?,
}

export type Npc = {
	Model: Model,
	Character: Character,
	Humanoid: Humanoid,
	RootPart: BasePart,
}

local function buildDescription(options: NpcOptions): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	local color = options.BodyColor
	if color ~= nil then
		description.HeadColor = color
		description.TorsoColor = color
		description.LeftArmColor = color
		description.RightArmColor = color
		description.LeftLegColor = color
		description.RightLegColor = color
	end
	local scale = options.Scale or 1
	description.HeightScale = scale
	description.WidthScale = scale
	description.DepthScale = scale
	description.HeadScale = scale
	return description
end

local function addMask(model: Model, scale: number): ()
	local head = model:FindFirstChild("Head")
	if head == nil or not head:IsA("BasePart") then
		return
	end
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Color = Color3.fromRGB(240, 238, 230)
	mask.Material = Enum.Material.SmoothPlastic
	mask.Size = Vector3.new(1.15, 1.2, 0.25) * scale
	mask.CanCollide = false
	mask.CanTouch = false
	mask.Massless = true
	mask.CFrame = head.CFrame * CFrame.new(0, 0.05 * scale, -0.6 * scale)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = mask
	weld.Parent = mask
	mask.Parent = model
end

-- Rig generado para cuando Arte aún no ha colocado el modelo.
local function buildRig(options: NpcOptions): Model
	local model = Players:CreateHumanoidModelFromDescription(buildDescription(options), Enum.HumanoidRigType.R15)
	if options.Mask then
		addMask(model, options.Scale or 1)
	end
	return model
end

-- Copia del modelo de Arte, si está colocado y es un personaje válido.
local function cloneArtModel(assetName: string?): Model?
	if assetName == nil then
		return nil
	end
	local clone = AssetLibrary.Clone(assetName)
	if clone == nil then
		return nil
	end
	if
		clone:IsA("Model")
		and clone:FindFirstChildOfClass("Humanoid") ~= nil
		and clone:FindFirstChild("HumanoidRootPart") ~= nil
	then
		return clone
	end
	log:Warn("%s debe ser un Model con Humanoid y HumanoidRootPart; se usa el rig provisional", assetName)
	clone:Destroy()
	return nil
end

local NpcFactory = {}

function NpcFactory.Spawn(options: NpcOptions): Npc
	local model = cloneArtModel(options.ModelAsset) or buildRig(options)
	model.Name = options.Name
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local rootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model.PrimaryPart = rootPart
	humanoid.WalkSpeed = options.WalkSpeed
	humanoid.AutoRotate = options.WalkSpeed > 0
	humanoid.MaxHealth = options.MaxHealth
	humanoid.Health = options.MaxHealth
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	model:PivotTo(options.CFrame)
	model:SetAttribute(ReplicatedAttributes.DISPLAY_NAME, options.DisplayName)
	local attributes: { [string]: any } = options.Attributes or {}
	for name, value in attributes do
		model:SetAttribute(name, value)
	end

	local character = CharacterModule.new({
		Race = Races.Default,
		Level = options.Level,
		MaxHealth = options.MaxHealth,
		MaxPosture = options.MaxPosture,
		Resources = {},
	})
	-- La vida autoritativa vive en Character; el Humanoid solo la refleja.
	character.MaxHealthChanged:Connect(function(maxHealth: number)
		humanoid.MaxHealth = maxHealth
	end)
	character.HealthChanged:Connect(function(health: number)
		humanoid.Health = math.clamp(health, 0, humanoid.MaxHealth)
	end)

	CollectionService:AddTag(model, ReplicatedAttributes.NPC_TAG)
	CharacterReplicator.Bind(model, character)
	model.Parent = options.Parent
	-- El servidor simula su física: sus desplazamientos y los empujes se aplican aquí.
	rootPart:SetNetworkOwner(nil)
	CombatService:RegisterCharacter(nil, model, character)

	return {
		Model = model,
		Character = character,
		Humanoid = humanoid,
		RootPart = rootPart,
	}
end

function NpcFactory.Despawn(npc: Npc): ()
	CombatService:UnregisterCharacter(npc.Model)
	npc.Character:Destroy()
	npc.Model:Destroy()
end

return NpcFactory
