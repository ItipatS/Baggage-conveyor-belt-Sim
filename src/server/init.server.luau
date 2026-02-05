-- ServerScriptService/server/ServerInit.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConveyorManager = require(script.ConveyorManager)
local BagManager = require(script.BagManager)
local ControllerService  = require(script.ControllerService )
-- Init conveyor + bags
local spec = ConveyorManager.Create()
BagManager.Init(spec)

-- Init ControllerService + set api
ControllerService.Init({
    SetInterval = function(seconds)
        BagManager.SetInterval(seconds)
    end,
})