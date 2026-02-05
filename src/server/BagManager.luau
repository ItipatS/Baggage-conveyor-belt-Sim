--ServerScriptService/server/BagManager.luau

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

--Config
--Constaints
local INTERVAL:number = 1
local SPAWNPOINT:Vector3 = Vector3.new(1, 5, 1)
local BAGFOLDER:Folder = nil
local BAGSIZE:Vector3 = Vector3.new(3,2,4)

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
    State: "Spawning" | "Moving" | "Deleting"
}} = {}

local BagManager = {}

local conveyor = nil
local HeartbeatConn: RBXScriptConnection? = nil


local function pickRandom<T>(list: {T}): T
    return list[math.random(#list)]
end


local function tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function PlaySpawnVfx(bag: BasePart, baseCFrame: CFrame, onDone: () -> ())
    -- Start above + tiny + invisible
    bag.Transparency = 1
    bag.CFrame = baseCFrame * CFrame.new(0, 6, 0)
    bag.Size = Vector3.new(0.5, 0.5, 0.5)

    -- Phase 1: appear + overshoot scale
    local t1 = tween(bag, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Transparency = 0,
        Size = BAGSIZE * 1.12,
    })

    t1.Completed:Once(function()
        -- Phase 2: settle size (little shrink bounce)
        local t2 = tween(bag, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = BAGSIZE,
        })

        -- Phase 3: drop onto belt with bounce
        local dropTo = baseCFrame * CFrame.new(0, 2, 0)
        local t3 = tween(bag, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
            CFrame = dropTo,
        })

        -- finish when drop completes (size settle might finish earlier, that’s fine)
        t3.Completed:Once(function()
            if onDone then onDone() end
        end)
    end)
end

local function PlayDespawnVfx(bag: BasePart, onDone: () -> ())
    local up = bag.CFrame * CFrame.new(0, 3, 0)

    local t1 = tween(bag, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = up,
    })

    t1.Completed:Once(function()
        local t2 = tween(bag, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = bag.Size * 0.05,
            Transparency = 1,
        })
        t2.Completed:Once(function()
            if onDone then onDone() end
        end)
    end)
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
    

     -- Spawn slightly above belt at start
    local spawnCFrame = conveyor.StartCFrame * CFrame.new(0, 3, 0)
    bag.CFrame = spawnCFrame
    bag.Parent = BAGFOLDER

    bag:SetAttribute("BagId", bagId)
    
    Bags[bag] = {
        BagId = bagId,
        Color = color,
        Material = material,
        Distance = 0,
        SpawnedAt = os.clock(),
        State = "Spawning"
    }

    --play animation!
    PlaySpawnVfx(bag, conveyor.StartCFrame, function()
        local meta = Bags[bag]
        if meta then meta.State = "Moving" end
    end)
end

local function DestroyBag(bag: Instance)
    Bags[bag] = nil
    bag:Destroy()
end

function BagManager.Init(spec)
    conveyor = spec

    --Initialize BAGFOLDER
    BAGFOLDER = Workspace:FindFirstChild("Bags") or Instance.new("Folder")
    BAGFOLDER.Parent = Workspace
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

            if meta.State == "Moving" then
                meta.Distance += conveyor.Speed * dt

                -- compute new position: start + dir * distance (+ vertical offset)
                local pos = conveyor.StartCFrame.Position + conveyor.Direction * meta.Distance + Vector3.new(0, 2, 0)
                bag.Position = pos
            end

            if meta.State == "Moving" and meta.Distance >= conveyor.Length then
                meta.State = "Deleting"
                PlayDespawnVfx(bag, function()
                    DestroyBag(bag)
                end)
            end
        end
    end)
end

--API for set bag spawn interval from anywhere
function BagManager.SetInterval(seconds: number)
    INTERVAL = math.clamp(seconds, 0.1, 5.0)
end

function BagManager.IsBag(part: Instance): boolean
    return Bags[part] ~= nil
end

return BagManager