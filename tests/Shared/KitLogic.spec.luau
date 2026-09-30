local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitLogic = require(ReplicatedStorage.Shared.Modules.KitLogic)

local MOVESET = {
	LightAttack = { "L1" },
	HeavyAttack = "H",
	Dodge = "D",
	Dash = "M",
	Skills = { "S1", "S2" },
}

local RACE = {
	Id = "R",
	DisplayName = "R",
	Description = "",
	Playable = true,
	Resources = {},
	Kit = { Moveset = "M", StartingItems = {} },
	Milestones = {
		{
			Id = "First",
			DisplayName = "First",
			Description = "",
			RequiredLevel = 2,
			RequiredStats = { Kills = 3 },
			UnlockSkills = { "S3" },
		},
		{
			Id = "Second",
			DisplayName = "Second",
			Description = "",
			RequiredLevel = 5,
			RequiredStats = { Kills = 10 },
			UnlockSkills = { "S4", "S5" },
		},
	},
}

return {
	["GetSkills: sin hitos, solo las técnicas del moveset"] = function()
		expect(KitLogic.GetSkills(RACE, MOVESET, {})).toEqual({ "S1", "S2" })
		expect(KitLogic.GetSkills(nil, MOVESET, { "First" })).toEqual({ "S1", "S2" })
	end,

	["GetSkills: añade las de los hitos alcanzados, hasta 4 casillas"] = function()
		expect(KitLogic.GetSkills(RACE, MOVESET, { "First" })).toEqual({ "S1", "S2", "S3" })
		expect(KitLogic.GetSkills(RACE, MOVESET, { "First", "Second" })).toEqual({ "S1", "S2", "S3", "S4" })
	end,

	["GetSkills: no modifica el moveset"] = function()
		KitLogic.GetSkills(RACE, MOVESET, { "First" })
		expect(#MOVESET.Skills).toBe(2)
	end,

	["MeetsMilestone: hacen falta el nivel y cada estadística"] = function()
		local milestone = RACE.Milestones[1]
		expect(KitLogic.MeetsMilestone(milestone, 2, { Kills = 3 })).toBe(true)
		expect(KitLogic.MeetsMilestone(milestone, 1, { Kills = 99 })).toBe(false)
		expect(KitLogic.MeetsMilestone(milestone, 9, { Kills = 2 })).toBe(false)
		expect(KitLogic.MeetsMilestone(milestone, 9, {})).toBe(false)
	end,

	["NewMilestones: solo los cumplidos y no alcanzados, en orden"] = function()
		local stats = { Kills = 10 }
		local all = KitLogic.NewMilestones(RACE, 5, stats, {})
		expect(#all).toBe(2)
		expect(all[1].Id).toBe("First")
		local rest = KitLogic.NewMilestones(RACE, 5, stats, { "First" })
		expect(#rest).toBe(1)
		expect(rest[1].Id).toBe("Second")
		expect(#KitLogic.NewMilestones(RACE, 1, stats, {})).toBe(0)
	end,

	["NextMilestone: el primero sin alcanzar, o nil"] = function()
		expect(KitLogic.NextMilestone(RACE, {}).Id).toBe("First")
		expect(KitLogic.NextMilestone(RACE, { "First" }).Id).toBe("Second")
		expect(KitLogic.NextMilestone(RACE, { "First", "Second" })).toBeNil()
	end,
}
