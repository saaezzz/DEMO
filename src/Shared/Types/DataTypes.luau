--!strict

local GameTypes = require(script.Parent.GameTypes)

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

-- Esquema completo de datos persistentes (ProfileService).
export type PlayerProfileData = {
	Attributes: CharacterAttributes,
	Experience: number,
	Currency: number,
	Inventory: { InventoryItem },
	Settings: PlayerSettings,
}

-- Subconjunto de PlayerProfileData replicado al cliente vía ReplicaService.
-- Debe evitarse exponer datos que permitan al cliente inferir información
-- explotable (por ejemplo, semillas de loot o datos de otros jugadores).
export type ReplicatedPlayerData = {
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
