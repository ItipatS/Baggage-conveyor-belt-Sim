-- ServerScriptService/server/ConveyorManager.luau

local Workspace = game:GetService("Workspace")

local ConveyorManager = {}

export type ConveyorSpec = {
    StartCFrame: CFrame,
    Direction: Vector3,
    Length: number,
    Speed: number,
    EndPosition: Vector3,
}

local BELT_LENGTH = 100
local BELT_SPEED = 12 -- studs/sec (tweakable)
local BELT_WIDTH = 12
local BELT_HEIGHT = 1

function ConveyorManager.Create(): ConveyorSpec
    
    local folder = Instance.new("Folder")
    folder.Name = "Conveyor"
    folder.Parent = Workspace

    -- Choose a consistent coordinate frame for the belt
    local startCFrame = CFrame.new(0, 4, 0) -- center-ish start
    local direction = Vector3.new(0, 0, 1) -- forward along +Z

    -- Visual belt (single part is enough for assignment)
    local belt = Instance.new("Part")
    belt.Name = "Belt"
    belt.Anchored = true
    belt.Size = Vector3.new(BELT_WIDTH, BELT_HEIGHT, BELT_LENGTH)
    -- Place belt so its "start" is near startCFrame and extends forward
    belt.CFrame = startCFrame * CFrame.new(0, 0, BELT_LENGTH / 2)
    belt.Material = Enum.Material.Metal
    belt.Color = Color3.fromRGB(40, 40, 40)
    belt.Parent = folder

    -- End position for deletion checks (start + direction * length)
    local endPos = (startCFrame.Position + direction * BELT_LENGTH)

    return {
        StartCFrame = startCFrame,
        Direction = direction.Unit,
        Length = BELT_LENGTH,
        Speed = BELT_SPEED,
        EndPosition = endPos,
    }
end

return ConveyorManager
