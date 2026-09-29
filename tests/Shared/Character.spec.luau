local Character = require(game:GetService("ReplicatedStorage").Shared.Modules.Character)

local function newCharacter(resources)
	return Character.new({
		Race = "TestRace",
		Level = 1,
		MaxHealth = 100,
		MaxPosture = 100,
		Resources = resources or { Energy = { Current = 50, Max = 100 } },
	})
end

return {
	["empieza con vida máxima, postura 0 y estado Idle"] = function()
		local character = newCharacter()
		expect(character:GetHealth()).toBe(100)
		expect(character:GetPosture()).toBe(0)
		expect(character:GetState()).toBe("Idle")
		expect(character:IsAlive()).toBe(true)
	end,

	["limita los recursos iniciales a su máximo"] = function()
		local character = newCharacter({ Energy = { Current = 500, Max = 100 } })
		expect(character:GetResource("Energy")).toBe(100)
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

	["morir emite Died una vez y pasa a Dead"] = function()
		local character = newCharacter()
		local deaths = 0
		character.Died:Connect(function()
			deaths += 1
		end)

		character:TakeDamage(150)
		character:TakeDamage(10)

		expect(character:GetHealth()).toBe(0)
		expect(character:IsAlive()).toBe(false)
		expect(character:GetState()).toBe("Dead")
		expect(deaths).toBe(1)
	end,

	["Dead es terminal"] = function()
		local character = newCharacter()
		character:TakeDamage(100)
		expect(character:CanTransitionTo("Idle")).toBe(false)
		expect(character:CanTransitionTo("Stunned")).toBe(false)
	end,

	["morir durante un ataque sale de Attacking"] = function()
		local character = newCharacter()
		local seen = {}
		character:OnStateChanged(function(oldState, newState)
			table.insert(seen, oldState .. "->" .. newState)
		end)

		character:TransitionTo("Attacking")
		character:TakeDamage(100)

		expect(seen).toEqual({ "Idle->Attacking", "Attacking->Dead" })
	end,

	["un personaje muerto no se cura"] = function()
		local character = newCharacter()
		character:TakeDamage(100)
		character:Heal(50)
		expect(character:GetHealth()).toBe(0)
	end,

	["Heal no supera la vida máxima"] = function()
		local character = newCharacter()
		character:TakeDamage(10)
		character:Heal(50)
		expect(character:GetHealth()).toBe(100)
	end,

	["SpendResource cobra todo o nada"] = function()
		local character = newCharacter({ Energy = { Current = 10, Max = 100 } })
		expect(character:SpendResource("Energy", 20)).toBe(false)
		expect(character:GetResource("Energy")).toBe(10)
		expect(character:SpendResource("Energy", 10)).toBe(true)
		expect(character:GetResource("Energy")).toBe(0)
	end,

	["SpendResource falla con recursos inexistentes"] = function()
		local character = newCharacter()
		expect(character:HasResource("Missing")).toBe(false)
		expect(character:SpendResource("Missing", 1)).toBe(false)
		expect(character:GetResource("Missing")).toBe(0)
		expect(character:GetMaxResource("Missing")).toBe(0)
		expect(character:RestoreResource("Missing", 5)).toBe(0)
	end,

	["ResourceChanged informa del recurso y los valores"] = function()
		local character = newCharacter()
		local changes = {}
		character.ResourceChanged:Connect(function(resourceId, newValue, oldValue)
			table.insert(changes, { resourceId, newValue, oldValue })
		end)

		character:SpendResource("Energy", 20)
		character:RestoreResource("Energy", 5)

		expect(changes).toEqual({ { "Energy", 30, 50 }, { "Energy", 35, 30 } })
	end,

	["RestoreResource no supera el máximo ni emite si ya está lleno"] = function()
		local character = newCharacter({ Energy = { Current = 95, Max = 100 } })
		local emissions = 0
		character.ResourceChanged:Connect(function()
			emissions += 1
		end)

		character:RestoreResource("Energy", 50)
		character:RestoreResource("Energy", 50)

		expect(character:GetResource("Energy")).toBe(100)
		expect(emissions).toBe(1)
	end,

	["GetResourceIds lista los recursos del personaje"] = function()
		local character = newCharacter({ A = { Current = 1, Max = 1 }, B = { Current = 1, Max = 1 } })
		local ids = character:GetResourceIds()
		table.sort(ids)
		expect(ids).toEqual({ "A", "B" })
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

	["las interrupciones son alcanzables desde cualquier acción"] = function()
		for _, action in { "Attacking", "Blocking", "Dashing", "Casting", "Transforming" } do
			local character = newCharacter()
			expect(character:TransitionTo(action)).toBe(true)
			expect(character:CanTransitionTo("Stunned")).toBe(true)
			expect(character:CanTransitionTo("Dead")).toBe(true)
		end
	end,

	["no se encadenan acciones sin volver a Idle"] = function()
		local character = newCharacter()
		character:TransitionTo("Attacking")
		expect(character:CanTransitionTo("Dashing")).toBe(false)
		expect(character:CanTransitionTo("Blocking")).toBe(false)
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
