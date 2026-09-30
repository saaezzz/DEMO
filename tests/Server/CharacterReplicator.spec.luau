local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Character = require(ReplicatedStorage.Shared.Modules.Character)
local ReplicatedAttributes = require(ReplicatedStorage.Shared.Network.ReplicatedAttributes)
local CharacterReplicator = require(ServerScriptService.Server.Modules.CharacterReplicator)

-- Modelo falso: solo necesita SetAttribute.
local function fakeModel()
	local attributes = {}
	return {
		Attributes = attributes,
		SetAttribute = function(_, name, value)
			attributes[name] = value
		end,
	}
end

local function bind()
	local model = fakeModel()
	local character = Character.new({
		Race = "TestRace",
		Level = 3,
		MaxHealth = 100,
		MaxPosture = 80,
		Resources = { Energy = { Current = 40, Max = 100 } },
	})
	CharacterReplicator.Bind(model, character)
	return model.Attributes, character
end

return {
	["escribe el estado inicial"] = function()
		local attributes = bind()
		expect(attributes.Level).toBe(3)
		expect(attributes.Race).toBe("TestRace")
		expect(attributes.MaxPosture).toBe(80)
		expect(attributes.Posture).toBe(0)
		expect(attributes.ActionState).toBe("Idle")
		expect(attributes.Locomotion).toBe("Stationary")
		expect(attributes.Form).toBeNil()
		expect(attributes[ReplicatedAttributes.Resource("Energy")]).toBe(40)
		expect(attributes[ReplicatedAttributes.ResourceMax("Energy")]).toBe(100)
	end,

	["refleja postura, recursos y estado cuando cambian"] = function()
		local attributes, character = bind()
		character:ApplyPostureDamage(25)
		character:SpendResource("Energy", 15)
		character:SetLocomotion("Running")
		character:SetForm("TestForm")
		character:TransitionTo("Blocking")
		expect(attributes.Posture).toBe(25)
		expect(attributes.Locomotion).toBe("Running")
		expect(attributes.Form).toBe("TestForm")
		expect(attributes[ReplicatedAttributes.Resource("Energy")]).toBe(25)
		expect(attributes.ActionState).toBe("Blocking")
	end,

	["deja de escribir tras destruir el Character"] = function()
		local attributes, character = bind()
		character:Destroy()
		character:TransitionTo("Blocking")
		expect(attributes.ActionState).toBe("Idle")
	end,

	["ParseResource reconoce solo los atributos de valor actual"] = function()
		expect(ReplicatedAttributes.ParseResource(ReplicatedAttributes.Resource("Energy"))).toBe("Energy")
		expect(ReplicatedAttributes.ParseResource(ReplicatedAttributes.ResourceMax("Energy"))).toBeNil()
		expect(ReplicatedAttributes.ParseResource("Posture")).toBeNil()
	end,
}
