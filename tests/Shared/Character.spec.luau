local Character = require(game:GetService("ReplicatedStorage").Shared.Modules.Character)

local function newCharacter(overrides)
	local attributes = {
		Health = 100,
		MaxHealth = 100,
		Reiatsu = 50,
		MaxReiatsu = 100,
		Posture = 0,
		MaxPosture = 100,
		Race = "Shinigami",
		Level = 1,
	}
	for key, value in overrides or {} do
		attributes[key] = value
	end
	return Character.new(attributes)
end

return {
	["limita los valores iniciales a sus máximos"] = function()
		local character = newCharacter({ Health = 500, Reiatsu = 500, Posture = 500 })
		expect(character:GetHealth()).toBe(100)
		expect(character:GetReiatsu()).toBe(100)
		expect(character:GetPosture()).toBe(100)
	end,

	["TakeDamage reduce la vida y emite HealthChanged"] = function()
		local character = newCharacter()
		local changes = {}
		character.HealthChanged:Connect(function(newValue, oldValue)
			table.insert(changes, { newValue, oldValue })
		end)

		character:TakeDamage(30)

		expect(character:GetHealth()).toBe(70)
		expect(changes).toEqual({ { 70, 100 } })
	end,

	["TakeDamage ignora cantidades no positivas"] = function()
		local character = newCharacter()
		character:TakeDamage(0)
		character:TakeDamage(-10)
		expect(character:GetHealth()).toBe(100)
	end,

	["la vida llega a 0 y emite Died una sola vez"] = function()
		local character = newCharacter()
		local deaths = 0
		character.Died:Connect(function()
			deaths += 1
		end)

		character:TakeDamage(150)
		character:TakeDamage(10)

		expect(character:GetHealth()).toBe(0)
		expect(character:IsAlive()).toBe(false)
		expect(deaths).toBe(1)
	end,

	["un personaje muerto no se cura"] = function()
		local character = newCharacter()
		character:TakeDamage(100)
		character:Heal(50)
		expect(character:GetHealth()).toBe(0)
	end,

	["Heal no supera la vida máxima"] = function()
		local character = newCharacter({ Health = 90 })
		character:Heal(50)
		expect(character:GetHealth()).toBe(100)
	end,

	["SpendReiatsu falla sin recurso suficiente y no gasta nada"] = function()
		local character = newCharacter({ Reiatsu = 10 })
		expect(character:SpendReiatsu(20)).toBe(false)
		expect(character:GetReiatsu()).toBe(10)
		expect(character:SpendReiatsu(10)).toBe(true)
		expect(character:GetReiatsu()).toBe(0)
	end,

	["RestoreReiatsu no emite si ya está al máximo"] = function()
		local character = newCharacter({ Reiatsu = 100 })
		local emitted = false
		character.ReiatsuChanged:Connect(function()
			emitted = true
		end)

		character:RestoreReiatsu(10)

		expect(emitted).toBe(false)
	end,

	["la postura sube con daño, baja con RecoverPosture y se vacía con ResetPosture"] = function()
		local character = newCharacter()
		character:ApplyPostureDamage(60)
		expect(character:GetPosture()).toBe(60)
		character:RecoverPosture(20)
		expect(character:GetPosture()).toBe(40)
		character:RecoverPosture(100)
		expect(character:GetPosture()).toBe(0)
		character:ApplyPostureDamage(500)
		expect(character:GetPosture()).toBe(100)
		character:ResetPosture()
		expect(character:GetPosture()).toBe(0)
	end,

	["llenar la postura no cambia el estado (lo decide CombatService)"] = function()
		local character = newCharacter()
		character:ApplyPostureDamage(100)
		expect(character:GetState()).toBe("Idle")
	end,

	["delegación de estados a la máquina de estados"] = function()
		local character = newCharacter()
		local changes = {}
		character:OnStateChanged(function(oldState, newState)
			table.insert(changes, oldState .. "->" .. newState)
		end)

		expect(character:CanTransitionTo("Attacking")).toBe(true)
		character:TransitionTo("Attacking")

		expect(character:GetState()).toBe("Attacking")
		expect(changes).toEqual({ "Idle->Attacking" })
	end,

	["tras Destroy es seguro llamar a sus métodos y no emite señales"] = function()
		local character = newCharacter()
		local emitted = false
		character.HealthChanged:Connect(function()
			emitted = true
		end)

		character:Destroy()
		character:Destroy()
		character:TakeDamage(10)

		expect(character:GetHealth()).toBe(100)
		expect(emitted).toBe(false)
	end,
}
