--!strict

-- Tren de cercanías (D-044). Solo existe en el cliente y no choca: es
-- ambiente. Su posición sale de la hora del servidor, así que todos los
-- jugadores lo ven en el mismo sitio sin tráfico de red. Va de un extremo de
-- la vía al otro, para en la estación, espera y vuelve. Mientras pasa, los
-- pasos a nivel parpadean y bajan las barreras.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PathLogic = require(ReplicatedStorage.Shared.Modules.PathLogic)
local WorldMap = require(ReplicatedStorage.Shared.Modules.WorldMap)
local WorldTags = require(ReplicatedStorage.Shared.Config.WorldTags)

-- Debe coincidir con el suavizado de la vía en el generador (Context: Rail).
local PATH_STEP = 8
local SPEED = 55
local STATION_STOP_SECONDS = 9
local END_WAIT_SECONDS = 25
local CAR_COUNT = 4
local CAR_LENGTH = 38
local CAR_GAP = 1.5
local CAR_WIDTH = 10
local CAR_HEIGHT = 10
local FLOOR_Y = 1.4
-- Los pasos a nivel se activan con el tren a esta distancia.
local CROSSING_REACH = 90
local GATE_SECONDS = 1.2

local path: { PathLogic.Point } = {}
local pathLength = 0
local stationDistance = 0
local cycleSeconds = 0
local travelSeconds = 0
local cars: { Model } = {}
-- Progreso de cada barrera (0 = arriba, 1 = abajo).
local gateProgress: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = name == "Body"
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

local function buildCar(index: number, folder: Instance): Model
	local model = Instance.new("Model")
	model.Name = "TrainCar" .. index
	local body = part(
		model,
		"Body",
		Vector3.new(CAR_WIDTH, CAR_HEIGHT, CAR_LENGTH),
		CFrame.identity,
		Color3.fromRGB(232, 234, 236),
		Enum.Material.SmoothPlastic
	)
	model.PrimaryPart = body
	part(
		model,
		"Stripe",
		Vector3.new(CAR_WIDTH + 0.1, 1.1, CAR_LENGTH + 0.1),
		CFrame.new(0, -2.4, 0),
		Color3.fromRGB(235, 120, 40),
		Enum.Material.SmoothPlastic
	)
	local windows = part(
		model,
		"Windows",
		Vector3.new(CAR_WIDTH + 0.12, 2.8, CAR_LENGTH - 4),
		CFrame.new(0, 1.3, 0),
		Color3.fromRGB(90, 110, 125),
		Enum.Material.Glass
	)
	windows:SetAttribute(WorldTags.Attributes.Lit, true)
	CollectionService:AddTag(windows, WorldTags.Window)
	part(
		model,
		"Roof",
		Vector3.new(CAR_WIDTH - 1, 0.8, CAR_LENGTH - 1),
		CFrame.new(0, CAR_HEIGHT / 2 + 0.4, 0),
		Color3.fromRGB(150, 155, 160),
		Enum.Material.Metal
	)
	for _, z in { -CAR_LENGTH / 3, CAR_LENGTH / 3 } do
		part(
			model,
			"Bogie",
			Vector3.new(CAR_WIDTH - 2, 1.4, 6),
			CFrame.new(0, -CAR_HEIGHT / 2 - 0.3, z),
			Color3.fromRGB(40, 40, 42),
			Enum.Material.Metal
		)
	end
	-- Faros en los dos testeros (el que va delante depende del sentido).
	for _, sign in { -1, 1 } do
		local lamp = part(
			model,
			"Headlight",
			Vector3.new(4, 0.8, 0.2),
			CFrame.new(0, -1, sign * (CAR_LENGTH / 2 + 0.05)),
			Color3.fromRGB(255, 244, 214),
			Enum.Material.SmoothPlastic
		)
		CollectionService:AddTag(lamp, WorldTags.NightNeon)
	end
	model.Parent = folder
	return model
end

local TRAIN_LENGTH = CAR_COUNT * (CAR_LENGTH + CAR_GAP)

-- Distancia recorrida (del centro del tren) a los `elapsed` segundos de una
-- pasada que empieza en 0, para en `stop` y acaba en `span`.
local function legDistance(elapsed: number, stop: number, span: number): number
	local toStop = stop / SPEED
	if elapsed < toStop then
		return elapsed * SPEED
	elseif elapsed < toStop + STATION_STOP_SECONDS then
		return stop
	end
	return math.min(stop + (elapsed - toStop - STATION_STOP_SECONDS) * SPEED, span)
end

