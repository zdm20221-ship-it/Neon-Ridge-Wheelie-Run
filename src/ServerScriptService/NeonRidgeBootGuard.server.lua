-- Neon Ridge boot guard: keep the place safe if the primary world script fails.
-- This does not replace the full world; it provides an obvious recovery test area.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("[Neon Ridge] Boot guard started; checking world startup.")

local function ensureFolder(parent, name)
    local found = parent:FindFirstChild(name)
    if found and found:IsA("Folder") then return found end
    if found then found:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function ensureRemote(parent, name)
    local found = parent:FindFirstChild(name)
    if found and found:IsA("RemoteEvent") then return found end
    if found then found:Destroy() end
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = parent
    return remote
end

local function makePart(parent, name, size, cf, color, material, anchored, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = anchored ~= false
    p.CanCollide = collide ~= false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Create the safety floor as soon as this guard starts. The .rbxlx also saves
-- these parts directly in Workspace, so edit-mode opens already have visible ground.
if not Workspace:FindFirstChild("NeonRidgeSafetyFloor") then
    makePart(Workspace, "NeonRidgeSafetyFloor", Vector3.new(860, 8, 860), CFrame.new(0, -4.4, 0), Color3.fromRGB(81, 123, 91), Enum.Material.Grass, true, true)
end
if not Workspace:FindFirstChild("NeonRidgeSafetySpawn") then
    local safeSpawn = Instance.new("SpawnLocation")
    safeSpawn.Name = "NeonRidgeSafetySpawn"
    safeSpawn.Size = Vector3.new(12, 1, 12)
    safeSpawn.CFrame = CFrame.new(-275, 0.1, 145)
    safeSpawn.Color = Color3.fromRGB(68, 242, 219)
    safeSpawn.Material = Enum.Material.Metal
    safeSpawn.Anchored = true
    safeSpawn.Neutral = true
    safeSpawn.Duration = 0
    safeSpawn.Parent = Workspace
end

local function makeLabel(part, title, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "RecoveryLabel"
    gui.Adornee = part
    gui.Size = UDim2.fromOffset(340, 60)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 700
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(8, 19, 31)
    label.BackgroundTransparency = 0.08
    label.Text = title
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.65
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    return gui
end

local function spawnRecoveryRide(player)
    local cars = ensureFolder(Workspace, "NeonRidgeCars")
    local name = "RecoveryE-Moto_" .. player.UserId
    local old = cars:FindFirstChild(name)
    if old then old:Destroy() end

    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("IsNeonCar", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("VehicleId", "RecoveryE-Moto")
    model:SetAttribute("DisplayName", "RECOVERY E-MOTO")
    model:SetAttribute("Power", 24)
    model:SetAttribute("MaxSpeed", 62)
    model:SetAttribute("Grip", 3.6)
    model:SetAttribute("Steering", 0.85)
    model:SetAttribute("Handbrake", false)
    model:SetAttribute("CurrentSpeed", 0)
    model:SetAttribute("VehicleType", "Moto")

    local root = Instance.new("Part")
    root.Name = "Chassis"
    root.Size = Vector3.new(2, 0.9, 3.8)
    root.CFrame = CFrame.new(-270, 1.8, 170)
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = true
    root.CustomPhysicalProperties = PhysicalProperties.new(0.9, 0.7, 0.02, 1, 1)
    root.Parent = model
    model.PrimaryPart = root

    local function detail(partName, size, localCF, color, material, shape)
        local part = Instance.new("Part")
        part.Name = partName
        part.Size = size
        part.CFrame = root.CFrame * localCF
        part.Color = color
        part.Material = material or Enum.Material.Metal
        if shape then part.Shape = shape end
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
        part.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = part
        return part
    end

    local neon = Color3.fromRGB(68, 242, 219)
    local orange = Color3.fromRGB(255, 129, 63)
    local black = Color3.fromRGB(22, 27, 34)
    detail("Frame", Vector3.new(0.3, 0.3, 2.8), CFrame.new(0, 0.12, 0), Color3.fromRGB(118, 130, 144))
    detail("BatteryPack", Vector3.new(0.8, 0.62, 0.9), CFrame.new(0, -0.05, 0.1), black)
    detail("OrangeSidePanelL", Vector3.new(0.1, 0.48, 0.68), CFrame.new(-0.45, 0.15, -0.25), orange, Enum.Material.SmoothPlastic)
    detail("OrangeSidePanelR", Vector3.new(0.1, 0.48, 0.68), CFrame.new(0.45, 0.15, -0.25), orange, Enum.Material.SmoothPlastic)
    detail("SeatVisual", Vector3.new(0.55, 0.18, 1.1), CFrame.new(0, 0.55, 0.25), black, Enum.Material.SmoothPlastic)
    detail("Handlebar", Vector3.new(1.1, 0.08, 0.12), CFrame.new(0, 0.65, -1.38), black)
    detail("Headlight", Vector3.new(0.36, 0.24, 0.12), CFrame.new(0, 0.45, -1.58), Color3.fromRGB(229, 252, 255), Enum.Material.Neon)
    detail("BatteryGlow", Vector3.new(0.66, 0.08, 0.64), CFrame.new(0, 0.22, 0.1), neon, Enum.Material.Neon)
    for _, z in ipairs({-1.35, 1.25}) do
        detail(z < 0 and "FrontWheel" or "RearWheel", Vector3.new(0.32, 0.72, 0.72), CFrame.new(0, -0.1, z), black, Enum.Material.Rubber, Enum.PartType.Cylinder)
        detail(z < 0 and "FrontHub" or "RearHub", Vector3.new(0.34, 0.24, 0.24), CFrame.new(0, -0.1, z), neon, Enum.Material.Metal, Enum.PartType.Cylinder)
    end

    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(0.9, 0.4, 0.9)
    seat.CFrame = root.CFrame * CFrame.new(0, 0.75, 0.2)
    seat.Transparency = 1
    seat.Anchored = false
    seat.CanCollide = false
    seat.Massless = true
    seat.HeadsUpDisplay = false
    seat.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = seat
    weld.Parent = seat

    model.Parent = cars
    task.delay(0.3, function()
        if player.Parent ~= Players or not model.Parent or not seat.Parent then return end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then seat:Sit(humanoid) end
    end)
end

local function buildRecoveryArea(hasMainGround)
    local recovery = ensureFolder(Workspace, "NeonRidgeRecoveryWorld")
    if recovery:GetAttribute("Built") then return end
    recovery:SetAttribute("Built", true)

    -- This section is intentionally simple and uses only standard parts.
    if not hasMainGround then
        makePart(recovery, "RecoveryGround", Vector3.new(900, 1, 900), CFrame.new(0, -0.05, 0), Color3.fromRGB(72, 116, 83), Enum.Material.Grass, true, true)
    end
    local route = {
        Vector3.new(-170, 0.55, -110), Vector3.new(150, 0.55, -110),
        Vector3.new(150, 0.55, 150), Vector3.new(-170, 0.55, 150),
    }
    for i, a in ipairs(route) do
        local b = route[(i % #route) + 1]
        local middle = (a + b) / 2
        local length = (b - a).Magnitude
        local road = makePart(recovery, "RecoveryRoad_" .. i, Vector3.new(28, 0.45, length + 3), CFrame.lookAt(middle, b), Color3.fromRGB(40, 46, 56), Enum.Material.Asphalt, true, true)
        road.CastShadow = false
        for _, side in ipairs({-1, 1}) do
            local stripe = makePart(recovery, "RecoveryRoadEdge", Vector3.new(0.3, 0.05, length), road.CFrame * CFrame.new(side * 12.5, 0.25, 0), Color3.fromRGB(87, 249, 223), Enum.Material.Neon, true, false)
            stripe.CastShadow = false
        end
    end

    local tower = makePart(recovery, "RecoveryBeacon", Vector3.new(12, 36, 12), CFrame.new(0, 18, 20), Color3.fromRGB(34, 53, 69), Enum.Material.Metal, true, true)
    makePart(recovery, "RecoveryBeaconTop", Vector3.new(16, 1.5, 16), CFrame.new(0, 37, 20), Color3.fromRGB(68, 242, 219), Enum.Material.Neon, true, false)
    makeLabel(tower, "NEON RIDGE  /  RECOVERY TEST AREA", Color3.fromRGB(105, 255, 230))

    local pad = makePart(recovery, "RecoveryMotoPad", Vector3.new(13, 0.7, 13), CFrame.new(-270, 0.35, 170), Color3.fromRGB(30, 53, 66), Enum.Material.Metal, true, true)
    makePart(recovery, "RecoveryMotoPadGlow", Vector3.new(12, 0.08, 12), CFrame.new(-270, 0.76, 170), Color3.fromRGB(68, 242, 219), Enum.Material.Neon, true, false)
    makeLabel(pad, "PRESS E  /  SPAWN RECOVERY E-MOTO", Color3.fromRGB(255, 153, 80))
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "RecoveryMotoPrompt"
    prompt.ActionText = "Spawn test ride"
    prompt.ObjectText = "Recovery E-Moto"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0.25
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = pad
    prompt.Triggered:Connect(function(player)
        spawnRecoveryRide(player)
    end)

    warn("[Neon Ridge] Recovery area created because the main map did not finish initializing. Check earlier red errors in Output.")
end

task.wait(12)

local world = Workspace:FindFirstChild("NeonRidgeWorld")
local hasGround = world and world:FindFirstChild("IslandGround")
local hasSpawn = world and world:FindFirstChild("HarborSpawn")
local hasGarage = world and world:FindFirstChild("GaragePad_SolarGT")
if hasGround and hasSpawn and hasGarage then
    print("[Neon Ridge] Boot check passed: ground, spawn, and garage detected.")
    return
end

local missing = {}
if not hasGround then table.insert(missing, "IslandGround") end
if not hasSpawn then table.insert(missing, "HarborSpawn") end
if not hasGarage then table.insert(missing, "GaragePad_SolarGT") end
warn("[Neon Ridge] Main world startup incomplete. Missing: " .. table.concat(missing, ", "))

-- Ensure folders/remotes exist so the client and physics script don't wait forever.
local cars = ensureFolder(Workspace, "NeonRidgeCars")
ensureFolder(Workspace, "NeonRidgeWorld")
local remotes = ensureFolder(ReplicatedStorage, "NeonRidgeRemotes")
ensureRemote(remotes, "Handbrake")
ensureRemote(remotes, "VehicleAction")
ensureRemote(remotes, "RaceUpdate")

-- Ensure a reachable spawn exists even if the main script stopped mid-build.
local spawn = Workspace:FindFirstChild("NeonRidgeSafetySpawn")
if not spawn then
    spawn = Instance.new("SpawnLocation")
    spawn.Name = "NeonRidgeSafetySpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.CFrame = CFrame.new(-275, 0.1, 145)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = Color3.fromRGB(68, 242, 219)
    spawn.Material = Enum.Material.Metal
    spawn.Parent = Workspace
end

buildRecoveryArea(hasGround ~= nil)
for _, player in ipairs(Players:GetPlayers()) do
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid and root and humanoid.Health > 0 and not humanoid.SeatPart then
        character:PivotTo(CFrame.new(-275, 5, 145))
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(character)
        task.wait(0.25)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and not humanoid.SeatPart then
            character:PivotTo(CFrame.new(-275, 5, 145))
        end
    end)
end

print("[Neon Ridge] Recovery checks complete; the safety floor and recovery test area are available.")
