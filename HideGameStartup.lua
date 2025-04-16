
-- This script makes a black screen when the game starts up.
-- You can keep this or get rid of it; it's your choice.

--▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜▟▜

local Gui = Instance.new("ScreenGui")
Gui.Name = "ReplicatedFirstGui"
Gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
local Frame = Instance.new("Frame")
Frame.Parent = Gui
Frame.Size = UDim2.new(1, 0, 1, 36)
Frame.Position = UDim2.new(0, 0, 0, -36)
Frame.BackgroundColor3 = Color3.new(0, 0, 0)
