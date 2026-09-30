--!strict

-- Tareas diferidas de un personaje (golpes, fin de habilidad, salida de un
-- aturdimiento), agrupadas para poder cancelarlas juntas.

local TaskScheduler = {}
TaskScheduler.__index = TaskScheduler

type TaskSchedulerData = {
	-- Hilo → grupo al que pertenece.
	_tasks: { [thread]: string },
	_destroyed: boolean,
}

export type TaskScheduler = typeof(setmetatable({} :: TaskSchedulerData, TaskScheduler))

-- Solo se cancelan hilos suspendidos: una tarea puede provocar su propia
-- cancelación (p. ej. un golpe que recibe parry cancela el ataque en curso).
local function cancelThread(thread: thread): ()
	if coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
end

function TaskScheduler.new(): TaskScheduler
	return setmetatable({
		_tasks = {},
		_destroyed = false,
	}, TaskScheduler)
end

-- La tarea sale de la lista al ejecutarse, así que la lista no crece sin límite.
function TaskScheduler.Schedule(self: TaskScheduler, group: string, delaySeconds: number, callback: () -> ()): thread?
	if self._destroyed then
		return nil
	end
	local thread: thread
	thread = task.delay(delaySeconds, function()
		self._tasks[thread] = nil
		callback()
	end)
	self._tasks[thread] = group
	return thread
end

function TaskScheduler.CancelGroup(self: TaskScheduler, group: string): ()
	for thread, taskGroup in self._tasks do
		if taskGroup == group then
			self._tasks[thread] = nil
			cancelThread(thread)
		end
	end
end

function TaskScheduler.HasPending(self: TaskScheduler, group: string): boolean
	for _, taskGroup in self._tasks do
		if taskGroup == group then
			return true
		end
	end
	return false
end

function TaskScheduler.Destroy(self: TaskScheduler): ()
	self._destroyed = true
	local tasks = self._tasks
	self._tasks = {}
	for thread in tasks do
		cancelThread(thread)
	end
end

return TaskScheduler
