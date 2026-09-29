--!strict

-- Logger con niveles y ámbito por módulo. Luau puro (salida inyectable).
--
--   local log = Logger.new("CombatService")
--   log:Info("Combo %s registrado", combo.Id)
--
-- El nivel mínimo es global. Los bootstraps lo fijan (Debug en Studio, Info en
-- servidores publicados).

export type LogLevel = "Debug" | "Info" | "Warn" | "Error"
export type Sink = (level: LogLevel, message: string) -> ()

local LEVEL_PRIORITY: { [LogLevel]: number } = {
	Debug = 1,
	Info = 2,
	Warn = 3,
	Error = 4,
}

local function defaultSink(level: LogLevel, message: string): ()
	if level == "Warn" or level == "Error" then
		warn(message)
	else
		print(message)
	end
end

local minimumLevel: LogLevel = "Info"
local sink: Sink = defaultSink

local Logger = {}
Logger.__index = Logger

type LoggerData = {
	_scope: string,
}

export type Logger = typeof(setmetatable({} :: LoggerData, Logger))

function Logger.new(scope: string): Logger
	return setmetatable({ _scope = scope }, Logger)
end

function Logger.SetLevel(level: LogLevel): ()
	minimumLevel = level
end

function Logger.GetLevel(): LogLevel
	return minimumLevel
end

-- nil restaura la salida por defecto (print/warn).
function Logger.SetSink(newSink: Sink?): ()
	sink = newSink or defaultSink
end

-- Solo se aplica string.format si hay argumentos, para que los mensajes sin
-- formato puedan contener "%" sin escaparlo.
local function emit(self: Logger, level: LogLevel, template: string, ...: any): ()
	if LEVEL_PRIORITY[level] < LEVEL_PRIORITY[minimumLevel] then
		return
	end

	local message = if select("#", ...) > 0 then string.format(template, ...) else template
	sink(level, string.format("[%s][%s] %s", level, self._scope, message))
end

function Logger.Debug(self: Logger, template: string, ...: any): ()
	emit(self, "Debug", template, ...)
end

function Logger.Info(self: Logger, template: string, ...: any): ()
	emit(self, "Info", template, ...)
end

function Logger.Warn(self: Logger, template: string, ...: any): ()
	emit(self, "Warn", template, ...)
end

function Logger.Error(self: Logger, template: string, ...: any): ()
	emit(self, "Error", template, ...)
end

return Logger
