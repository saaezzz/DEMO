--!strict

local CombatController = require(script.Controllers.CombatController)

CombatController:Init()

CombatController:OnComboHitMarker(function(comboId: string, markerName: string)
	print(string.format("[Client] Marca de combo alcanzada: %s -> %s", comboId, markerName))
end)

print("[Client] Demo_RPG combat bootstrap listo.")
