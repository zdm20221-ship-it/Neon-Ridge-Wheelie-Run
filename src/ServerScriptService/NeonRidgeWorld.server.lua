-- Neon Ridge: original Roblox driving-game starter.
-- Place this Script in ServerScriptService.
print("[Neon Ridge] World script starting.")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WORLD_NAME = "NeonRidgeWorld"
local CARS_NAME = "NeonRidgeCars"

local oldWorld = Workspace:FindFirstChild(WORLD_NAME)
if oldWorld then oldWorld:Destroy() end
local oldCars = Workspace:FindFirstChild(CARS_NAME)
if oldCars then oldCars:Destroy() end

local world = Instance.new("Folder")
world.Name = WORLD_NAME
world.Parent = Workspace

local carsFolder = Instance.new("Folder")
carsFolder.Name = CARS_NAME
carsFolder.Parent = Workspace

local remotes = ReplicatedStorage:FindFirstChild("NeonRidgeRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "NeonRidgeRemotes"
    remotes.Parent = ReplicatedStorage
end

local function getOrMakeRemote(name)
    local remote = remotes:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotes
    end
    return remote
end

local handbrakeEvent = getOrMakeRemote("Handbrake")
local actionEvent = getOrMakeRemote("VehicleAction")
local raceEvent = getOrMakeRemote("RaceUpdate")

-- World lighting: a warm, clean sunset with restrained neon accents.
Lighting.Technology = Enum.Technology.Future
Lighting.ClockTime = 17.6
Lighting.Brightness = 2.1
Lighting.ExposureCompensation = 0.05
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.8
Lighting.Ambient = Color3.fromRGB(92, 104, 130)
Lighting.OutdoorAmbient = Color3.fromRGB(132, 142, 160)
Lighting.GlobalShadows = true

for _, effectName in ipairs({"NR_Atmosphere", "NR_Bloom", "NR_Color", "NR_SunRays"}) do
    local old = Lighting:FindFirstChild(effectName)
    if old then old:Destroy() end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "NR_Atmosphere"
atmosphere.Density = 0.24
atmosphere.Offset = 0.18
atmosphere.Color = Color3.fromRGB(205, 216, 255)
atmosphere.Decay = Color3.fromRGB(255, 177, 132)
atmosphere.Glare = 0.18
atmosphere.Haze = 1.4
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "NR_Bloom"
bloom.Intensity = 0.34
bloom.Size = 22
bloom.Threshold = 1.25
bloom.Parent = Lighting

local color = Instance.new("ColorCorrectionEffect")
color.Name = "NR_Color"
color.Brightness = 0.025
color.Contrast = 0.12
color.Saturation = 0.08
color.TintColor = Color3.fromRGB(255, 238, 224)
color.Parent = Lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "NR_SunRays"
sunRays.Intensity = 0.055
sunRays.Spread = 0.78
sunRays.Parent = Lighting

local function makePart(parent, name, size, cframe, color3, material, anchored, canCollide)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color3
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = anchored ~= false
    part.CanCollide = canCollide ~= false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function makeBillboard(adornee, title, accent)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WorldLabel"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(270, 48)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 450
    gui.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(11, 20, 31)
    label.BackgroundTransparency = 0.12
    label.Text = title
    label.TextColor3 = accent
    label.TextStrokeTransparency = 0.75
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Transparency = 0.18
    stroke.Thickness = 1.5
    stroke.Parent = label
    return gui
end

-- Base island and ocean shelf.
makePart(world, "CoastalWater", Vector3.new(1800, 8, 1800), CFrame.new(0, -8, 0), Color3.fromRGB(38, 117, 151), Enum.Material.Glass, true, true)
makePart(world, "IslandGround", Vector3.new(820, 8, 820), CFrame.new(0, -4, 0), Color3.fromRGB(81, 123, 91), Enum.Material.Grass, true, true)
-- Once the real island ground exists, retire the saved-in-place safety floor.
local safetyFloor = Workspace:FindFirstChild("NeonRidgeSafetyFloor")
if safetyFloor then safetyFloor:Destroy() end
makePart(world, "CoastalCliffNorth", Vector3.new(820, 18, 10), CFrame.new(0, 5, -405), Color3.fromRGB(93, 104, 92), Enum.Material.Rock, true, true)
makePart(world, "CoastalCliffSouth", Vector3.new(820, 18, 10), CFrame.new(0, 5, 405), Color3.fromRGB(93, 104, 92), Enum.Material.Rock, true, true)
makePart(world, "CoastalCliffEast", Vector3.new(10, 18, 820), CFrame.new(405, 5, 0), Color3.fromRGB(93, 104, 92), Enum.Material.Rock, true, true)
makePart(world, "CoastalCliffWest", Vector3.new(10, 18, 820), CFrame.new(-405, 5, 0), Color3.fromRGB(93, 104, 92), Enum.Material.Rock, true, true)

-- Original scenic loop: long coast roads, a city core, and a checkpoint time trial.
local route = {
    Vector3.new(-220, 0.2, 70),
    Vector3.new(-220, 0.2, -130),
    Vector3.new(-120, 0.2, -250),
    Vector3.new(80, 0.2, -250),
    Vector3.new(230, 0.2, -140),
    Vector3.new(230, 0.2, 60),
    Vector3.new(120, 0.2, 220),
    Vector3.new(-100, 0.2, 220),
}

local function createRoadSegment(startPos, endPos, width, segmentIndex)
    local delta = endPos - startPos
    local length = delta.Magnitude
    local middle = (startPos + endPos) / 2
    local roadCFrame = CFrame.lookAt(middle, endPos)
    local road = makePart(world, "CoastalRoad_" .. segmentIndex, Vector3.new(width, 0.55, length + 5), roadCFrame, Color3.fromRGB(43, 48, 57), Enum.Material.Asphalt, true, true)
    road.CastShadow = false

    -- White edge stripes.
    for _, side in ipairs({-1, 1}) do
        local stripe = makePart(world, "RoadEdge", Vector3.new(0.32, 0.055, length), roadCFrame * CFrame.new(side * (width / 2 - 1.6), 0.305, 0), Color3.fromRGB(220, 225, 225), Enum.Material.SmoothPlastic, true, false)
        stripe.CastShadow = false
    end

    -- Broken amber center line.
    local offset = -length / 2 + 8
    while offset < length / 2 - 3 do
        local dash = makePart(world, "CenterLine", Vector3.new(0.45, 0.06, 7), roadCFrame * CFrame.new(0, 0.31, offset), Color3.fromRGB(255, 190, 76), Enum.Material.Neon, true, false)
        dash.CastShadow = false
        offset += 19
    end

    return road
end

for i = 1, #route do
    local nextIndex = (i % #route) + 1
    createRoadSegment(route[i], route[nextIndex], 40, i)
end

-- A short service road makes the original garage entrance easy to find.
createRoadSegment(Vector3.new(-300, 0.2, 120), Vector3.new(-220, 0.2, 120), 32, "GarageLink")
createRoadSegment(Vector3.new(-220, 0.2, 120), Vector3.new(-220, 0.2, 70), 32, "GarageApproach")

-- Downtown blocks: procedural buildings with glass bands and luminous roof trims.
local rng = Random.new(74421)
local buildingColors = {
    Color3.fromRGB(45, 67, 86),
    Color3.fromRGB(60, 75, 89),
    Color3.fromRGB(68, 78, 102),
    Color3.fromRGB(82, 91, 104),
    Color3.fromRGB(48, 81, 89),
}
local accentColors = {
    Color3.fromRGB(66, 238, 220),
    Color3.fromRGB(255, 174, 92),
    Color3.fromRGB(115, 162, 255),
    Color3.fromRGB(214, 130, 255),
}

local buildingCoords = {
    {-100, -95}, {-35, -95}, {35, -95}, {100, -95},
    {-100, -30}, {-35, -30}, {35, -30}, {100, -30},
    {-100, 35}, {-35, 35}, {35, 35}, {100, 35},
    {-100, 100}, {-35, 100}, {35, 100}, {100, 100},
}

for i, coord in ipairs(buildingCoords) do
    local x, z = coord[1], coord[2]
    local width = rng:NextInteger(20, 27)
    local depth = rng:NextInteger(20, 27)
    local height = rng:NextInteger(28, 82)
    local bodyColor = buildingColors[rng:NextInteger(1, #buildingColors)]
    local accent = accentColors[rng:NextInteger(1, #accentColors)]
    local base = makePart(world, "CityBuilding_" .. i, Vector3.new(width, height, depth), CFrame.new(x, height / 2, z), bodyColor, Enum.Material.Concrete, true, true)
    base.CastShadow = true

    makePart(world, "RoofTrim", Vector3.new(width + 1, 0.6, depth + 1), CFrame.new(x, height + 0.25, z), accent, Enum.Material.Neon, true, false)
    makePart(world, "FacadeAccent", Vector3.new(0.7, height - 4, 0.35), CFrame.new(x - width / 2 + 2, height / 2, z - depth / 2 - 0.2), accent, Enum.Material.Neon, true, false)

    local floorY = 8
    while floorY < height - 4 do
        makePart(world, "GlassBand", Vector3.new(width - 5, 2.3, 0.22), CFrame.new(x, floorY, z - depth / 2 - 0.18), Color3.fromRGB(105, 178, 204), Enum.Material.Glass, true, false).Transparency = 0.28
        floorY += 10
    end
end

-- A recognizable skyline marker at the center of town.
local tower = makePart(world, "HarborBeacon", Vector3.new(10, 115, 10), CFrame.new(0, 57.5, 0), Color3.fromRGB(37, 53, 69), Enum.Material.Metal, true, true)
makePart(world, "BeaconLight", Vector3.new(15, 2, 15), CFrame.new(0, 116, 0), Color3.fromRGB(66, 238, 220), Enum.Material.Neon, true, false)
local beaconLight = Instance.new("PointLight")
beaconLight.Color = Color3.fromRGB(66, 238, 220)
beaconLight.Range = 42
beaconLight.Brightness = 1.8
beaconLight.Parent = tower
makeBillboard(tower, "APEX HARBOR", Color3.fromRGB(106, 250, 228))

-- Stylized coastal pines around the island perimeter.
local treePositions = {
    {-345, -330}, {-285, -348}, {-210, -352}, {-120, -350}, {-20, -350},
    {85, -350}, {180, -350}, {280, -338}, {345, -280}, {350, -170},
    {350, -60}, {350, 55}, {345, 165}, {320, 280}, {230, 345},
    {120, 350}, {10, 350}, {-100, 350}, {-210, 345}, {-320, 280},
    {-350, 165}, {-350, 40}, {-350, -90},
}
for i, p in ipairs(treePositions) do
    local x, z = p[1], p[2]
    local trunkHeight = rng:NextInteger(7, 11)
    makePart(world, "PineTrunk", Vector3.new(2.2, trunkHeight, 2.2), CFrame.new(x, trunkHeight / 2, z), Color3.fromRGB(108, 79, 55), Enum.Material.Wood, true, true)
    local crown = makePart(world, "PineCanopy", Vector3.new(10, 12, 10), CFrame.new(x, trunkHeight + 2, z), Color3.fromRGB(42, rng:NextInteger(105, 138), 94), Enum.Material.Grass, true, true)
    crown.Shape = Enum.PartType.Ball
    crown.CastShadow = true
end

-- Street lighting along alternating route sections.
for i = 1, #route do
    local a = route[i]
    local b = route[(i % #route) + 1]
    local delta = b - a
    local length = delta.Magnitude
    local dir = delta.Unit
    local right = dir:Cross(Vector3.yAxis).Unit
    local count = math.floor(length / 55)
    for j = 1, count do
        if (j + i) % 2 == 0 then
            local t = j / (count + 1)
            local point = a:Lerp(b, t) + right * 25
            local pole = makePart(world, "StreetLampPole", Vector3.new(0.55, 10, 0.55), CFrame.new(point.X, 5, point.Z), Color3.fromRGB(53, 67, 80), Enum.Material.Metal, true, true)
            makePart(world, "StreetLampHead", Vector3.new(2.2, 0.55, 1.2), CFrame.new(point.X, 10.2, point.Z), Color3.fromRGB(255, 210, 145), Enum.Material.Neon, true, false)
            local lamp = Instance.new("PointLight")
            lamp.Color = Color3.fromRGB(255, 199, 132)
            lamp.Range = 22
            lamp.Brightness = 0.85
            lamp.Parent = pole
        end
    end
end

-- Garage architecture and three distinct vehicle selection pads.
local garageCenter = Vector3.new(-318, 0, 120)
makePart(world, "GarageFloor", Vector3.new(46, 0.7, 76), CFrame.new(-304, 0.35, 120), Color3.fromRGB(47, 56, 68), Enum.Material.Concrete, true, true)
makePart(world, "GarageBackWall", Vector3.new(1.2, 17, 76), CFrame.new(-338, 8.5, 120), Color3.fromRGB(35, 46, 59), Enum.Material.Metal, true, true)
makePart(world, "GarageRoof", Vector3.new(46, 1.5, 76), CFrame.new(-316, 17.5, 120), Color3.fromRGB(27, 37, 50), Enum.Material.Metal, true, true)
makePart(world, "GarageNeonBeam", Vector3.new(1, 1.2, 77), CFrame.new(-293, 15.7, 120), Color3.fromRGB(66, 238, 220), Enum.Material.Neon, true, false)
local garageSign = makePart(world, "GarageSign", Vector3.new(0.8, 5, 31), CFrame.new(-292.5, 11, 120), Color3.fromRGB(13, 28, 42), Enum.Material.SmoothPlastic, true, false)
local signGui = Instance.new("SurfaceGui")
signGui.Name = "GarageSignUI"
signGui.Face = Enum.NormalId.Right
signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
signGui.PixelsPerStud = 35
signGui.Parent = garageSign
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Text = "NEON RIDGE  •  MOTOR CLUB"
signText.TextColor3 = Color3.fromRGB(100, 255, 228)
signText.TextScaled = true
signText.Font = Enum.Font.GothamBlack
signText.Rotation = 0
signText.Parent = signGui

local carSpecs = {
    {
        Id = "SolarGT",
        DisplayName = "Solar GT",
        BodyColor = Color3.fromRGB(255, 135, 73),
        AccentColor = Color3.fromRGB(255, 209, 116),
        Power = 33,
        MaxSpeed = 118,
        Grip = 2.65,
        Steering = 1.0,
        Description = "Balanced coastal coupe",
    },
    {
        Id = "HarborXR",
        DisplayName = "Harbor XR",
        BodyColor = Color3.fromRGB(57, 205, 188),
        AccentColor = Color3.fromRGB(176, 255, 239),
        Power = 29,
        MaxSpeed = 106,
        Grip = 3.1,
        Steering = 1.15,
        Description = "Grippy all-rounder",
    },
    {
        Id = "SummitRS",
        DisplayName = "Summit RS",
        BodyColor = Color3.fromRGB(153, 119, 255),
        AccentColor = Color3.fromRGB(225, 210, 255),
        Power = 39,
        MaxSpeed = 132,
        Grip = 2.15,
        Steering = 1.08,
        Description = "Fast, loose sport build",
    },
}

local function weldDecorativePart(root, part)
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = part
    weld.Parent = root
    return part
end

local function addCarPart(model, root, name, size, localCFrame, color3, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = root.CFrame * localCFrame
    part.Color = color3
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    if shape then part.Shape = shape end
    part.Parent = model
    weldDecorativePart(root, part)
    return part
end

local function createCar(player, spec)
    local lane = (player.UserId % 5) - 2
    local spawnCFrame = CFrame.new(-220 + lane * 5, 1.1, 112)
    local model = Instance.new("Model")
    model.Name = spec.Id .. "_" .. player.UserId
    model:SetAttribute("IsNeonCar", true)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("VehicleId", spec.Id)
    model:SetAttribute("DisplayName", spec.DisplayName)
    model:SetAttribute("Power", spec.Power)
    model:SetAttribute("MaxSpeed", spec.MaxSpeed)
    model:SetAttribute("Grip", spec.Grip)
    model:SetAttribute("Steering", spec.Steering)
    model:SetAttribute("Handbrake", false)
    model:SetAttribute("CurrentSpeed", 0)

    local root = Instance.new("Part")
    root.Name = "Chassis"
    root.Size = Vector3.new(4.8, 1.25, 7.8)
    root.CFrame = spawnCFrame
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = true
    root.CanTouch = true
    root.CanQuery = true
    root.Massless = false
    root.CustomPhysicalProperties = PhysicalProperties.new(1.15, 0.82, 0.03, 1, 1)
    root.TopSurface = Enum.SurfaceType.Smooth
    root.BottomSurface = Enum.SurfaceType.Smooth
    root.Parent = model
    model.PrimaryPart = root

    local black = Color3.fromRGB(25, 29, 37)
    local glass = Color3.fromRGB(102, 179, 208)
    addCarPart(model, root, "LowerBody", Vector3.new(4.85, 0.72, 7.9), CFrame.new(0, 0.1, 0), spec.BodyColor, Enum.Material.Metal)
    addCarPart(model, root, "Hood", Vector3.new(4.4, 0.36, 2.4), CFrame.new(0, 0.58, -2.45), spec.BodyColor, Enum.Material.SmoothPlastic)
    addCarPart(model, root, "Trunk", Vector3.new(4.35, 0.36, 1.5), CFrame.new(0, 0.58, 2.7), spec.BodyColor, Enum.Material.SmoothPlastic)
    addCarPart(model, root, "Cabin", Vector3.new(3.3, 1.12, 3.15), CFrame.new(0, 1.0, -0.35), black, Enum.Material.Metal)
    addCarPart(model, root, "Roof", Vector3.new(2.7, 0.16, 1.8), CFrame.new(0, 1.62, -0.55), spec.BodyColor, Enum.Material.SmoothPlastic)
    addCarPart(model, root, "FrontGlass", Vector3.new(2.75, 0.68, 0.12), CFrame.new(0, 1.19, -1.86) * CFrame.Angles(math.rad(-24), 0, 0), glass, Enum.Material.Glass)
    addCarPart(model, root, "RearGlass", Vector3.new(2.6, 0.64, 0.12), CFrame.new(0, 1.17, 1.12) * CFrame.Angles(math.rad(22), 0, 0), glass, Enum.Material.Glass)
    addCarPart(model, root, "FrontSplitter", Vector3.new(4.9, 0.16, 0.55), CFrame.new(0, -0.08, -3.92), black, Enum.Material.Metal)
    addCarPart(model, root, "RearDiffuser", Vector3.new(4.6, 0.18, 0.48), CFrame.new(0, -0.06, 3.91), black, Enum.Material.Metal)
    addCarPart(model, root, "SideStripeL", Vector3.new(0.08, 0.18, 4.8), CFrame.new(-2.43, 0.33, 0.1), spec.AccentColor, Enum.Material.Neon)
    addCarPart(model, root, "SideStripeR", Vector3.new(0.08, 0.18, 4.8), CFrame.new(2.43, 0.33, 0.1), spec.AccentColor, Enum.Material.Neon)

    for _, x in ipairs({-1.55, 1.55}) do
        local frontLamp = addCarPart(model, root, "Headlamp", Vector3.new(0.82, 0.22, 0.12), CFrame.new(x, 0.5, -3.85), Color3.fromRGB(220, 246, 255), Enum.Material.Neon)
        local light = Instance.new("SpotLight")
        light.Color = Color3.fromRGB(202, 235, 255)
        light.Range = 36
        light.Brightness = 1.1
        light.Angle = 62
        light.Face = Enum.NormalId.Front
        light.Parent = frontLamp
        addCarPart(model, root, "TailLamp", Vector3.new(0.82, 0.2, 0.12), CFrame.new(x, 0.48, 3.88), Color3.fromRGB(255, 67, 82), Enum.Material.Neon)
    end

    -- Decorative rotating wheel assemblies; tires are visual, with chassis collisions handling impacts.
    for _, x in ipairs({-2.47, 2.47}) do
        for _, z in ipairs({-2.55, 2.55}) do
            local wheelLocal = CFrame.new(x, 0, z)
            local wheel = Instance.new("Part")
            wheel.Name = "Tire"
            wheel.Shape = Enum.PartType.Cylinder
            wheel.Size = Vector3.new(0.9, 1.23, 1.23)
            wheel.CFrame = root.CFrame * wheelLocal
            wheel.Color = Color3.fromRGB(23, 25, 30)
            wheel.Material = Enum.Material.Rubber
            wheel.Anchored = false
            wheel.CanCollide = false
            wheel.CanTouch = false
            wheel.CanQuery = false
            wheel.Massless = true
            wheel.Parent = model

            local motor = Instance.new("Motor6D")
            motor.Name = "WheelMotor"
            motor.Part0 = root
            motor.Part1 = wheel
            motor.C0 = wheelLocal
            motor.C1 = CFrame.new()
            motor.Parent = root

            local hubLocal = CFrame.new(x * 1.12, 0, z)
            addCarPart(model, root, "WheelHub", Vector3.new(0.16, 0.58, 0.58), hubLocal, spec.AccentColor, Enum.Material.Metal, Enum.PartType.Cylinder)
        end
    end

    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(2, 0.9, 2)
    seat.CFrame = root.CFrame * CFrame.new(0, 1.12, 0.45)
    seat.Color = black
    seat.Material = Enum.Material.SmoothPlastic
    seat.Anchored = false
    seat.CanCollide = false
    seat.CanTouch = true
    seat.Massless = true
    seat.HeadsUpDisplay = false
    seat.MaxSpeed = spec.MaxSpeed
    seat.Parent = model
    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = root
    seatWeld.Part1 = seat
    seatWeld.Parent = root

    model.Parent = carsFolder

    -- Make the owner sit automatically so the first action after spawning is driving.
    task.delay(0.3, function()
        if player.Parent == Players and seat.Parent == model and seat.Occupant == nil then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                seat:Sit(humanoid)
            end
        end
    end)
    return model
end

local currentCarByPlayer = {}

local function setUpPlayer(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    local credits = leaderstats:FindFirstChild("Credits")
    if not credits then
        credits = Instance.new("IntValue")
        credits.Name = "Credits"
        credits.Value = 0
        credits.Parent = leaderstats
    end
end

Players.PlayerAdded:Connect(setUpPlayer)
for _, player in ipairs(Players:GetPlayers()) do setUpPlayer(player) end

local pads = {}
for index, spec in ipairs(carSpecs) do
    local z = 82 + (index - 1) * 29
    local pad = makePart(world, "GaragePad_" .. spec.Id, Vector3.new(16, 0.6, 22), CFrame.new(-286, 0.35, z), Color3.fromRGB(37, 49, 63), Enum.Material.Metal, true, true)
    makePart(world, "GaragePadGlow_" .. spec.Id, Vector3.new(15, 0.08, 21), CFrame.new(-286, 0.7, z), spec.AccentColor, Enum.Material.Neon, true, false)
    makeBillboard(pad, spec.DisplayName .. "  •  " .. spec.Description, spec.AccentColor)

    local selectedSpec = spec
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SpawnVehiclePrompt"
    prompt.ActionText = "Spawn vehicle"
    prompt.ObjectText = spec.DisplayName
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 13
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = pad
    prompt.Triggered:Connect(function(player)
        setUpPlayer(player)
        local previous = currentCarByPlayer[player]
        if previous and previous.Parent then previous:Destroy() end
        -- Remove any e-moto/e-bike too, so a player never accumulates active rides.
        for _, existing in ipairs(carsFolder:GetChildren()) do
            if existing:GetAttribute("OwnerUserId") == player.UserId then existing:Destroy() end
        end
        local newCar = createCar(player, selectedSpec)
        currentCarByPlayer[player] = newCar
    end)
    pads[index] = pad
end

-- Gate graphics and invisible trigger volumes. These are original time-trial assets.
local raceStates = {}
local gateTouchTimes = {}

local function createRaceGate(name, position, kind, checkpointIndex, accent, labelText)
    local trigger = makePart(world, "GateTrigger_" .. name, Vector3.new(44, 13, 12), CFrame.new(position.X, position.Y + 5.5, position.Z), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, true, false)
    trigger.Transparency = 1
    trigger.CanTouch = true
    trigger.CanQuery = false
    trigger:SetAttribute("GateKind", kind)
    trigger:SetAttribute("CheckpointIndex", checkpointIndex or 0)
    trigger:SetAttribute("GateName", name)

    makePart(world, "GatePost", Vector3.new(1.4, 10, 1.4), CFrame.new(position + Vector3.new(-20, 5, 0)), accent, Enum.Material.Neon, true, false)
    makePart(world, "GatePost", Vector3.new(1.4, 10, 1.4), CFrame.new(position + Vector3.new(20, 5, 0)), accent, Enum.Material.Neon, true, false)
    local beam = makePart(world, "GateBeam", Vector3.new(42, 0.9, 1.5), CFrame.new(position + Vector3.new(0, 10, 0)), accent, Enum.Material.Neon, true, false)
    makeBillboard(beam, labelText, accent)

    trigger.Touched:Connect(function(hit)
        local car = hit:FindFirstAncestorOfClass("Model")
        if not car or car.Parent ~= carsFolder or not car:GetAttribute("IsNeonCar") then return end
        local seat = car:FindFirstChild("DriverSeat")
        local occupant = seat and seat.Occupant
        local player = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
        if not player then return end
        if car:GetAttribute("OwnerUserId") ~= player.UserId then return end

        local now = os.clock()
        local debounceKey = tostring(player.UserId) .. ":" .. name
        if gateTouchTimes[debounceKey] and now - gateTouchTimes[debounceKey] < 1.1 then return end
        gateTouchTimes[debounceKey] = now

        if kind == "Start" then
            if raceStates[player.UserId] then return end
            raceStates[player.UserId] = {startedAt = now, nextCheckpoint = 1}
            raceEvent:FireClient(player, "start", {total = 4, elapsed = 0})
            return
        end

        local state = raceStates[player.UserId]
        if not state then return end
        local elapsed = now - state.startedAt

        if kind == "Checkpoint" then
            if checkpointIndex == state.nextCheckpoint then
                state.nextCheckpoint += 1
                raceEvent:FireClient(player, "checkpoint", {
                    index = checkpointIndex,
                    total = 4,
                    elapsed = elapsed,
                })
            else
                raceEvent:FireClient(player, "wrong", {expected = state.nextCheckpoint, total = 4})
            end
            return
        end

        if kind == "Finish" then
            if state.nextCheckpoint <= 4 then
                raceEvent:FireClient(player, "wrong", {expected = state.nextCheckpoint, total = 4})
                return
            end
            local leaderstats = player:FindFirstChild("leaderstats")
            local credits = leaderstats and leaderstats:FindFirstChild("Credits")
            local bonus = math.max(0, math.floor(250 - elapsed * 1.5))
            local reward = 500 + bonus
            if credits then credits.Value += reward end
            raceEvent:FireClient(player, "complete", {elapsed = elapsed, reward = reward})
            raceStates[player.UserId] = nil
        end
    end)
    return trigger
end

createRaceGate("Start", Vector3.new(-220, 0.2, 56), "Start", 0, Color3.fromRGB(88, 255, 180), "TIME TRIAL  •  START")
createRaceGate("Checkpoint1", Vector3.new(-220, 0.2, -130), "Checkpoint", 1, Color3.fromRGB(66, 238, 220), "CHECKPOINT  01")
createRaceGate("Checkpoint2", Vector3.new(80, 0.2, -250), "Checkpoint", 2, Color3.fromRGB(66, 238, 220), "CHECKPOINT  02")
createRaceGate("Checkpoint3", Vector3.new(230, 0.2, 60), "Checkpoint", 3, Color3.fromRGB(66, 238, 220), "CHECKPOINT  03")
createRaceGate("Checkpoint4", Vector3.new(-100, 0.2, 220), "Checkpoint", 4, Color3.fromRGB(66, 238, 220), "CHECKPOINT  04")
createRaceGate("Finish", Vector3.new(-160, 0.2, 145), "Finish", 0, Color3.fromRGB(255, 174, 92), "TIME TRIAL  •  FINISH")

-- Simple world entry spawn, kept separate from the vehicle garage.
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "HarborSpawn"
spawnLocation.Size = Vector3.new(10, 1, 10)
spawnLocation.CFrame = CFrame.new(-275, 0.65, 145)
spawnLocation.Color = Color3.fromRGB(55, 83, 99)
spawnLocation.Material = Enum.Material.Metal
spawnLocation.Anchored = true
spawnLocation.Neutral = true
spawnLocation.Duration = 0
spawnLocation.Parent = world
makeBillboard(spawnLocation, "WELCOME TO NEON RIDGE", Color3.fromRGB(100, 255, 228))
local safetySpawn = Workspace:FindFirstChild("NeonRidgeSafetySpawn")
if safetySpawn then safetySpawn:Destroy() end
local startupPreview = Workspace:FindFirstChild("NeonRidgeStartupPreview")
if startupPreview then startupPreview:Destroy() end

-- Because the world is generated at runtime, move any character that spawned
-- before the SpawnLocation existed to a safe spot outside the beacon tower.
local function placeCharacterAtHarbor(player, character)
    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not root or not humanoid then return end
        task.wait(0.15)
        if player.Parent ~= Players or player.Character ~= character or humanoid.Health <= 0 then return end
        if humanoid.SeatPart then return end
        character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 3.5, 0))
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        placeCharacterAtHarbor(player, character)
    end)
    if player.Character then placeCharacterAtHarbor(player, player.Character) end
end)
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(character)
        placeCharacterAtHarbor(player, character)
    end)
    if player.Character then placeCharacterAtHarbor(player, player.Character) end
end

Players.PlayerRemoving:Connect(function(player)
    local car = currentCarByPlayer[player]
    if car and car.Parent then car:Destroy() end
    currentCarByPlayer[player] = nil
    raceStates[player.UserId] = nil
end)

print("[Neon Ridge] World built: coastal road loop, garage, three cars, time trial, and lighting.")
