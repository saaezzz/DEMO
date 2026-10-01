--!strict

-- Contenido: mapa principal, Karakura (capa IP, §4, D-043). Solo datos: el
-- generador (tools/worldgen) construye con ellos el modelo Workspace.Map, y
-- el juego los usa para colocar enemigos, muñecos, zonas y misiones
-- (Shared/Modules/WorldMap).
--
-- Las coordenadas se toman del mapa de distritos de referencia
-- (docs/references/karakura_map.png, 1000 × 1310 px) con px(x, y): así,
-- para mover algo basta con mirar el mapa. 1 px = 1,3 studs; el norte del
-- mapa es -Z en Roblox. El suelo está a Y = 0.
--
-- Este archivo no puede usar require ni `game`: lo lee también Lune.

export type Point = { X: number, Z: number }

export type RoadKind = "Arterial" | "Street"

export type Road = {
	Id: string,
	DisplayName: string,
	Kind: RoadKind,
	Points: { Point },
	-- El último punto se une con el primero.
	Closed: boolean?,
}

export type River = {
	Id: string,
	DisplayName: string,
	Points: { Point },
	-- Anchuras en studs: agua, llanura de hierba a cada lado y talud a cada lado.
	WaterWidth: number,
	FloodWidth: number,
	BankWidth: number,
}

-- Cómo se rellena un distrito: Residential (casas bajas), Dense (casas,
-- tiendas y bloques de pisos), Commercial (tiendas y oficinas).
export type DistrictStyle = "Residential" | "Dense" | "Commercial"

export type District = {
	Id: string,
	DisplayName: string,
	Kanji: string,
	Style: DistrictStyle,
	-- Giro (grados) de la cuadrícula de callejuelas del distrito.
	GridAngle: number,
	Polygon: { Point },
}

-- Tipos de edificio singular que sabe construir el generador.
export type LandmarkKind =
	"TrainingShop"
	| "Clinic"
	| "House"
	| "Dojo"
	| "SmallApartment"
	| "Ruins"
	| "HighSchool"
	| "School"
	| "Hospital"
	| "Station"
	| "Mall"
	| "Supermarket"
	| "ShopStreet"
	| "Shrine"
	| "RacecourseRuins"

export type Landmark = {
	Id: string,
	DisplayName: string,
	Kind: LandmarkKind,
	Position: Point,
	-- Parcela completa en studs (X = ancho, Z = fondo).
	Size: Point,
	-- Grados. A 0 la fachada mira al norte (-Z).
	Rotation: number,
	-- Texto del letrero, si lo tiene.
	Sign: string?,
}

export type ParkKind = "Park" | "Playground" | "Riverside"

export type Park = {
	Id: string,
	DisplayName: string,
	Kind: ParkKind,
	Position: Point,
	Size: Point,
	Rotation: number,
}

export type Hill = {
	Position: Point,
	Radius: number,
}

-- Punto del mundo con nombre para el juego (Y incluida).
export type Anchor = { X: number, Y: number, Z: number }

export type MapDefinition = {
	Name: string,
	Seed: number,
	-- Carretera de circunvalación: límite del pueblo.
	TownBoundary: { Point },
	-- Distancia (studs) de los muros invisibles a la circunvalación.
	BoundaryMargin: number,
	Rivers: { River },
	-- Costa sur: al sur de esta línea hay mar.
	Shoreline: { Point },
	Railway: { Point },
	Roads: { Road },
	Districts: { District },
	Landmarks: { Landmark },
	Parks: { Park },
	Hills: { Hill },
	-- Galería subterránea de entrenamiento bajo el Landmark TrainingShop.
	Underground: {
		Landmark: string,
		Center: Point,
		Size: number,
		FloorY: number,
		CeilingY: number,
	},
	Anchors: { [string]: Anchor },
}

local SCALE = 1.3
local ORIGIN_X = 520
local ORIGIN_Y = 770

-- Píxel del mapa de referencia → studs.
local function px(x: number, y: number): Point
	return { X = (x - ORIGIN_X) * SCALE, Z = (y - ORIGIN_Y) * SCALE }
end

local function anchor(point: Point, y: number, offsetX: number?, offsetZ: number?): Anchor
	return { X = point.X + (offsetX or 0), Y = y, Z = point.Z + (offsetZ or 0) }
end

local function points(list: { { number } }): { Point }
	local result: { Point } = {}
	for _, pair in list do
		table.insert(result, px(pair[1], pair[2]))
	end
	return result
