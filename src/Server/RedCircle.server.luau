local Workspace = game:GetService("Workspace")

local circle = Instance.new("Part")
circle.Name = "RedCircle"
circle.Shape = Enum.PartType.Cylinder
circle.Anchored = true
circle.CanCollide = false
circle.Material = Enum.Material.Neon
circle.Color = Color3.fromRGB(255, 0, 0)

-- Cylinder's height runs along its local X axis, so rotate it to lie flat
-- (radius on X/Z, thin on Y) and sit just above the baseplate.
circle.Size = Vector3.new(0.2, 20, 20)
circle.CFrame = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))

circle.Parent = Workspace
