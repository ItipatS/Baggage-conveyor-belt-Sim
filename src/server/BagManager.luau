--ServerScriptService/server/BagManager.luau

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Config
--Constaints
local INTERVAL:number = 1
local BAGFOLDER:Folder = nil
local DELETE_TICK = 0.1 -- 10Hz

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
local deleteAcc = 0

local BagManager = {}

local conveyor = nil
local HeartbeatConn: RBXScriptConnection? = nil

local function pickRandom<T>(list: {T}): T
    return list[math.random(#list)]
end

local function getOrCreateFolder(parent: Instance, name: string): Folder
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f :: Folder
end

local function publishConveyorSpec(spec)
    local specFolder = getOrCreateFolder(ReplicatedStorage, "ConveyorSpec")
    local startPos = spec.StartCFrame.Position
    local dir = spec.Direction

    specFolder:SetAttribute("StartX", startPos.X)
    specFolder:SetAttribute("StartY", startPos.Y)
    specFolder:SetAttribute("StartZ", startPos.Z)

    specFolder:SetAttribute("DirX", dir.X)
    specFolder:SetAttribute("DirY", dir.Y)
    specFolder:SetAttribute("DirZ", dir.Z)

    specFolder:SetAttribute("Length", spec.Length)
    specFolder:SetAttribute("Speed", spec.Speed)
end

local function SpawnBagRecord()
    assert(conveyor, "BagManager not initialized with conveyor spec")

    local bagId = HttpService:GenerateGUID(false)
    local color = pickRandom(COLORS)
    local material = pickRandom(MATERIALS)

    local record = Instance.new("Folder")
    record.Name = bagId
    record.Parent = BAGFOLDER

    record:SetAttribute("BagId", bagId)
    record:SetAttribute("SpawnT", os.clock())
    record:SetAttribute("Mat", material.Name)

    -- store Color3 as numbers
    record:SetAttribute("R", color.R)
    record:SetAttribute("G", color.G)
    record:SetAttribute("B", color.B)
end

function BagManager.Init(spec)
    conveyor = spec
    publishConveyorSpec(spec)

    -- Replicated bag records folder
    BAGFOLDER = getOrCreateFolder(ReplicatedStorage, "Bags")

    if HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end

    HeartbeatConn = RunService.Heartbeat:Connect(function(dt)
        -- spawn loop (unchanged)
        acc += dt
        while acc >= INTERVAL do
            acc -= INTERVAL
            SpawnBagRecord()
        end

        -- delete loop (10Hz)
        deleteAcc += dt
        if deleteAcc < DELETE_TICK then
            return
        end
        deleteAcc -= DELETE_TICK

        local now = os.clock()
        for _, record in ipairs(BAGFOLDER:GetChildren()) do
            local spawnT = record:GetAttribute("SpawnT")
            if typeof(spawnT) ~= "number" then
                continue
            end

            local dist = (now - spawnT) * conveyor.Speed
            if dist >= conveyor.Length then
                record:Destroy()
            end
        end
    end)
end

--API for set bag spawn interval from anywhere
function BagManager.SetInterval(seconds: number)
    INTERVAL = math.clamp(seconds, 0.1, 5.0)
end

function BagManager.IsBagId(bagId: string): boolean
    if typeof(bagId) ~= "string" then return false end
    return BAGFOLDER:FindFirstChild(bagId) ~= nil
end

return BagManager