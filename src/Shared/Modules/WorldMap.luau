--!strict

-- Acceso del juego a los datos del mapa activo (D-043): puntos con nombre
-- (Anchors) para colocar enemigos, muñecos, zonas y marcadores de misión sin
-- copiar coordenadas. Si el mapa cambia, todo se mueve con él.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.Content.World)

local WorldMap = {}

-- Posición del anchor `name` más un desplazamiento opcional. Falla si no
-- existe (un error de contenido debe verse al arrancar).
function WorldMap.Anchor(name: string, offset: Vector3?): Vector3
	local anchor = World.Anchors[name]
	assert(anchor ~= nil, `[WorldMap] el mapa {World.Name} no tiene el anchor "{name}"`)
	return Vector3.new(anchor.X, anchor.Y, anchor.Z) + (offset or Vector3.zero)
end

function WorldMap.HasAnchor(name: string): boolean
	return World.Anchors[name] ~= nil
end

-- Vía del tren (puntos del mapa, sin suavizar).
function WorldMap.Railway(): { { X: number, Z: number } }
	return World.Railway
end

-- Posición en el suelo del primer lugar de un tipo (p. ej. "Station").
function WorldMap.FindLandmark(kind: string): Vector3?
	for _, landmark in World.Landmarks do
		if landmark.Kind == kind then
			return Vector3.new(landmark.Position.X, 0, landmark.Position.Z)
		end
	end
	return nil
end

return WorldMap
