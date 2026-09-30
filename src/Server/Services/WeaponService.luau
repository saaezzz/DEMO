--!strict

-- Arma en la mano del personaje (D-034). Usa el modelo de Arte si está en
-- Studio (Assets/Models/<Weapon.Model>) y, si no, una hoja provisional. Se
-- crea en el servidor, así que todos los jugadores la ven.
--
-- Modelo de Arte: un Model con una pieza llamada "Handle" (el mango). Todas
-- sus piezas se sueldan al Handle y el Handle a la mano según Weapon.Grip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)
local Weapons = require(ReplicatedStorage.Shared.Content.Weapons)
local AssetLibrary = require(ReplicatedStorage.Shared.Modules.AssetLibrary)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

type WeaponDefinition = ContentTypes.WeaponDefinition

local WEAPON_NAME = "Weapon"
local HANDLE_NAME = "Handle"

local log = Logger.new("WeaponService")

local function buildPlaceholder(definition: WeaponDefinition): Model
	local weapon = Instance.new("Model")
	local blade = Instance.new("Part")
	blade.Name = HANDLE_NAME
	blade.Size = definition.Placeholder.Size
	blade.Color = Color3.fromHex(definition.Placeholder.Color)
	blade.Material = Enum.Material.Metal
	blade.Parent = weapon

	-- Guarda (tsuba) cerca del mango.
	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.6, 0.6, 0.1)
	guard.Color = Color3.fromRGB(40, 36, 30)
	guard.CFrame = blade.CFrame * CFrame.new(0, 0, blade.Size.Z * 0.3)
	guard.Parent = weapon

	weapon.PrimaryPart = blade
	return weapon
end

-- Modelo de Arte válido (con Handle), o nil.
local function cloneArtWeapon(definition: WeaponDefinition): Model?
	local clone = AssetLibrary.Clone(definition.Model)
	if clone == nil then
		return nil
	end
	local handle = clone:FindFirstChild(HANDLE_NAME, true)
	if clone:IsA("Model") and handle ~= nil and handle:IsA("BasePart") then
		clone.PrimaryPart = handle
		return clone
	end
	log:Warn("%s debe ser un Model con una pieza Handle; se usa la hoja provisional", definition.Model)
	clone:Destroy()
	return nil
end

-- Decorativa: no choca, no pesa y no la encuentran las hitboxes.
local function prepareParts(weapon: Model, handle: BasePart): ()
	for _, descendant in weapon:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
			if descendant ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
end

local WeaponService = {
	Name = "WeaponService",
}

-- Pone el arma `weaponId` en la mano de `model` (nil = quitar el arma).
function WeaponService:Equip(model: Model, weaponId: string?): ()
	local previous = model:FindFirstChild(WEAPON_NAME)
	if previous ~= nil then
		previous:Destroy()
	end
	local definition = if weaponId ~= nil then Weapons[weaponId] else nil
	local hand = model:FindFirstChild("RightHand")
	if definition == nil or hand == nil or not hand:IsA("BasePart") then
		return
	end

	local weapon = cloneArtWeapon(definition) or buildPlaceholder(definition)
	weapon.Name = WEAPON_NAME
	local handle = weapon.PrimaryPart :: BasePart
	prepareParts(weapon, handle)
	-- Mueve todo el modelo para que el Handle quede en la mano según el Grip.
	local pivotOffset = handle.CFrame:ToObjectSpace(weapon:GetPivot())
	weapon:PivotTo(hand.CFrame * definition.Grip * pivotOffset)

	local grip = Instance.new("WeldConstraint")
	grip.Part0 = hand
	grip.Part1 = handle
	grip.Parent = handle
	weapon.Parent = model
end

return WeaponService
