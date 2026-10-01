--!strict

-- Contrato entre el generador del mapa (tools/worldgen) y el cliente (D-043):
-- etiquetas de CollectionService y atributos que pone el generador en las
-- piezas del mapa, y que EnvironmentController anima (luces de noche,
-- semáforos, pasos a nivel, relojes...).
--
-- Sin require ni `game`: también lo lee Lune.

local WorldTags = {
	-- Ventana: de noche se ilumina si su atributo Lit es true.
	Window = "MapWindow",
	-- PointLight / SurfaceLight / SpotLight que solo se enciende de noche.
	NightLight = "MapNightLight",
	-- Pieza que de noche pasa a Neon (farolas, letreros, linternas).
	NightNeon = "MapNightNeon",
	-- Cabeza de semáforo con hijos Red, Yellow y Green; atributo Axis (0 o 1).
	TrafficLight = "MapTrafficLight",
	-- Luces de un paso a nivel (hijos Left y Right) y barreras (se giran).
	CrossingSignal = "MapCrossingSignal",
	CrossingGate = "MapCrossingGate",
	-- Pieza con un SurfaceGui cuyo TextLabel muestra la hora del juego.
	Clock = "MapClock",
	-- Luz que parpadea (ruinas).
	Flicker = "MapFlicker",
	-- Luz roja de balizamiento de azoteas (parpadeo lento de noche).
	Beacon = "MapBeacon",
	-- Agua provisional: el servidor la cambia por agua de Terrain al arrancar.
	Water = "MapWater",
}

-- Atributos.
WorldTags.Attributes = {
	-- Ventanas: si se enciende de noche.
	Lit = "Lit",
	-- Semáforos: los del eje 0 y el eje 1 van en fases opuestas.
	Axis = "Axis",
	-- Barreras de paso a nivel: giro (grados) al bajar.
	GateAngle = "GateAngle",
	-- Barreras y señales: punto del paso a nivel (distancia sobre la vía).
	RailDistance = "RailDistance",
}

return WorldTags
