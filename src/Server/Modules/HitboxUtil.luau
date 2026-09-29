--!strict

local Workspace = game:GetService("Workspace")

local GameTypes = require(game:GetService("ReplicatedStorage").Shared.Types.GameTypes)

type HitboxDefinition = GameTypes.HitboxDefinition

export type HitboxTarget = {
	Model: Model,
	Humanoid: Humanoid,
	Distance: number,
}

local function resolveTargetModel(part: BasePart, origin: Vector3, seen: { [Model]: boolean }): HitboxTarget?
	local model = part:FindFirstAncestorOfClass("Model")
	if model == nil or seen[model] then
		return nil
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return nil
	end

	seen[model] = true

	local rootPart = model.PrimaryPart or part
	return {
		Model = model,
		Humanoid = humanoid,
		Distance = (rootPart.Position - origin).Magnitude,
	}
end

local function sortByDistance(targets: { HitboxTarget })
	table.sort(targets, function(a, b)
		return a.Distance < b.Distance
	end)
end

local function trimToMax(targets: { HitboxTarget }, maxTargets: number): { HitboxTarget }
	if maxTargets <= 0 or #targets <= maxTargets then
		return targets
	end

	local trimmed = table.create(maxTargets)
	for index = 1, maxTargets do
		trimmed[index] = targets[index]
	end
	return trimmed
end

local HitboxUtil = {}

function HitboxUtil.BuildOverlapParams(ignoreList: { Instance }): OverlapParams
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.RespectCanCollide = false
	return params
end

function HitboxUtil.FindTargetsInBox(cframe: CFrame, size: Vector3, params: OverlapParams, maxTargets: number): { HitboxTarget }
	local parts = Workspace:GetPartBoundsInBox(cframe, size, params)

	local seen: { [Model]: boolean } = {}
	local targets: { HitboxTarget } = {}

	for _, part in ipairs(parts) do
		local target = resolveTargetModel(part, cframe.Position, seen)
		if target ~= nil then
			table.insert(targets, target)
		end
	end

	sortByDistance(targets)
	return trimToMax(targets, maxTargets)
end

function HitboxUtil.FindTargetsInRadius(position: Vector3, radius: number, params: OverlapParams, maxTargets: number): { HitboxTarget }
	local parts = Workspace:GetPartBoundsInRadius(position, radius, params)

	local seen: { [Model]: boolean } = {}
	local targets: { HitboxTarget } = {}

	for _, part in ipairs(parts) do
		local target = resolveTargetModel(part, position, seen)
		if target ~= nil then
			table.insert(targets, target)
		end
	end

	sortByDistance(targets)
	return trimToMax(targets, maxTargets)
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
