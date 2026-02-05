-- ServerScriptService/server/ControllerService.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllerService = {}

local controller: Player? = nil
local api = nil

local function getRemotesFolder()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Remotes"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

function ControllerService.Init(externalApi)
    api = externalApi

    local remotes = getRemotesFolder()

    local SetController = remotes:FindFirstChild("SetController") or Instance.new("RemoteEvent")
    SetController.Name = "SetController"
    SetController.Parent = remotes

    local SetSpawnInterval = remotes:FindFirstChild("SetSpawnInterval") or Instance.new("RemoteEvent")
    SetSpawnInterval.Name = "SetSpawnInterval"
    SetSpawnInterval.Parent = remotes

    local BagClicked = remotes:FindFirstChild("BagClicked") or Instance.new("RemoteEvent")
    BagClicked.Name = "BagClicked"
    BagClicked.Parent = remotes

    -- choose controller
    Players.PlayerAdded:Connect(function(plr)
        if not controller then
            controller = plr
            SetController:FireClient(plr, true)
        else
            SetController:FireClient(plr, false)
        end
    end)

    -- validate interval requests
    SetSpawnInterval.OnServerEvent:Connect(function(plr, interval)
        if plr ~= controller then return end
        if typeof(interval) ~= "number" then return end

        api.SetInterval(interval) -- BagManager clamps internally
    end)

    BagClicked.OnServerEvent:Connect(function(plr, part)
        if typeof(part) ~= "Instance" then return end
        if not part:IsA("BasePart") then return end
        if not part:IsDescendantOf(workspace) then return end

        local bagId = part:GetAttribute("BagId")
        if typeof(bagId) ~= "string" then return end

        if api.IsBagId and not api.IsBagId(bagId) then return end

        print(("[SERVER] %s clicked BagId: %s"):format(plr.Name, bagId))
    end)

end

return ControllerService
