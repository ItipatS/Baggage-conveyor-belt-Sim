--ServerScriptService/server/BagManager.luau

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--Config
--Constaints
local INTERVAL:number = 1
local SPAWNPOINT:Vector3 = Vector3.new(1, 5, 1)
local BAGFOLDER:Folder = nil

local MATERIALS = {
    Enum.Material.Plastic,
    Enum.Material.SmoothPlastic,
    Enum.Material.Metal,
    Enum.Material.Fabric,
}

local COLORS = {
    Color3.fromRGB(255, 80, 80),
    Color3.fromRGB(80, 255, 80),
    Color3.fromRGB(80, 80, 255),
    Color3.fromRGB(255, 220, 80),
}

-- State
local acc:number = 0

local BagManager = {}

--Initialize BAGFOLDER
BAGFOLDER = Workspace:FindFirstChild("Bags") or Instance.new("Folder", Workspace)
BAGFOLDER.Name = "Bags"


local function pickRandom<T>(list: {T}): T
    return list[math.random(#list)]
end

local function SpawnBag()
    local bagId  = HttpService:GenerateGUID(false)
    local color = pickRandom(COLORS)
    local material = pickRandom(MATERIALS)

    local bag = Instance.new("Part")
    bag.Size = Vector3.new(2,2,4)
    bag.Position = SPAWNPOINT
    bag.Anchored = false -- temporary: physics allowed for early visual validation
    bag.Color = color
    bag.Material = material
    bag.Parent = BAGFOLDER

    bag:SetAttribute("BagId", bagId)
end

RunService.Heartbeat:Connect(function(dt)
    acc += dt
    while acc >= INTERVAL do
        acc -= INTERVAL
        SpawnBag()
    end
end)

return BagManager