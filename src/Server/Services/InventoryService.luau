--!strict

-- Inventario (§46, D-036): añadir objetos (botín, recompensas, kits) y usar
-- consumibles. El inventario vive en el perfil (Inventory) y replica al
-- dueño; el cliente solo pide usar un objeto y el servidor lo valida todo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local ItemConfig = require(ReplicatedStorage.Shared.Config.ItemConfig)
local Items = require(ReplicatedStorage.Shared.Content.Items)
local InventoryLogic = require(ReplicatedStorage.Shared.Modules.InventoryLogic)
local Schema = require(ReplicatedStorage.Shared.Network.Schema)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local CombatRegistry = require(script.Parent.Parent.Combat.CombatRegistry)
local Cooldowns = require(script.Parent.Parent.Combat.Cooldowns)
local ServerNetwork = require(script.Parent.Parent.Network.ServerNetwork)
local DataService = require(script.Parent.DataService)

type RequestResponse = GameTypes.RequestResponse

local MAX_ITEM_ID_LENGTH = 32

local log = Logger.new("InventoryService")
local cooldowns = Cooldowns.new()

local validateUseRequest = Schema.record({
	ItemId = Schema.string(MAX_ITEM_ID_LENGTH),
})

local function respond(status: "Accepted" | "Rejected", message: string?): RequestResponse
	return { Status = status, Message = message }
end

local function useItem(player: Player, request: { ItemId: string }): RequestResponse
	local data = DataService:GetData(player)
	local definition = Items[request.ItemId]
	local use = if definition ~= nil then definition.Use else nil
	if data == nil or definition == nil or use == nil then
		return respond("Rejected", "Objeto no utilizable")
	end
	if InventoryLogic.Count(data.Inventory, definition.Id) <= 0 then
		return respond("Rejected", "No tienes ese objeto")
	end
	local entity = CombatRegistry.GetAlive(player)
	if entity == nil then
		return respond("Rejected", "Personaje no disponible")
	end
	if not cooldowns:IsReady(player, definition.Id) then
		return respond("Rejected", "Aún no puedes usarlo")
	end

	-- No se gasta si no haría nada.
	local character = entity.Character
	local restore = use.Restore
	local healUseful = use.Heal ~= nil and character:GetHealth() < character:GetMaxHealth()
	local restoreUseful = restore ~= nil
		and character:HasResource(restore.Resource)
		and character:GetResource(restore.Resource) < character:GetMaxResource(restore.Resource)
	if not healUseful and not restoreUseful then
		return respond("Rejected", "No tendría efecto")
	end

	local updated = InventoryLogic.Remove(data.Inventory, definition.Id, 1)
	if updated == nil then
		return respond("Rejected", "No tienes ese objeto")
	end
	DataService:SetValue(player, "Inventory", updated)
	cooldowns:Start(player, definition.Id, use.Cooldown)

	if use.Heal ~= nil then
		character:Heal(use.Heal)
	end
	if restore ~= nil then
		character:RestoreResource(restore.Resource, restore.Amount)
	end
	return respond("Accepted", nil)
end

local InventoryService = {
	Name = "InventoryService",
}

function InventoryService:Start(): ()
	ServerNetwork:HandleFunction("UseItem", validateUseRequest, useItem)
end

-- Añade objetos al inventario. Devuelve cuántos cupieron.
function InventoryService:AddItem(player: Player, itemId: string, quantity: number): number
	local data = DataService:GetData(player)
	local definition = Items[itemId]
	if data == nil or definition == nil then
		log:Warn("No se puede dar %s a %s", itemId, player.Name)
		return 0
	end
	local updated, added = InventoryLogic.Add(data.Inventory, definition, quantity, ItemConfig.MaxSlots)
	if added > 0 then
		DataService:SetValue(player, "Inventory", updated)
	end
	if added < quantity then
		log:Info("Inventario de %s lleno: se pierden %d %s", player.Name, quantity - added, itemId)
	end
	return added
end

return InventoryService
