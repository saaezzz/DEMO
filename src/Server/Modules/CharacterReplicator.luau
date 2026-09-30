--!strict

-- Refleja el estado autoritativo de un Character en atributos de su modelo
-- (D-021) para que los clientes puedan mostrarlo. La vida ya replica por el
-- Humanoid; aquí van nivel, raza, postura, recursos y las tres capas de estado.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterModule = require(ReplicatedStorage.Shared.Modules.Character)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)

type Character = CharacterModule.Character

local CharacterReplicator = {}

-- Las conexiones son a señales del Character: Character:Destroy() las corta.
function CharacterReplicator.Bind(model: Instance, character: Character): ()
	model:SetAttribute(ReplicatedAttributes.LEVEL, character.Level)
	model:SetAttribute(ReplicatedAttributes.RACE, character.Race)
	model:SetAttribute(ReplicatedAttributes.MAX_POSTURE, character:GetMaxPosture())
	model:SetAttribute(ReplicatedAttributes.POSTURE, character:GetPosture())
	model:SetAttribute(ReplicatedAttributes.STATE, character:GetState())
	model:SetAttribute(ReplicatedAttributes.LOCOMOTION, character:GetLocomotion())
	model:SetAttribute(ReplicatedAttributes.FORM, character:GetForm())

	for _, resourceId in character:GetResourceIds() do
		model:SetAttribute(ReplicatedAttributes.ResourceMax(resourceId), character:GetMaxResource(resourceId))
		model:SetAttribute(ReplicatedAttributes.Resource(resourceId), character:GetResource(resourceId))
	end

	character.PostureChanged:Connect(function(posture: number)
		model:SetAttribute(ReplicatedAttributes.POSTURE, posture)
	end)
	character.ResourceChanged:Connect(function(resourceId: string, value: number)
		model:SetAttribute(ReplicatedAttributes.Resource(resourceId), value)
	end)
	character:OnStateChanged(function(_, newState)
		model:SetAttribute(ReplicatedAttributes.STATE, newState)
	end)
	character.LevelChanged:Connect(function(level: number)
		model:SetAttribute(ReplicatedAttributes.LEVEL, level)
	end)
	character.LocomotionChanged:Connect(function(locomotion)
		model:SetAttribute(ReplicatedAttributes.LOCOMOTION, locomotion)
	end)
	character.FormChanged:Connect(function(formId)
		model:SetAttribute(ReplicatedAttributes.FORM, formId)
	end)
end

return CharacterReplicator
