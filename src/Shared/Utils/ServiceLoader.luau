--!strict

-- Arranque de servicios/controladores en dos fases (D-014):
--   1. Init  — en orden; cada servicio prepara su estado interno. No debe
--              llamar a otros servicios ni ceder (yield).
--   2. Start — en orden, cuando todos han terminado Init; conecta eventos y
--              arranca bucles. Puede usar otros servicios.
-- El orden lo fija la lista explícita del bootstrap: sin descubrimiento
-- automático ni inyección de dependencias.
-- Un servicio es una tabla con `Name: string` y, opcionalmente, `Init` y/o
-- `Start`. Un fallo en cualquier fase aborta el arranque indicando servicio y fase.

type Phase = "Init" | "Start"
type Lifecycle = (service: any) -> ()

local ServiceLoader = {}

local function getName(service: any): string
	local name = service.Name
	assert(typeof(name) == "string", "[ServiceLoader] un servicio no tiene Name")
	return name
end

local function getCallback(service: any, phase: Phase): Lifecycle?
	local callback = service[phase]
	if callback == nil then
		return nil
	end
	assert(typeof(callback) == "function", `[ServiceLoader] {getName(service)}.{phase} no es una función`)
	return callback
end

local function runPhase(services: { any }, phase: Phase): ()
	for _, service in services do
		local callback = getCallback(service, phase)
		if callback ~= nil then
			local ok, err = pcall(function()
				callback(service)
			end)
			if not ok then
				error(string.format("[ServiceLoader] %s:%s falló: %s", getName(service), phase, tostring(err)), 0)
			end
		end
	end
end

function ServiceLoader.Run(services: { any }): ()
	local names: { [string]: boolean } = {}
	for _, service in services do
		local name = getName(service)
		assert(not names[name], `[ServiceLoader] servicio duplicado: {name}`)
		names[name] = true
	end

	runPhase(services, "Init")
	runPhase(services, "Start")
end

return ServiceLoader
