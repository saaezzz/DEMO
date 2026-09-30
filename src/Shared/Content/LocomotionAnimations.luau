--!strict

-- Contenido: locomoción del personaje (D-022). Sustituye las animaciones del
-- script Animate por defecto de Roblox (R15): carpeta del Animate → nombre del
-- valor Animation dentro de ella → clave de animación.

local LocomotionAnimations: { [string]: { [string]: string } } = {
	idle = { Animation1 = "Locomotion.Idle", Animation2 = "Locomotion.LookAround" },
	walk = { WalkAnim = "Locomotion.Walk" },
	run = { RunAnim = "Locomotion.Run" },
	jump = { JumpAnim = "Locomotion.Jump" },
	fall = { FallAnim = "Locomotion.Fall" },
	climb = { ClimbAnim = "Locomotion.Climb" },
	swim = { Swim = "Locomotion.Swim" },
	swimidle = { SwimIdle = "Locomotion.SwimIdle" },
}

return LocomotionAnimations
