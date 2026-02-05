-- StarterPlayerScripts/client/BagClickController.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local BagClicked = remotes:WaitForChild("BagClicked")

local function isBag(part: Instance): (boolean, string?)
    if not part:IsA("BasePart") then
        return false, nil
    end
    local bagId = part:GetAttribute("BagId")
    if typeof(bagId) ~= "string" then
        return false, nil
    end
    return true, bagId
end

local function raycastFromMouse(screenPos: Vector2): RaycastResult?
    if not camera then return nil end

    local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { player.Character } -- ignore own character
    params.IgnoreWater = true

    return Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local hit = raycastFromMouse(input.Position)
    if not hit then return end

    local part = hit.Instance
    local ok, bagId = isBag(part)
    if not ok then return end

    -- Client requirement: print ID
    print(("[CLIENT] BagId: %s"):format(bagId))

    -- Server requirement: notify server (send the instance)
    BagClicked:FireServer(bagId)
end)
return {}