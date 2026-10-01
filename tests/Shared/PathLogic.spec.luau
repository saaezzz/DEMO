local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PathLogic = require(ReplicatedStorage.Shared.Modules.PathLogic)

local function near(a, b)
	return math.abs(a - b) < 1e-6
end

local L_PATH = { { X = 0, Z = 0 }, { X = 10, Z = 0 }, { X = 10, Z = 10 } }

return {
	["Length suma los tramos"] = function()
		expect(PathLogic.Length(L_PATH)).toBe(20)
	end,

	["PointAt: punto y dirección del tramo; fuera de rango se queda en el extremo"] = function()
		local p, direction = PathLogic.PointAt(L_PATH, 15)
		expect(near(p.X, 10) and near(p.Z, 5)).toBe(true)
		expect(near(direction.X, 0) and near(direction.Z, 1)).toBe(true)
		local start = PathLogic.PointAt(L_PATH, -5)
		expect(near(start.X, 0)).toBe(true)
		local finish = PathLogic.PointAt(L_PATH, 99)
		expect(near(finish.X, 10) and near(finish.Z, 10)).toBe(true)
	end,

	["ProjectDistance: distancia sobre el camino del punto más cercano"] = function()
		expect(near(PathLogic.ProjectDistance(L_PATH, { X = 4, Z = -3 }), 4)).toBe(true)
		expect(near(PathLogic.ProjectDistance(L_PATH, { X = 14, Z = 7 }), 17)).toBe(true)
	end,

	["Smooth pasa por todos los puntos originales y conserva los extremos"] = function()
		local points = { { X = 0, Z = 0 }, { X = 20, Z = 5 }, { X = 40, Z = -5 }, { X = 60, Z = 0 } }
		local smooth = PathLogic.Smooth(points, 4)
		expect(#smooth > #points).toBe(true)
		for _, original in points do
			local found = false
			for _, p in smooth do
				if near(p.X, original.X) and near(p.Z, original.Z) then
					found = true
				end
			end
			expect(found).toBe(true)
		end
		expect(smooth[#smooth].X).toBe(60)
	end,

	["Smooth con menos de tres puntos devuelve una copia"] = function()
		local points = { { X = 0, Z = 0 }, { X = 1, Z = 1 } }
		local smooth = PathLogic.Smooth(points, 1)
		expect(#smooth).toBe(2)
		expect(smooth ~= points).toBe(true)
	end,
}
