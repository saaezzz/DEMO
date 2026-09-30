--!strict

-- Objetivos válidos de una hitbox (§17 HitboxService): consulta espacial desde
-- la posición actual del atacante y validación de cada objetivo (registrado,
-- vivo y hostil).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameTypes = require(ReplicatedStorage.Shared.Types.GameTypes)
local CombatRegistry = require(script.Parent.CombatRegistry)
local HitboxUtil = require(script.Parent.HitboxUtil)

type HitboxDefinition = GameTypes.HitboxDefinition
type CombatEntity = CombatRegistry.CombatEntity

local HitboxService = {}

-- Ordenados por distancia; como mucho hitbox.MaxTargets (0 = sin límite).
function HitboxService.FindTargets(attacker: CombatEntity, hitbox: HitboxDefinition): { CombatEntity }
	local params = HitboxUtil.BuildOverlapParams({ attacker.Model })
	-- El límite se aplica tras filtrar: un aliado cercano no ocupa el hueco de un enemigo.
	local unlimited = table.clone(hitbox)
	unlimited.MaxTargets = 0

	local targets: { CombatEntity } = {}
	for _, target in HitboxUtil.FindTargets(unlimited, attacker.RootPart.CFrame, params) do
		local entity = CombatRegistry.Get(target.Model)
		if entity ~= nil and entity.Character:IsAlive() and CombatRegistry.AreHostile(attacker, entity) then
			table.insert(targets, entity)
			if hitbox.MaxTargets > 0 and #targets >= hitbox.MaxTargets then
				break
			end
		end
	end
	return targets
end

return HitboxService