-- Centro del tren sobre la vía y sentido (+1 ida, -1 vuelta) en el instante `t`.
local function trainAt(t: number): (number, number)
	local span = pathLength - TRAIN_LENGTH
	local legSeconds = travelSeconds + STATION_STOP_SECONDS
	local halfCycle = legSeconds + END_WAIT_SECONDS
	local phase = t % cycleSeconds
	local outbound = phase < halfCycle
	local elapsed = math.min(if outbound then phase else phase - halfCycle, legSeconds)
	local stop = math.clamp(stationDistance - TRAIN_LENGTH / 2, 0, span)
	if outbound then
		return TRAIN_LENGTH / 2 + legDistance(elapsed, stop, span), 1
	end
	return pathLength - TRAIN_LENGTH / 2 - legDistance(elapsed, span - stop, span), -1
end

-- Coloca los vagones alrededor de `center`; devuelve el tramo de vía que ocupan.
local function placeCars(center: number, direction: number): (number, number)
	for index, car in cars do
		local carCenter = center + direction * (TRAIN_LENGTH / 2 - (index - 0.5) * (CAR_LENGTH + CAR_GAP))
		local a = PathLogic.PointAt(path, carCenter + direction * CAR_LENGTH / 3)
		local b = PathLogic.PointAt(path, carCenter - direction * CAR_LENGTH / 3)
		local mid = Vector3.new((a.X + b.X) / 2, FLOOR_Y + CAR_HEIGHT / 2, (a.Z + b.Z) / 2)
		local look = Vector3.new(a.X - b.X, 0, a.Z - b.Z)
		if look.Magnitude > 1e-3 then
			car:PivotTo(CFrame.lookAt(mid, mid + look))
		end
	end
	return center - TRAIN_LENGTH / 2, center + TRAIN_LENGTH / 2
end

local function updateCrossings(low: number, high: number, now: number, deltaTime: number): ()
	local function active(instance: Instance): boolean
		local at = instance:GetAttribute(WorldTags.Attributes.RailDistance)
		return typeof(at) == "number" and at > low - CROSSING_REACH and at < high + CROSSING_REACH
	end
	local blink = math.floor(now * 2) % 2 == 0
	for _, signal in CollectionService:GetTagged(WorldTags.CrossingSignal) do
		local on = active(signal)
		for name, lit in { Left = blink, Right = not blink } do
			local lamp = signal:FindFirstChild(name)
			if lamp ~= nil and lamp:IsA("BasePart") then
				local glowing = on and lit
				lamp.Material = if glowing then Enum.Material.Neon else Enum.Material.SmoothPlastic
				lamp.Color = if glowing then Color3.fromRGB(255, 40, 30) else Color3.fromRGB(74, 16, 16)
			end
		end
	end
	for _, gate in CollectionService:GetTagged(WorldTags.CrossingGate) do
		local pivot = gate:GetAttribute("Pivot")
		local angle = gate:GetAttribute(WorldTags.Attributes.GateAngle)
		if gate:IsA("BasePart") and typeof(pivot) == "CFrame" and typeof(angle) == "number" then
			local target = if active(gate) then 1 else 0
			local current = gateProgress[gate] or 0
			local step = deltaTime / GATE_SECONDS
			current = if current < target then math.min(current + step, target) else math.max(current - step, target)
			if current ~= gateProgress[gate] then
				gateProgress[gate] = current
				gate.CFrame = pivot * CFrame.Angles(0, 0, math.rad(angle * current)) * CFrame.new(0, gate.Size.Y / 2, 0)
			end
		end
	end
end

local TrainController = {
	Name = "TrainController",
}

function TrainController:Start(): ()
	path = PathLogic.Smooth(WorldMap.Railway(), PATH_STEP)
	pathLength = PathLogic.Length(path)
	local station = WorldMap.FindLandmark("Station")
	stationDistance = if station ~= nil
		then PathLogic.ProjectDistance(path, { X = station.X, Z = station.Z })
		else pathLength / 2
	travelSeconds = (pathLength - TRAIN_LENGTH) / SPEED
	cycleSeconds = 2 * (travelSeconds + STATION_STOP_SECONDS + END_WAIT_SECONDS)

	local folder = Instance.new("Folder")
	folder.Name = "Train"
	folder.Parent = Workspace
	for index = 1, CAR_COUNT do
		table.insert(cars, buildCar(index, folder))
	end

	RunService.Heartbeat:Connect(function(deltaTime)
		local now = Workspace:GetServerTimeNow()
		local center, direction = trainAt(now)
		local low, high = placeCars(center, direction)
		updateCrossings(low, high, now, deltaTime)
	end)
end

return TrainController
