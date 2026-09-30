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
		Placeholder = { Size = Vector3.new(0.15, 0.35, 3.8), Color = "#D8DCE3", Guard = true },
	},
	-- Arco espiritual de un Quincy, en la mano izquierda (se tira con la derecha).
	SpiritBow = {
		Id = "SpiritBow",
		DisplayName = "Arco espiritual",
		Model = "MDL_Weapon_SpiritBow",
		AttachTo = "LeftHand",
		-- Vertical, con el centro del arco en la mano.
		Grip = CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(90), 0, 0),
		Placeholder = { Size = Vector3.new(0.2, 0.3, 4.4), Color = "#8FDFFF", Glow = true },
	},
	-- Máscara de un Hollow: no es un arma, pero se lleva igual (en la cabeza).
	HollowMask = {
		Id = "HollowMask",
		DisplayName = "Máscara de Hollow",
		Model = "MDL_Accessory_HollowMask",
		AttachTo = "Head",
		-- Delante de la cara.
		Grip = CFrame.new(0, 0.05, -0.62),
		Placeholder = { Size = Vector3.new(1.1, 1.15, 0.2), Color = "#F2F0E6" },
	},
}

return Weapons
