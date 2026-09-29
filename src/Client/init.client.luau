--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local ServiceLoader = require(ReplicatedStorage.Shared.Utils.ServiceLoader)

local PlayerDataController = require(script.Controllers.PlayerDataController)
local InputController = require(script.Controllers.InputController)
local CombatController = require(script.Controllers.CombatController)

Logger.SetLevel(if RunService:IsStudio() then "Debug" else "Info")

ServiceLoader.Run({
	PlayerDataController,
	InputController,
	CombatController,
})

Logger.new("Client"):Info("Controladores iniciados")
