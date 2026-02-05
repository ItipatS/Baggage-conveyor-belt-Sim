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
local Bags: {[Instance]: {
    BagId: string,
    Color: Color3,
    Material: Enum.Material,
    Distance: number, -- how far along belt (studs)
    SpawnedAt: number,
}} = {}

local BagManager = {}

local conveyor = nil
local HeartbeatConn: RBXScriptConnection? = nil


local function pickRandom<T>(list: {T}): T
    return list[math.random(#list)]
end

local function SpawnBag()
    assert(conveyor, "BagManager not initialized with conveyor spec")

    local bagId  = HttpService:GenerateGUID(false)
    local color = pickRandom(COLORS)
    local material = pickRandom(MATERIALS)

    local bag = Instance.new("Part")
    bag.Name = "Bag"
    bag.Size = Vector3.new(3,2,4)
    bag.Position = SPAWNPOINT
    bag.Anchored =  true -- kinematic movement
    bag.Color = color
    bag.Material = material
    bag.Parent = BAGFOLDER

     -- Spawn slightly above belt at start
    local spawnCFrame = conveyor.StartCFrame * CFrame.new(0, 3, 0)
    bag.CFrame = spawnCFrame
    bag.Parent = Workspace

    bag:SetAttribute("BagId", bagId)
    
    Bags[bag] = {
        BagId = bagId,
        Color = color,
        Material = material,
        Distance = 0,
        SpawnedAt = os.clock(),
    }
end

local function DestroyBag(bag: Instance)
    Bags[bag] = nil
    bag:Destroy()
end

function BagManager.Init(spec)
    conveyor = spec

    --Initialize BAGFOLDER
    BAGFOLDER = Workspace:FindFirstChild("Bags") or Instance.new("Folder", Workspace)
    BAGFOLDER.Name = "Bags"

    -- prevent double init
    if HeartbeatConn then HeartbeatConn:Disconnect() end

    HeartbeatConn = RunService.Heartbeat:Connect(function(dt)
        -- spawn loop
        acc += dt
        while acc >= INTERVAL do
            acc -= INTERVAL
            SpawnBag()
        end

        -- move loop
        for bag, meta in pairs(Bags) do
            if not bag.Parent then
                Bags[bag] = nil
                continue
            end

            meta.Distance += conveyor.Speed * dt

            -- compute new position: start + dir * distance (+ vertical offset)
            local pos = conveyor.StartCFrame.Position + conveyor.Direction * meta.Distance + Vector3.new(0, 2, 0)
            bag.Position = pos

            if meta.Distance >= conveyor.Length then
                DestroyBag(bag)
            end
        end
    end)
end

--API for set bag spawn interval from anywhere
function BagManager.SetInterval(seconds: number)
    INTERVAL = math.clamp(seconds, 0.1, 5.0)
end

return BagManager