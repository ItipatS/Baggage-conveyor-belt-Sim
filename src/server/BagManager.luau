--ServerScriptService/server/BagManager.luau

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--Config
--Constaints
local INTERVAL:number = 1
local SPAWNPOINT:Vector3 = Vector3.new(1, 5, 1)
local BAGFOLDER:Folder = nil

--logic
local acc:number = 0


local BagManager = {}

--Initialize BAGFOLDER
BAGFOLDER = Workspace:FindFirstChild("Bags") or Instance.new("Folder", Workspace)
BAGFOLDER.Name = "Bags"

local function SpawnBag()
    local UUID = HttpService:GenerateGUID(false)

    local bag = Instance.new("Part")
    bag.Position = SPAWNPOINT
    bag.Parent = BAGFOLDER
    bag.Size = Vector3.new(2,2,4)

    bag.Anchored = false -- temporary: physics allowed for early visual validation

    bag:SetAttribute("BagId", UUID)
end

RunService.Heartbeat:Connect(function(dt)
    acc += dt
    while acc >= INTERVAL do
        acc -= INTERVAL
        SpawnBag()
    end
end)

return BagManager