--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local combatIntentRemote = remotesFolder:WaitForChild("CombatIntent") :: RemoteFunction

export type CombatIntentRemote = RemoteFunction

return {
	CombatIntent = combatIntentRemote,
}
