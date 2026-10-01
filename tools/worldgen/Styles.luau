--!strict

-- Paleta y variedad del mapa. Cambiar aquí los colores cambia todo el pueblo.

local Styles = {}

Styles.Ground = "#98948A"
Styles.Grass = "#6E9B4E"
Styles.GrassDark = "#5A8440"
Styles.Dirt = "#A88B64"
Styles.Sand = "#C9B488"
Styles.Asphalt = "#3B3E43"
Styles.AsphaltLane = "#55585D"
Styles.Sidewalk = "#B7B2A7"
Styles.Curb = "#D2CEC4"
Styles.RoadLine = "#EDEDE6"
Styles.RoadLineYellow = "#E8C24A"
Styles.Concrete = "#A7A49C"
Styles.ConcreteDark = "#7D7A73"
Styles.Water = "#3F7F8C"
Styles.Riverbed = "#4F4A3E"
Styles.Metal = "#8E959C"
Styles.MetalDark = "#4A4F55"
Styles.Wood = "#7A5A3C"
Styles.WoodDark = "#4B3525"
Styles.Rail = "#6A6158"
Styles.Ballast = "#7E766A"
Styles.Sleeper = "#4A3B2E"
Styles.Pole = "#9A9890"
Styles.LampWarm = "#FFD8A0"
Styles.WindowDay = "#6F8699"
Styles.Glass = "#8FB3C8"

-- Fachadas de casas japonesas: blancos, cremas, beiges y grises suaves.
Styles.HouseWalls = {
	"#EDEAE2",
	"#E4DDCF",
	"#D8CDB8",
	"#CFC7BA",
	"#E9E1D0",
	"#C9C2B6",
	"#DCD6CB",
	"#B8AE9C",
	"#E6E0D6",
	"#D3C3A5",
	"#C7CDD2",
	"#9C8B77",
}

Styles.Roofs = { "#3E4650", "#2F3640", "#5A3D33", "#4C5A4A", "#3D4B63", "#6B4B3A", "#555555" }

Styles.ApartmentWalls = { "#E2DED5", "#D6D0C4", "#C8C4BC", "#E9E4DA", "#BDB5A8", "#D9D2C1" }

Styles.OfficeGlass = { "#5F7E95", "#6D8B9C", "#4F6B80", "#7D95A3" }
Styles.OfficeFrame = { "#D2D2CE", "#B9B9B4", "#E0DFDA" }

Styles.Awnings = { "#B8352E", "#2F6FA3", "#3C8A4F", "#D98E2B", "#7A3E8F", "#C9C9C9", "#2B2B2B" }

Styles.Cars = { "#F2F2F2", "#C9CCD1", "#1E1E22", "#A8322D", "#2E5AA8", "#6B6F75", "#F2F2F2", "#8C8C8C" }

Styles.WindowsNight = { "#FFD9A0", "#FFE6BF", "#EAF1FF", "#FFCF8A" }

-- Letreros de tiendas (japonés genérico).
Styles.ShopSigns = {
	"ラーメン",
	"喫茶店",
	"本屋",
	"花屋",
	"薬局",
	"パン屋",
	"居酒屋",
	"床屋",
	"八百屋",
	"寿司",
	"カラオケ",
	"クリーニング",
	"文房具",
	"たばこ",
	"酒店",
	"うどん",
}

Styles.VendingColors = { "#E8E8E8", "#C8282E", "#2C62B5", "#F2F2F2", "#2E8B57" }

return Styles
