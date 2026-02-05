-- StarterPlayerScripts/client/ControllerUI.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local SetController = remotes:WaitForChild("SetController")
local SetSpawnInterval = remotes:WaitForChild("SetSpawnInterval")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ControllerGui"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 120)
frame.Position = UDim2.fromOffset(20, 20)
frame.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 40)
label.Position = UDim2.fromOffset(10, 10)
label.Text = "Spawn Interval: 1.0s"
label.Parent = frame

local minus = Instance.new("TextButton")
minus.Size = UDim2.fromOffset(50, 40)
minus.Position = UDim2.fromOffset(10, 60)
minus.Text = "-"
minus.Parent = frame

local plus = Instance.new("TextButton")
plus.Size = UDim2.fromOffset(50, 40)
plus.Position = UDim2.fromOffset(200, 60)
plus.Text = "+"
plus.Parent = frame

local interval = 1.0
local function update()
    label.Text = string.format("Spawn Interval: %.1fs", interval)
    SetSpawnInterval:FireServer(interval)
end

minus.MouseButton1Click:Connect(function()
    interval = math.max(0.1, interval - 0.1)
    update()
end)

plus.MouseButton1Click:Connect(function()
    interval = math.min(5.0, interval + 0.1)
    update()
end)

SetController.OnClientEvent:Connect(function(isController)
    gui.Enabled = isController == true
end)

return {}