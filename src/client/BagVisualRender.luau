--StarterPlayerScripts/client/BagVisualRender.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BagsFolder = ReplicatedStorage:WaitForChild("Bags")
local SpecFolder = ReplicatedStorage:WaitForChild("ConveyorSpec")

local visualsFolder = Workspace:FindFirstChild("BagVisuals") or Instance.new("Folder")
visualsFolder.Name = "BagVisuals"
visualsFolder.Parent = Workspace

local BAGSIZE = Vector3.new(3, 2, 4)

local visualsByRecord: {[Instance]: BasePart} = {}

local function tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function readSpec()
    local sx = SpecFolder:GetAttribute("StartX") or 0
    local sy = SpecFolder:GetAttribute("StartY") or 0
    local sz = SpecFolder:GetAttribute("StartZ") or 0
    local dx = SpecFolder:GetAttribute("DirX") or 0
    local dy = SpecFolder:GetAttribute("DirY") or 0
    local dz = SpecFolder:GetAttribute("DirZ") or 1
    local len = SpecFolder:GetAttribute("Length") or 100
    local speed = SpecFolder:GetAttribute("Speed") or 12

    local start = Vector3.new(sx, sy, sz)
    local dir = Vector3.new(dx, dy, dz)
    if dir.Magnitude < 1e-6 then dir = Vector3.new(0, 0, 1) end
    dir = dir.Unit

    return start, dir, len, speed
end


local function playSpawnVfx(bag: BasePart)
    bag.Size = Vector3.new(0.5, 0.5, 0.5)

    local t1 = tween(bag, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Transparency = 0,
        Size = BAGSIZE * 1.12,
    })

    t1.Completed:Once(function()
        tween(bag, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = BAGSIZE,
        })
    end)
end

local function playDespawnVfx(bag: BasePart, onDone: () -> ())
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

local function makeVisual(record: Instance): BasePart
    local part = Instance.new("Part")
    part.Name = "Bag"
    part.Anchored = true
    part.CanCollide = true
    part.Size = BAGSIZE

    local bagId = record:GetAttribute("BagId")
    if typeof(bagId) == "string" then
        part:SetAttribute("BagId", bagId)
    end

    local r = record:GetAttribute("R")
    local g = record:GetAttribute("G")
    local b = record:GetAttribute("B")
    if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
        part.Color = Color3.new(r, g, b)
    end

    local matName = record:GetAttribute("Mat")
    if typeof(matName) == "string" then
        local mat = Enum.Material[matName]
        if mat then part.Material = mat end
    end

    part.Parent = visualsFolder
    playSpawnVfx(part)
    return part
end

-- Create visuals for existing records (in case script loads late)
for _, record in ipairs(BagsFolder:GetChildren()) do
    visualsByRecord[record] = makeVisual(record)
end

BagsFolder.ChildAdded:Connect(function(record)
    visualsByRecord[record] = makeVisual(record)
end)

BagsFolder.ChildRemoved:Connect(function(record)
    local part = visualsByRecord[record]
    visualsByRecord[record] = nil
    if part then
        playDespawnVfx(part, function()
            part:Destroy()
        end)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    local start, dir, _, speed = readSpec()
    local now = os.clock()

    for record, part in pairs(visualsByRecord) do
        if not record.Parent then
            continue
        end
        local spawnT = record:GetAttribute("SpawnT")
        if typeof(spawnT) ~= "number" then
            continue
        end

        local dist = (now - spawnT) * speed
        local targetPos = start + dir * dist + Vector3.new(0, 2, 0)

        -- Smooth local motion
        part.Position = part.Position:Lerp(targetPos, math.clamp(dt * 20, 0, 1))
    end
end)
return {}