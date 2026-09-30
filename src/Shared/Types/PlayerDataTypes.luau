--!strict

-- Esquema de los datos persistentes del jugador (D-018). La versión y la
-- plantilla viven en el servidor (Server/Data/DataSchema); el cliente recibe
-- una copia de sus propios datos (D-005).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentTypes = require(ReplicatedStorage.Shared.Types.ContentTypes)

export type InventoryItem = {
	Id: string,
	Quantity: number,
}

export type PlayerSettings = {
	MusicVolume: number,
	SfxVolume: number,
	CameraShake: boolean,
}

-- Misión en curso: progreso de cada objetivo, en el orden de su definición.
export type ActiveQuest = {
	Id: string,
	Progress: { number },
}

export type QuestData = {
	Active: { ActiveQuest },
	-- Id de misión → true cuando se ha completado.
	Completed: { [string]: boolean },
}

export type PlayerData = {
	DataVersion: number,
	Race: ContentTypes.RaceId,
	Level: number,
	Experience: number,
	Currency: number,
	Inventory: { InventoryItem },
	Settings: PlayerSettings,
	Quests: QuestData,
	-- Estadística (Content/Stats) → valor (D-039).
	Stats: { [string]: number },
	-- Hitos de raza alcanzados, en el orden en que se alcanzaron.
	Milestones: { string },
}

-- Claves de primer nivel que se pueden modificar y replicar individualmente.
export type PlayerDataKey =
	"Race"
	| "Level"
	| "Experience"
	| "Currency"
	| "Inventory"
	| "Settings"
	| "Quests"
	| "Stats"
	| "Milestones"

-- Mensajes del remote PlayerData (servidor → propio cliente).
export type PlayerDataMessage = {
	-- Copia completa al cargar el perfil.
	Snapshot: PlayerData?,
	-- Cambio de una clave de primer nivel.
	Key: PlayerDataKey?,
	Value: any,
}

return {}
