--!strict

-- Contenido: armas (capa IP, §4, D-034). El modelo lo pone Arte en Studio
-- (Assets/Models/<Model>); hasta entonces se ve la hoja provisional.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

type WeaponDefinition = ContentTypes.WeaponDefinition

local Weapons: { [string]: WeaponDefinition } = {
	-- Zanpakuto sin nombre de un Shinigami recién llegado.
	Asauchi = {
		Id = "Asauchi",
		DisplayName = "Asauchi",
		Model = "MDL_Weapon_Asauchi",
		-- Hoja hacia delante, con el mango en la mano.
		Grip = CFrame.new(0, -0.3, -1.9),
		Placeholder = { Size = Vector3.new(0.15, 0.35, 3.8), Color = "#D8DCE3" },
	},
}

return Weapons
