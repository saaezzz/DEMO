--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local ServiceLoader = require(ReplicatedStorage.Shared.Utils.ServiceLoader)

local ServerNetwork = require(script.Network.ServerNetwork)
local DataService = require(script.Services.DataService)
local AbilityService = require(script.Services.AbilityService)
local MovementService = require(script.Services.MovementService)
local ResourceService = require(script.Services.ResourceService)
local CombatService = require(script.Services.CombatService)
local CharacterService = require(script.Services.CharacterService)
local ProgressionService = require(script.Services.ProgressionService)
local QuestService = require(script.Services.QuestService)
local TrainingService = require(script.Services.TrainingService)
local EnemyService = require(script.Services.EnemyService)

Logger.SetLevel(if RunService:IsStudio() then "Debug" else "Info")

-- Orden explícito: un servicio va después de aquellos de los que depende.
ServiceLoader.Run({
	ServerNetwork,
	DataService,
	AbilityService,
	MovementService,
	ResourceService,
	CombatService,
	CharacterService,
	ProgressionService,
	QuestService,
	TrainingService,
	EnemyService,
})

Logger.new("Server"):Info("Servicios iniciados")
