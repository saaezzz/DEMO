--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local ServiceLoader = require(ReplicatedStorage.Shared.Utils.ServiceLoader)

local PlayerDataController = require(script.Controllers.PlayerDataController)
local InputController = require(script.Controllers.InputController)
local MovementController = require(script.Controllers.MovementController)
local CombatController = require(script.Controllers.CombatController)
local HudController = require(script.Controllers.HudController)
local NameplateController = require(script.Controllers.NameplateController)
local HitFeedbackController = require(script.Controllers.HitFeedbackController)
local NotificationController = require(script.Controllers.NotificationController)
local QuestTrackerController = require(script.Controllers.QuestTrackerController)
local ActionBarController = require(script.Controllers.ActionBarController)
local LockOnController = require(script.Controllers.LockOnController)
local TargetFrameController = require(script.Controllers.TargetFrameController)
local VfxController = require(script.Controllers.VfxController)
local InventoryController = require(script.Controllers.InventoryController)
local RaceSelectionController = require(script.Controllers.RaceSelectionController)
local CharacterAnimationController = require(script.Controllers.CharacterAnimationController)

Logger.SetLevel(if RunService:IsStudio() then "Debug" else "Info")

ServiceLoader.Run({
	PlayerDataController,
	InputController,
	MovementController,
	CombatController,
	HudController,
	NameplateController,
	HitFeedbackController,
	NotificationController,
	QuestTrackerController,
	ActionBarController,
	LockOnController,
	TargetFrameController,
	VfxController,
	InventoryController,
	RaceSelectionController,
	CharacterAnimationController,
})

Logger.new("Client"):Info("Controladores iniciados")
