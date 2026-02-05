local ConveyorManager = require(script.ConveyorManager)
local BagManager = require(script.BagManager)

local conveyorSpec = ConveyorManager.Create()
BagManager.Init(conveyorSpec)