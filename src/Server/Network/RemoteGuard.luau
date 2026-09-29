--!strict

-- Envuelve el handler de un remote con las comprobaciones comunes (§11, D-016):
-- rate limit por jugador → validación del payload → handler protegido.
-- Cualquier rechazo o error devuelve nil al cliente y se registra en el log.
-- Luau puro: el jugador es una clave opaca, lo que permite testearlo con Lune.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local Schema = require(ReplicatedStorage.Shared.Network.Schema)
local RateLimiter = require(script.Parent.Parent.Modules.RateLimiter)

type Logger = Logger.Logger
type Validator = Schema.Validator
type RateLimiter = RateLimiter.RateLimiter

export type Handler = (player: any, payload: any) -> any
export type GuardedHandler = (player: any, payload: unknown) -> any

local RemoteGuard = {}

function RemoteGuard.wrap(
	remoteName: string,
	limiter: RateLimiter,
	validate: Validator,
	handler: Handler,
	log: Logger
): GuardedHandler
	return function(player, payload)
		if not limiter:Consume(player) then
			log:Debug("%s: rate limit superado por %s", remoteName, tostring(player))
			return nil
		end

		local valid, result = validate(payload)
		if not valid then
			log:Debug("%s: payload inválido de %s (%s)", remoteName, tostring(player), tostring(result))
			return nil
		end

		local ok, response = pcall(handler, player, result)
		if not ok then
			log:Error("%s: error en el handler: %s", remoteName, tostring(response))
			return nil
		end
		return response
	end
end

return RemoteGuard
