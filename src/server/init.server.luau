-- ServerScriptService/server/ServerInit.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConveyorManager = require(script.ConveyorManager)
local BagManager = require(script.BagManager)

-- Remotes Setup
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local SetController = remotesFolder:FindFirstChild("SetController") or Instance.new("RemoteEvent")
SetController.Name = "SetController"
SetController.Parent = remotesFolder

local SetSpawnInterval = remotesFolder:FindFirstChild("SetSpawnInterval") or Instance.new("RemoteEvent")
SetSpawnInterval.Name = "SetSpawnInterval"
SetSpawnInterval.Parent = remotesFolder

-- Init conveyor + bags
local spec = ConveyorManager.Create()
BagManager.Init(spec)

-- Controller assignment
local controller: Player? = nil
Players.PlayerAdded:Connect(function(plr)
    if not controller then
        controller = plr
        SetController:FireClient(plr, true)
    else
        SetController:FireClient(plr, false)
    end
end)

-- Interval updates (only controller allowed)
SetSpawnInterval.OnServerEvent:Connect(function(plr, interval)
    if plr ~= controller then return end
    if typeof(interval) ~= "number" then return end
    BagManager.SetInterval(interval) -- BagManager clamps internally
end)
