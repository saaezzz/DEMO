--!strict

local Shared = game:GetService("ReplicatedStorage").Shared
local GameTypes = require(Shared.Types.GameTypes)

type CharacterAttributes = GameTypes.CharacterAttributes
type CharacterRace = GameTypes.CharacterRace

export type InventoryItem = {
	Id: string,
	Quantity: number,
}

export type PlayerSettings = {
	MusicVolume: number,
	SfxVolume: number,
	CameraShake: boolean,
}

-- Borrador del esquema de datos persistentes. Se rediseñará con DataService v1
-- (ProfileStore, DataVersion y migraciones; ver DECISIONS.md D-004).
export type PlayerProfileData = {
	Attributes: CharacterAttributes,
	Experience: number,
	Currency: number,
	Inventory: { InventoryItem },
	Settings: PlayerSettings,
}

local DEFAULT_PROFILE_DATA: PlayerProfileData = {
	Attributes = {
		Health = 100,
		MaxHealth = 100,
		Reiatsu = 100,
		MaxReiatsu = 100,
		Posture = 0,
		MaxPosture = 100,
		Race = "Human" :: CharacterRace,
		Level = 1,
	},
	Experience = 0,
	Currency = 0,
	Inventory = {},
	Settings = {
		MusicVolume = 0.5,
		SfxVolume = 0.5,
		CameraShake = true,
	},
}

return {
	DEFAULT_PROFILE_DATA = DEFAULT_PROFILE_DATA,
}
