--!strict

local Workspace = game:GetService("Workspace")

local GameTypes = require(game:GetService("ReplicatedStorage").Shared.Types.GameTypes)

type HitboxDefinition = GameTypes.HitboxDefinition

export type HitboxTarget = {
	Model: Model,
	Distance: number,
}

-- Busca el primer Model ancestro con un Humanoid vivo. Recorre toda la cadena
-- porque la pieza puede pertenecer a un sub-modelo del personaje (arma, accesorio).
local function findCharacterModel(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	while model ~= nil do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			return if humanoid.Health > 0 then model else nil
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- Agrupa las piezas por personaje, ordena por distancia al origen y recorta a
-- maxTargets (0 = sin límite).
local function collectTargets(parts: { BasePart }, origin: Vector3, maxTargets: number): { HitboxTarget }
	local seen: { [Model]: boolean } = {}
	local targets: { HitboxTarget } = {}

	for _, part in parts do
		local model = findCharacterModel(part)
		if model ~= nil and not seen[model] then
			seen[model] = true
			local rootPart = model.PrimaryPart or part
			table.insert(targets, {
				Model = model,
				Distance = (rootPart.Position - origin).Magnitude,
			})
		end
	end

	table.sort(targets, function(a, b)
		return a.Distance < b.Distance
	end)

	if maxTargets > 0 and #targets > maxTargets then
		return table.move(targets, 1, maxTargets, 1, {})
	end
	return targets
end

local HitboxUtil = {}

function HitboxUtil.BuildOverlapParams(ignoreList: { Instance }): OverlapParams
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.RespectCanCollide = false
	return params
end

function HitboxUtil.FindTargetsInBox(
	cframe: CFrame,
	size: Vector3,
	params: OverlapParams,
	maxTargets: number
): { HitboxTarget }
	local parts = Workspace:GetPartBoundsInBox(cframe, size, params)
	return collectTargets(parts, cframe.Position, maxTargets)
end

function HitboxUtil.FindTargetsInRadius(
	position: Vector3,
	radius: number,
	params: OverlapParams,
	maxTargets: number
): { HitboxTarget }
	local parts = Workspace:GetPartBoundsInRadius(position, radius, params)
	return collectTargets(parts, position, maxTargets)
end

-- No existe una query nativa de cilindro en el motor de físicas: se aproxima
-- con una búsqueda esférica sobre el radio mayor del cilindro (size.X/2, size.Z/2).
function HitboxUtil.FindTargets(hitbox: HitboxDefinition, originCFrame: CFrame, params: OverlapParams): { HitboxTarget }
	local worldCFrame = originCFrame * hitbox.Offset

	if hitbox.Shape == "Box" then
		return HitboxUtil.FindTargetsInBox(worldCFrame, hitbox.Size, params, hitbox.MaxTargets)
	elseif hitbox.Shape == "Sphere" then
		local radius = math.max(hitbox.Size.X, hitbox.Size.Y, hitbox.Size.Z) * 0.5
		return HitboxUtil.FindTargetsInRadius(worldCFrame.Position, radius, params, hitbox.MaxTargets)
	else
		local radius = math.max(hitbox.Size.X, hitbox.Size.Z) * 0.5
		return HitboxUtil.FindTargetsInRadius(worldCFrame.Position, radius, params, hitbox.MaxTargets)
	end
end

return HitboxUtil