end

-- Lugares -----------------------------------------------------------------------

local URAHARA = px(880, 752)
local TSUBAKIDAI_PARK = px(480, 625)
local MATSUKURA = px(570, 628)
local RACECOURSE = px(880, 900)
local RIVERSIDE = px(410, 1085)
-- La galería está al sur de la tienda, bajo Mitsumiya y Kinogaya, en línea
-- con la entrada del túnel (24 studs al oeste del centro de la parcela).
local UNDERGROUND_CENTER = { X = URAHARA.X - 24, Z = URAHARA.Z + 230 }

local Karakura: MapDefinition = {
	Name = "Karakura",
	Seed = 1520,

	TownBoundary = points({
		{ 215, 520 },
		{ 290, 455 },
		{ 420, 412 },
		{ 520, 392 },
		{ 600, 338 },
		{ 700, 322 },
		{ 800, 332 },
		{ 850, 310 },
		{ 930, 328 },
		{ 962, 365 },
		{ 968, 500 },
		{ 970, 650 },
		{ 966, 800 },
		{ 970, 960 },
		{ 965, 1090 },
		{ 900, 1138 },
		{ 760, 1148 },
		{ 640, 1146 },
		{ 520, 1156 },
		{ 420, 1172 },
		{ 300, 1148 },
		{ 200, 1112 },
		{ 125, 1078 },
		{ 92, 1000 },
		{ 100, 900 },
		{ 128, 822 },
		{ 160, 722 },
		{ 186, 620 },
	}),
	BoundaryMargin = 45,

	Rivers = {
		{
			Id = "Onose",
			DisplayName = "Río Onose",
			Points = points({
				{ 700, -260 },
				{ 610, -40 },
				{ 540, 120 },
				{ 470, 230 },
				{ 400, 285 },
				{ 320, 338 },
				{ 240, 395 },
				{ 170, 465 },
				{ 125, 550 },
				{ 100, 640 },
				{ 82, 730 },
				{ 60, 830 },
				{ 38, 915 },
				{ 22, 1000 },
				{ 18, 1080 },
				{ 22, 1160 },
				{ 30, 1300 },
			}),
			WaterWidth = 56,
			FloodWidth = 14,
			BankWidth = 14,
		},
		{
			Id = "Karasu",
			DisplayName = "Río Karasu",
			Points = points({
				{ 300, 318 },
				{ 360, 380 },
				{ 378, 440 },
				{ 385, 520 },
				{ 380, 610 },
				{ 375, 700 },
				{ 378, 790 },
				{ 372, 870 },
				{ 358, 950 },
				{ 338, 1030 },
				{ 312, 1100 },
				{ 292, 1160 },
				{ 282, 1300 },
			}),
			WaterWidth = 22,
			FloodWidth = 8,
			BankWidth = 12,
		},
	},

	Shoreline = points({
		{ -500, 1225 },
		{ 0, 1232 },
		{ 150, 1222 },
		{ 300, 1215 },
		{ 450, 1228 },
		{ 600, 1210 },
		{ 800, 1205 },
		{ 1000, 1215 },
		{ 1400, 1220 },
	}),

	Railway = points({
		{ -300, 794 },
		{ 0, 798 },
		{ 120, 806 },
		{ 232, 826 },
		{ 330, 852 },
		{ 420, 905 },
		{ 520, 968 },
		{ 640, 1020 },
		{ 760, 1024 },
		{ 870, 1008 },
		{ 990, 1000 },
		{ 1300, 994 },
	}),

	Roads = {
		{
			Id = "Ring",
			DisplayName = "Circunvalación",
			Kind = "Arterial",
			Closed = true,
			Points = {},
		},
		{
			Id = "AvenidaCentral",
			DisplayName = "Avenida central",
			Kind = "Arterial",
			Points = points({
				{ 160, 722 },
				{ 260, 742 },
				{ 340, 760 },
				{ 438, 772 },
				{ 560, 792 },
				{ 680, 800 },
				{ 815, 826 },
			}),
		},
		{
			Id = "AvenidaSur",
			DisplayName = "Avenida sur",
			Kind = "Arterial",
			Points = points({
				{ 100, 900 },
				{ 210, 912 },
				{ 290, 950 },
				{ 420, 960 },
				{ 470, 1000 },
				{ 560, 1060 },
				{ 680, 1075 },
				{ 770, 1070 },
				{ 965, 1090 },
			}),
		},
		{
			Id = "MashibaNorte",
			DisplayName = "Calle Mashiba norte",
			Kind = "Arterial",
			Points = points({ { 662, 652 }, { 760, 628 }, { 870, 604 }, { 969, 600 } }),
		},
		{
			Id = "Tsubakidai",
			DisplayName = "Ronda de Tsubakidai",
			Kind = "Street",
			Closed = true,
			Points = points({
				{ 430, 560 },
				{ 500, 545 },
				{ 560, 552 },
				{ 615, 592 },
				{ 662, 652 },
				{ 600, 670 },
				{ 540, 675 },
				{ 478, 700 },
				{ 438, 735 },
				{ 430, 650 },
			}),
		},
		{
			Id = "HonchouNorte",
			DisplayName = "Calle Honchō norte",
			Kind = "Street",
			Points = points({ { 215, 520 }, { 300, 570 }, { 360, 598 }, { 430, 610 } }),
		},
		{
			Id = "HonchouInterior",
			DisplayName = "Calle Honchō",
			Kind = "Street",
			Points = points({ { 260, 742 }, { 270, 650 }, { 300, 570 } }),
		},
		{
			Id = "Kitakawase",
			DisplayName = "Calle Kitakawase",
			Kind = "Street",
			Points = points({ { 520, 392 }, { 510, 470 }, { 500, 545 } }),
		},
		{
			Id = "YumisawaOeste",
			DisplayName = "Calle Yumisawa oeste",
			Kind = "Street",
			Points = points({ { 600, 338 }, { 668, 400 }, { 738, 470 } }),
		},
		{
			Id = "YumisawaEste",
			DisplayName = "Calle Yumisawa este",
			Kind = "Street",
			Points = points({ { 800, 332 }, { 738, 470 } }),
		},
		{
			Id = "Gakuen",
			DisplayName = "Calle del instituto",
			Kind = "Street",
			Points = points({ { 738, 470 }, { 752, 560 }, { 760, 628 } }),
		},
		{
			Id = "GakuenEste",
			DisplayName = "Calle Gakuenchō este",
			Kind = "Street",
			Points = points({ { 850, 310 }, { 872, 450 }, { 870, 604 } }),
		},
		{
			Id = "Mitsumiya",
			DisplayName = "Calle Mitsumiya",
			Kind = "Street",
			Points = points({ { 760, 628 }, { 798, 720 }, { 815, 826 }, { 966, 800 } }),
		},
		{
			Id = "MitsumiyaEste",
			DisplayName = "Calle Mitsumiya este",
			Kind = "Street",
			Points = points({ { 870, 604 }, { 890, 700 }, { 969, 700 } }),
		},
		{
			Id = "MashibaOeste",
			DisplayName = "Calle Mashiba oeste",
			Kind = "Street",
			Points = points({ { 438, 735 }, { 438, 772 } }),
		},
		{
			Id = "Kasazaki",
			DisplayName = "Calle Kasazaki",
			Kind = "Street",
			Points = points({ { 500, 787 }, { 496, 880 }, { 470, 1000 } }),
		},
		{
			Id = "Sakurabashi",
			DisplayName = "Calle Sakurabashi",
			Kind = "Street",
			Points = points({ { 680, 800 }, { 665, 900 }, { 652, 980 }, { 640, 1068 } }),
		},
		{
			Id = "Komatsu",
			DisplayName = "Calle Komatsu",
			Kind = "Street",
			Points = points({ { 815, 826 }, { 790, 920 }, { 775, 1000 }, { 770, 1070 } }),
		},
		{
			Id = "SakurabashiSur",
			DisplayName = "Calle Sakurabashi sur",
			Kind = "Street",
			Points = points({ { 560, 1060 }, { 565, 1152 } }),
		},
		{
			Id = "KomatsuSur",
			DisplayName = "Calle Komatsu sur",
			Kind = "Street",
			Points = points({ { 770, 1070 }, { 765, 1148 } }),
		},
		{
			Id = "MinamikawaseOeste",
			DisplayName = "Calle Minamikawase",
			Kind = "Street",
			Points = points({ { 210, 912 }, { 215, 1000 }, { 200, 1112 } }),
		},
		{
			Id = "EstacionNorte",
			DisplayName = "Acceso norte a la estación",
			Kind = "Street",
			Points = points({ { 260, 742 }, { 250, 796 } }),
		},
		{
			Id = "EstacionSur",
			DisplayName = "Acceso sur a la estación",
			Kind = "Street",
			Points = points({ { 290, 950 }, { 268, 878 } }),
		},
	},

	Districts = {
		{
			Id = "KarakuraHonchou",
			DisplayName = "Karakura Honchō",
			Kanji = "空座本町",
			Style = "Dense",
			GridAngle = 12,
			Polygon = points({
				{ 215, 520 },
				{ 300, 570 },
				{ 370, 600 },
				{ 372, 770 },
				{ 340, 760 },
				{ 260, 742 },
				{ 160, 722 },
				{ 186, 620 },
			}),
		},
		{
			Id = "Kitakawase",
			DisplayName = "Kitakawase",
			Kanji = "北川瀬",
			Style = "Residential",
			GridAngle = -8,
			Polygon = points({
				{ 380, 440 },
				{ 420, 412 },
				{ 520, 392 },
				{ 600, 338 },
				{ 668, 400 },
				{ 738, 470 },
				{ 752, 560 },
				{ 760, 628 },
				{ 662, 652 },
				{ 615, 592 },
				{ 560, 552 },
				{ 500, 545 },
				{ 430, 560 },
				{ 430, 610 },
				{ 385, 605 },
			}),
		},
		{
			Id = "Yumisawa",
			DisplayName = "Yumisawa",
			Kanji = "弓沢",
			Style = "Residential",
			GridAngle = 3,
			Polygon = points({ { 600, 338 }, { 700, 322 }, { 800, 332 }, { 738, 470 }, { 668, 400 } }),
		},
		{
			Id = "Gakuenchou",
			DisplayName = "Gakuenchō",
			Kanji = "学園町",
			Style = "Residential",
			GridAngle = 5,
			Polygon = points({
				{ 800, 332 },
				{ 850, 310 },
				{ 930, 328 },
				{ 962, 365 },
				{ 968, 500 },
				{ 969, 600 },
				{ 870, 604 },
				{ 760, 628 },
				{ 752, 560 },
				{ 738, 470 },
			}),
		},
		{
			Id = "Tsubakidai",
			DisplayName = "Tsubakidai",
			Kanji = "椿台",
			Style = "Residential",
			GridAngle = -4,
			Polygon = points({
				{ 430, 560 },
				{ 500, 545 },
				{ 560, 552 },
				{ 615, 592 },
				{ 662, 652 },
				{ 600, 670 },
				{ 540, 675 },
				{ 478, 700 },
				{ 438, 735 },
				{ 430, 650 },
			}),
		},
		{
			Id = "Mitsumiya",
			DisplayName = "Mitsumiya",
			Kanji = "三ツ宮",
			Style = "Residential",
			GridAngle = 8,
			Polygon = points({
				{ 760, 628 },
				{ 870, 604 },
				{ 969, 600 },
				{ 966, 800 },
				{ 815, 826 },
				{ 798, 720 },
			}),
		},
		{
			Id = "Mashiba",
			DisplayName = "Mashiba",
			Kanji = "馬芝",
			Style = "Dense",
			GridAngle = -10,
			Polygon = points({
				{ 438, 735 },
				{ 478, 700 },
				{ 540, 675 },
				{ 600, 670 },
				{ 662, 652 },
				{ 760, 628 },
				{ 798, 720 },
				{ 815, 826 },
				{ 680, 800 },
				{ 560, 792 },
				{ 438, 772 },
			}),
		},
		{
			Id = "Kasazaki",
			DisplayName = "Kasazaki",
			Kanji = "笠咲",
			Style = "Dense",
			GridAngle = 22,
			Polygon = points({
				{ 378, 782 },
				{ 438, 772 },
				{ 560, 792 },
				{ 680, 800 },
				{ 665, 900 },
				{ 652, 980 },
				{ 520, 968 },
				{ 420, 905 },
				{ 372, 870 },
			}),
		},
		{
			Id = "Minamikawase",
			DisplayName = "Minamikawase",
			Kanji = "南川瀬",
			Style = "Commercial",
			GridAngle = 10,
			Polygon = points({
				{ 160, 722 },
				{ 260, 742 },
				{ 340, 760 },
				{ 372, 780 },
				{ 372, 870 },
				{ 358, 950 },
				{ 290, 950 },
				{ 210, 912 },
				{ 100, 900 },
				{ 128, 822 },
			}),
		},
		{
			Id = "MinamikawaseSur",
			DisplayName = "Minamikawase",
			Kanji = "南川瀬",
			Style = "Residential",
			GridAngle = -6,
			Polygon = points({
				{ 100, 900 },
				{ 210, 912 },
				{ 290, 950 },
				{ 358, 955 },
				{ 312, 1100 },
				{ 300, 1148 },
				{ 200, 1112 },
				{ 125, 1078 },
				{ 92, 1000 },
			}),
		},
		{
			Id = "Sakurabashi",
			DisplayName = "Sakurabashi",
			Kanji = "桜橋",
			Style = "Residential",
			GridAngle = 18,
			Polygon = points({
				{ 358, 955 },
				{ 420, 960 },
				{ 470, 1000 },
				{ 560, 1060 },
				{ 565, 1152 },
				{ 520, 1156 },
				{ 420, 1172 },
				{ 300, 1148 },
				{ 312, 1100 },
			}),
		},
		{
			Id = "Komatsu",
			DisplayName = "Komatsu",
			Kanji = "黄松",
			Style = "Residential",
			GridAngle = 15,
			Polygon = points({
				{ 520, 968 },
				{ 652, 980 },
				{ 665, 900 },
				{ 680, 800 },
				{ 815, 826 },
				{ 790, 920 },
				{ 775, 1000 },
				{ 770, 1070 },
				{ 680, 1075 },
				{ 560, 1060 },
				{ 470, 1000 },
			}),
		},
		{
			Id = "KomatsuSur",
			DisplayName = "Komatsu",
			Kanji = "黄松",
			Style = "Residential",
			GridAngle = 2,
			Polygon = points({
				{ 560, 1060 },
				{ 680, 1075 },
				{ 770, 1070 },
				{ 765, 1148 },
				{ 640, 1146 },
				{ 565, 1152 },
			}),
		},
		{
			Id = "Kinogaya",
			DisplayName = "Kinogaya",
			Kanji = "貴ノ茅",
			Style = "Residential",
			GridAngle = 6,
			Polygon = points({
				{ 815, 826 },
				{ 966, 800 },
				{ 970, 960 },
				{ 965, 1090 },
				{ 900, 1138 },
				{ 765, 1148 },
				{ 770, 1070 },
				{ 775, 1000 },
				{ 790, 920 },
			}),
		},
	},

	Landmarks = {
		{
			Id = "UraharaShop",
			DisplayName = "Tienda de Urahara",
			Kind = "TrainingShop",
			Position = URAHARA,
			Size = { X = 70, Z = 60 },
			Rotation = 0,
			Sign = "浦原商店",
		},
		{
			Id = "KurosakiClinic",
			DisplayName = "Clínica Kurosaki",
			Kind = "Clinic",
			Position = px(238, 895),
			Size = { X = 30, Z = 26 },
			Rotation = 180,
			Sign = "クロサキ医院",
		},
		{
			Id = "ArisawaHouse",
			DisplayName = "Casa de los Arisawa",
			Kind = "House",
			Position = px(300, 888),
			Size = { X = 26, Z = 24 },
			Rotation = 180,
			Sign = "有沢",
		},
		{
			Id = "FuurinCenter",
			DisplayName = "Centro municipal Fuurin",
			Kind = "Dojo",
			Position = px(320, 690),
			Size = { X = 34, Z = 30 },
			Rotation = 90,
			Sign = "風林会館",
		},
		{
			Id = "OrihimeApartment",
			DisplayName = "Casa de Orihime",
			Kind = "SmallApartment",
			Position = px(500, 1115),
			Size = { X = 34, Z = 28 },
			Rotation = 0,
		},
		{
			Id = "ChadApartment",
			DisplayName = "Casa de Chad",
			Kind = "SmallApartment",
			Position = px(250, 1050),
			Size = { X = 30, Z = 24 },
			Rotation = 90,
		},
		{
			Id = "MatsukuraRuins",
			DisplayName = "Ruinas del Hospital Matsukura",
			Kind = "Ruins",
			Position = MATSUKURA,
			Size = { X = 84, Z = 76 },
			Rotation = 0,
			Sign = "松倉病院",
		},
		{
			Id = "KarakuraHigh",
			DisplayName = "Instituto de Karakura",
			Kind = "HighSchool",
			Position = px(806, 515),
			Size = { X = 110, Z = 120 },
			Rotation = 0,
			Sign = "空座第一高等学校",
		},
		{
			Id = "MashibaSchool",
			DisplayName = "Colegio Mashiba",
			Kind = "School",
			Position = px(570, 860),
			Size = { X = 90, Z = 70 },
			Rotation = 0,
			Sign = "馬芝小学校",
		},
		{
			Id = "GeneralHospital",
			DisplayName = "Hospital General de Karakura",
			Kind = "Hospital",
			Position = px(310, 798),
			Size = { X = 70, Z = 56 },
			Rotation = 0,
			Sign = "空座総合病院",
		},
		{
			Id = "HonchouStation",
			DisplayName = "Estación de Karakura Honchō",
			Kind = "Station",
			Position = px(222, 838),
			Size = { X = 150, Z = 80 },
			Rotation = 0,
			Sign = "空座本町駅",
		},
		{
			Id = "ShoppingCenter",
			DisplayName = "Centro comercial de Karakura",
			Kind = "Mall",
			Position = px(445, 840),
			Size = { X = 70, Z = 60 },
			Rotation = 0,
			Sign = "空座モール",
		},
		{
			Id = "HirohyakuSupermarket",
			DisplayName = "Supermercado Hirohyaku",
			Kind = "Supermarket",
			Position = px(552, 1008),
			Size = { X = 50, Z = 40 },
			Rotation = 0,
			Sign = "ヒロヒャク",
		},
		{
			Id = "MashibaShopStreet",
			DisplayName = "Galería comercial de Mashiba",
			Kind = "ShopStreet",
			Position = px(720, 700),
			Size = { X = 30, Z = 110 },
			Rotation = 0,
			Sign = "馬芝商店街",
		},
		{
			Id = "KitakawaseShrine",
			DisplayName = "Santuario de Kitakawase",
			Kind = "Shrine",
			Position = px(455, 470),
			Size = { X = 40, Z = 50 },
			Rotation = 0,
		},
		{
			Id = "IshidaHouse",
			DisplayName = "Casa de Uryū",
			Kind = "House",
			Position = px(575, 430),
			Size = { X = 28, Z = 26 },
			Rotation = 0,
			Sign = "石田",
		},
		{
			Id = "RacecourseRuins",
			DisplayName = "Restos del edificio de carreras",
			Kind = "RacecourseRuins",
			Position = RACECOURSE,
			Size = { X = 130, Z = 100 },
			Rotation = 0,
		},
	},

	Parks = {
		{
			Id = "TsubakidaiPark",
			DisplayName = "Parque Tsubakidai",
			Kind = "Park",
			Position = TSUBAKIDAI_PARK,
			Size = { X = 100, Z = 100 },
			Rotation = 0,
		},
		{
			Id = "PublicPark",
			DisplayName = "Parque público de Karakura",
			Kind = "Park",
			Position = px(600, 730),
			Size = { X = 90, Z = 60 },
			Rotation = 0,
		},
		{
			Id = "YumisawaPlayground",
			DisplayName = "Parque infantil Yumisawa",
			Kind = "Playground",
			Position = px(713, 378),
			Size = { X = 40, Z = 34 },
			Rotation = 0,
		},
		{
			Id = "KarasuRiverside",
			DisplayName = "Orilla del Karasu",
			Kind = "Riverside",
			Position = RIVERSIDE,
			Size = { X = 120, Z = 100 },
			Rotation = 0,
		},
	},

	Hills = {
		{ Position = px(1120, 230), Radius = 190 },
		{ Position = px(1230, 450), Radius = 160 },
		{ Position = px(-260, 320), Radius = 210 },
		{ Position = px(-330, 700), Radius = 170 },
	},

	Underground = {
		Landmark = "UraharaShop",
		Center = UNDERGROUND_CENTER,
		Size = 240,
		FloorY = -96,
		CeilingY = -36,
	},

	Anchors = {
		-- Aparición de los jugadores: patio de la tienda de Urahara.
		Spawn = anchor(URAHARA, 0, 0, -18),
		TrainingGround = anchor(UNDERGROUND_CENTER, -96),
		TsubakidaiPark = anchor(TSUBAKIDAI_PARK, 0),
		MatsukuraRuins = anchor(MATSUKURA, 0, 0, -22),
		RacecourseRuins = anchor(RACECOURSE, 0, 0, -10),
		KarasuRiverside = anchor(RIVERSIDE, 0),
	},
}

-- La circunvalación sigue el límite del pueblo.
Karakura.Roads[1].Points = Karakura.TownBoundary

return Karakura
