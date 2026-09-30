--!strict

-- Aplica los golpes (§17 DamageService): resuelve el resultado con
-- DamageResolver y lo aplica al defensor (daño, postura, aturdimiento,
-- empuje) o al atacante (parry).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local VelocityImpulse = require(ReplicatedStorage.Shared.Modules.VelocityImpulse)
local CombatConfig = require(script.Parent.Parent.Config.CombatConfig)
local CombatRegistry = require(script.Parent.CombatRegistry)
local DamageResolver = require(script.Parent.DamageResolver)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

type AbilityHit = AbilityTypes.AbilityHit
type CombatEntity = CombatRegistry.CombatEntity
type HitOutcome = DamageResolver.HitOutcome

local STUN_GROUP = "Stun"

local DamageService = {
	-- (atacante, defensor, resultado) por cada golpe que no se esquiva, ANTES de
	-- aplicar el daño: quien da el golpe final ya consta cuando el defensor muere.
	-- Síncrona: los handlers no deben ceder (D-013).
	HitLanded = Signal.new() :: Signal.Signal<CombatEntity, CombatEntity, HitOutcome>,
}

-- Si ya está aturdido, solo se alarga: un aturdimiento corto (hitstun) no
-- acorta uno largo (postura rota).
function DamageService.ApplyStun(entity: CombatEntity, duration: number): ()
	local character = entity.Character
	local endsAt = os.clock() + duration
	local stunned = character:GetState() == "Stunned"
	if stunned and entity.StunEndsAt ~= nil and entity.StunEndsAt >= endsAt then
		return
	end
	if not stunned and not character:TransitionTo("Stunned") then
		return
	end
	entity.StunEndsAt = endsAt
	entity.Scheduler:CancelGroup(STUN_GROUP)
	entity.Scheduler:Schedule(STUN_GROUP, duration, function()
		entity.StunEndsAt = nil
		if character:GetState() == "Stunned" then
			character:TransitionTo("Idle")
		end
	end)
end

local function isInvulnerable(entity: CombatEntity, now: number): boolean
	local action = entity.Action
	local iframes = if action ~= nil then action.Ability.IFrames else nil
	if action == nil or iframes == nil then
		return false
	end
	local elapsed = now - action.StartedAt
	return elapsed >= iframes.Start and elapsed <= iframes.End
end

local function isInParryWindow(entity: CombatEntity, now: number): boolean
	local start = entity.ParryWindowStart
	return start ~= nil and now - start <= CombatConfig.ParryWindowSeconds
end

local function applyKnockback(attacker: CombatEntity, defender: CombatEntity, speed: number): ()
	local look = attacker.RootPart.CFrame.LookVector
	local horizontal = Vector3.new(look.X, 0, look.Z)
	if horizontal.Magnitude < 1e-3 then
		return
	end
	local velocity = horizontal.Unit * speed + Vector3.new(0, CombatConfig.KnockbackLift, 0)
	VelocityImpulse.Apply(defender.RootPart, velocity, CombatConfig.KnockbackSeconds)
end

function DamageService.ApplyHit(attacker: CombatEntity, defender: CombatEntity, hit: AbilityHit): HitOutcome
	local now = os.clock()
	local character = defender.Character
	local state = character:GetState()

	local outcome = DamageResolver.Resolve({
		Damage = hit.Damage,
		PostureDamage = hit.PostureDamage,
		GuardBreak = hit.GuardBreak == true,
		Knockback = hit.Knockback or 0,
		DefenderBlocking = state == "Blocking" or state == "Parrying",
		DefenderInParryWindow = isInParryWindow(defender, now),
		DefenderInvulnerable = isInvulnerable(defender, now),
		DefenderPosture = character:GetPosture(),
		DefenderMaxPosture = character:GetMaxPosture(),
	}, CombatConfig)

	if outcome.Kind == "Evaded" then
		return outcome
	end
	DamageService.HitLanded:Fire(attacker, defender, outcome)
	if outcome.Kind == "Parried" then
		if attacker.Character:IsAlive() and attacker.Character:GetState() == "Attacking" then
			DamageService.ApplyStun(attacker, CombatConfig.ParryStunSeconds)
		end
		return outcome
	end

	character:TakeDamage(outcome.Damage)
	character:ApplyPostureDamage(outcome.PostureDamage)
	if not character:IsAlive() then
		return outcome
	end

	if outcome.PostureBreak then
		character:ResetPosture()
		DamageService.ApplyStun(defender, CombatConfig.PostureBreakStunSeconds)
	elseif outcome.Kind == "Hit" then
		DamageService.ApplyStun(defender, CombatConfig.HitStunSeconds)
	end
	if outcome.Knockback > 0 then
		applyKnockback(attacker, defender, outcome.Knockback)
	end
	return outcome
end

return DamageService
