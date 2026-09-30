--!strict

-- Informe de assets en Output, solo en Studio (D-033). Ayuda a arte y
-- animación a comprobar su trabajo sin leer código:
-- - Qué assets del manifiesto ya están (con ID o colocados en Studio) y cuáles faltan.
-- - Objetos en ReplicatedStorage.Assets que no están en el manifiesto (¿nombre mal escrito?)
--   o que están en la carpeta equivocada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = require(ReplicatedStorage.Shared.Content.Assets)
local AssetLibrary = require(ReplicatedStorage.Shared.Modules.AssetLibrary)
local AssetRegistry = require(ReplicatedStorage.Shared.Modules.AssetRegistry)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)

local log = Logger.new("Assets")

local function reportMissing(): ()
	local ready, missing = 0, {}
	for _, entry in Assets do
		local placed = AssetLibrary.FindInstance(entry.Name) ~= nil
		if entry.AssetId ~= nil or placed then
			ready += 1
		else
			table.insert(missing, entry.Name)
		end
	end
	log:Info("%d de %d assets listos. Pendientes (se usa placeholder): %s", ready, #Assets, table.concat(missing, ", "))
end

local function reportUnknown(): ()
	local root = ReplicatedStorage:FindFirstChild("Assets")
	if root == nil then
		log:Warn("No existe ReplicatedStorage.Assets (Rojo debería crearla)")
		return
	end
	-- Varias categorías comparten carpeta (Sounds): cada carpeta se revisa una vez.
	local folderNames: { [string]: boolean } = {}
	for _, folderName in AssetLibrary.FOLDERS do
		folderNames[folderName] = true
	end
	for folderName in folderNames do
		local folder = root:FindFirstChild(folderName)
		for _, child in if folder ~= nil then folder:GetChildren() else {} do
			local entry = AssetRegistry.Get(child.Name)
			if entry == nil then
				log:Warn("Assets/%s/%s no está en el manifiesto (¿nombre mal escrito?)", folderName, child.Name)
			elseif AssetLibrary.FOLDERS[entry.Category] ~= folderName then
				log:Warn(
					"%s es de tipo %s: muévelo a Assets/%s",
					child.Name,
					entry.Category,
					AssetLibrary.FOLDERS[entry.Category]
				)
			end
		end
	end
end

local AssetAuditService = {
	Name = "AssetAuditService",
}

function AssetAuditService:Start(): ()
	if RunService:IsStudio() then
		reportMissing()
		reportUnknown()
	end
end

return AssetAuditService
