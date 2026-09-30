local QuestLogic = require(game:GetService("ServerScriptService").Server.Modules.QuestLogic)

local DEFINITIONS = {
	Hunt = {
		Id = "Hunt",
		Title = "",
		Type = "Hunt",
		Description = "",
		Objectives = {
			{ Kind = "Kill", Target = "Wolf", Count = 2, Description = "" },
			{ Kind = "Kill", Target = "Bear", Count = 1, Description = "" },
		},
		Rewards = { Experience = 10 },
	},
	Other = {
		Id = "Other",
		Title = "",
		Type = "Hunt",
		Description = "",
		Objectives = { { Kind = "Kill", Target = "Wolf", Count = 1, Description = "" } },
		Rewards = { Experience = 5 },
	},
}

local function empty()
	return { Active = {}, Completed = {} }
end

return {
	["Start añade la misión con el progreso a 0 sin tocar el original"] = function()
		local data = empty()
		local result = QuestLogic.Start(data, "Hunt", DEFINITIONS)
		expect(result.Active).toEqual({ { Id = "Hunt", Progress = { 0, 0 } } })
		expect(#data.Active).toBe(0)
	end,

	["Start rechaza misiones desconocidas, en curso o completadas"] = function()
		expect(QuestLogic.Start(empty(), "Nope", DEFINITIONS)).toBeNil()
		local started = QuestLogic.Start(empty(), "Hunt", DEFINITIONS)
		expect(QuestLogic.Start(started, "Hunt", DEFINITIONS)).toBeNil()
		expect(QuestLogic.Start({ Active = {}, Completed = { Hunt = true } }, "Hunt", DEFINITIONS)).toBeNil()
	end,

	["RecordKill avanza solo los objetivos de ese enemigo"] = function()
		local data = QuestLogic.Start(empty(), "Hunt", DEFINITIONS)
		local result, completed = QuestLogic.RecordKill(data, "Wolf", DEFINITIONS)
		expect(result.Active[1].Progress).toEqual({ 1, 0 })
		expect(#completed).toBe(0)
		expect(data.Active[1].Progress).toEqual({ 0, 0 })
	end,

	["un objetivo no pasa de su cantidad"] = function()
		local data = QuestLogic.Start(empty(), "Hunt", DEFINITIONS)
		for _ = 1, 5 do
			data = QuestLogic.RecordKill(data, "Wolf", DEFINITIONS)
		end
		expect(data.Active[1].Progress).toEqual({ 2, 0 })
	end,

	["al cumplir todos los objetivos la misión se completa"] = function()
		local data = QuestLogic.Start(empty(), "Hunt", DEFINITIONS)
		data = QuestLogic.RecordKill(data, "Wolf", DEFINITIONS)
		data = QuestLogic.RecordKill(data, "Wolf", DEFINITIONS)
		local result, completed = QuestLogic.RecordKill(data, "Bear", DEFINITIONS)
		expect(completed).toEqual({ "Hunt" })
		expect(#result.Active).toBe(0)
		expect(result.Completed.Hunt).toBe(true)
	end,

	["una baja cuenta para todas las misiones activas que la necesiten"] = function()
		local data = QuestLogic.Start(empty(), "Hunt", DEFINITIONS)
		data = QuestLogic.Start(data, "Other", DEFINITIONS)
		local result, completed = QuestLogic.RecordKill(data, "Wolf", DEFINITIONS)
		expect(completed).toEqual({ "Other" })
		expect(result.Active).toEqual({ { Id = "Hunt", Progress = { 1, 0 } } })
	end,

	["una misión retirada del contenido se conserva"] = function()
		local data = { Active = { { Id = "Removed", Progress = { 3 } } }, Completed = {} }
		local result = QuestLogic.RecordKill(data, "Wolf", DEFINITIONS)
		expect(result.Active).toEqual({ { Id = "Removed", Progress = { 3 } } })
	end,
}
