-- Neon Ridge HUD, chase camera, keyboard/mouse input and mobile handbrake button.
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("NeonRidgeRemotes")
local handbrakeEvent = remotes:WaitForChild("Handbrake")
local actionEvent = remotes:WaitForChild("VehicleAction")
local raceEvent = remotes:WaitForChild("RaceUpdate")

local existing = playerGui:FindFirstChild("NeonRidgeHUD")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "NeonRidgeHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local COLORS = {
    panel = Color3.fromRGB(12, 20, 31),
    panel2 = Color3.fromRGB(22, 34, 48),
    text = Color3.fromRGB(238, 246, 250),
    muted = Color3.fromRGB(153, 174, 190),
    mint = Color3.fromRGB(91, 247, 211),
    amber = Color3.fromRGB(255, 177, 94),
    red = Color3.fromRGB(255, 93, 111),
}

local function create(className, parent, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(object, radius)
    create("UICorner", object, {CornerRadius = UDim.new(0, radius or 10)})
end

local function addStroke(object, color3, transparency)
    create("UIStroke", object, {
        Color = color3 or COLORS.mint,
        Thickness = 1.2,
        Transparency = transparency or 0.24,
    })
end

local function addLabel(parent, name, text, position, size, font, textSize, color3, align)
    return create("TextLabel", parent, {
        Name = name,
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = font or Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = color3 or COLORS.text,
        TextSize = textSize or 16,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    })
end

-- Brand card.
local brand = create("Frame", gui, {
    Name = "BrandCard",
    Position = UDim2.fromOffset(22, 22),
    Size = UDim2.fromOffset(302, 76),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
})
addCorner(brand, 13)
addStroke(brand, COLORS.mint, 0.32)
create("Frame", brand, {
    Name = "AccentBar",
    Position = UDim2.fromOffset(0, 12),
    Size = UDim2.new(0, 4, 1, -24),
    BackgroundColor3 = COLORS.mint,
    BorderSizePixel = 0,
})
addLabel(brand, "BrandTitle", "NEON RIDGE", UDim2.fromOffset(17, 8), UDim2.new(1, -28, 0, 35), Enum.Font.GothamBlack, 25, COLORS.text)
addLabel(brand, "BrandSub", "COASTAL MOTOR CLUB  /  FREE ROAM", UDim2.fromOffset(19, 43), UDim2.new(1, -28, 0, 20), Enum.Font.GothamMedium, 10, COLORS.muted)

-- Credits wallet.
local wallet = create("Frame", gui, {
    Name = "WalletCard",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -22, 0, 22),
    Size = UDim2.fromOffset(202, 62),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
})
addCorner(wallet, 12)
addStroke(wallet, COLORS.amber, 0.42)
addLabel(wallet, "WalletCaption", "GARAGE CREDITS", UDim2.fromOffset(13, 6), UDim2.new(1, -20, 0, 17), Enum.Font.GothamBold, 10, COLORS.muted)
local creditsLabel = addLabel(wallet, "Credits", "0 CR", UDim2.fromOffset(13, 24), UDim2.new(1, -20, 0, 28), Enum.Font.GothamBlack, 22, COLORS.amber)

-- Context / race status banner.
local statusCard = create("Frame", gui, {
    Name = "StatusCard",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 24),
    Size = UDim2.new(0, 390, 0, 64),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
})
addCorner(statusCard, 12)
addStroke(statusCard, COLORS.mint, 0.55)
local statusTitle = addLabel(statusCard, "StatusTitle", "FREE ROAM", UDim2.fromOffset(13, 6), UDim2.new(1, -26, 0, 24), Enum.Font.GothamBlack, 16, COLORS.mint, Enum.TextXAlignment.Center)
local statusSub = addLabel(statusCard, "StatusSub", "Find the glowing garage to choose a car", UDim2.fromOffset(13, 31), UDim2.new(1, -26, 0, 21), Enum.Font.GothamMedium, 12, COLORS.muted, Enum.TextXAlignment.Center)

-- Speedometer panel, visible while seated in a Neon Ridge car.
local speedCard = create("Frame", gui, {
    Name = "SpeedCard",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -24, 1, -24),
    Size = UDim2.fromOffset(254, 158),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
    Visible = false,
})
addCorner(speedCard, 16)
addStroke(speedCard, COLORS.mint, 0.18)
addLabel(speedCard, "SpeedCaption", "GROUND SPEED", UDim2.fromOffset(17, 9), UDim2.new(1, -34, 0, 18), Enum.Font.GothamBold, 10, COLORS.muted)
local speedLabel = addLabel(speedCard, "SpeedValue", "0", UDim2.fromOffset(14, 23), UDim2.new(0, 162, 0, 78), Enum.Font.GothamBlack, 63, COLORS.text)
local unitsLabel = addLabel(speedCard, "SpeedUnits", "KM/H", UDim2.fromOffset(172, 54), UDim2.new(0, 65, 0, 24), Enum.Font.GothamBlack, 14, COLORS.mint, Enum.TextXAlignment.Right)
local vehicleLabel = addLabel(speedCard, "VehicleName", "SOLAR GT", UDim2.fromOffset(17, 101), UDim2.new(1, -34, 0, 21), Enum.Font.GothamBold, 12, COLORS.amber)
local speedHint = addLabel(speedCard, "SpeedHint", "WASD DRIVE   •   R RESET", UDim2.fromOffset(17, 126), UDim2.new(1, -34, 0, 19), Enum.Font.GothamMedium, 10, COLORS.muted)

-- Keyboard hints stay visible on desktop; mobile players also get a hold-to-drift button.
local controlsCard = create("Frame", gui, {
    Name = "ControlsCard",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 22, 1, -24),
    Size = UDim2.fromOffset(300, 69),
    BackgroundColor3 = COLORS.panel,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
})
addCorner(controlsCard, 12)
addStroke(controlsCard, COLORS.muted, 0.72)
addLabel(controlsCard, "ControlsTitle", "DRIVE CONTROLS", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 18), Enum.Font.GothamBlack, 11, COLORS.mint)
addLabel(controlsCard, "ControlsSub", "WASD / ARROWS  •  SPACE DRIFT  •  R RECOVER", UDim2.fromOffset(12, 29), UDim2.new(1, -24, 0, 22), Enum.Font.GothamMedium, 10, COLORS.text)

local driftButton = create("TextButton", gui, {
    Name = "MobileDriftButton",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -292, 1, -28),
    Size = UDim2.fromOffset(112, 66),
    BackgroundColor3 = COLORS.panel2,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBlack,
    Text = "DRIFT\nHOLD",
    TextColor3 = COLORS.amber,
    TextSize = 15,
    Visible = UserInputService.TouchEnabled,
    AutoButtonColor = true,
})
addCorner(driftButton, 13)
addStroke(driftButton, COLORS.amber, 0.22)

-- Reflow the HUD for narrow touch screens instead of letting cards overlap.
if UserInputService.TouchEnabled then
    brand.Position = UDim2.fromOffset(12, 12)
    brand.Size = UDim2.fromOffset(260, 66)
    wallet.AnchorPoint = Vector2.new(0, 0)
    wallet.Position = UDim2.fromOffset(12, 86)
    wallet.Size = UDim2.fromOffset(125, 50)
    statusCard.AnchorPoint = Vector2.new(1, 0)
    statusCard.Position = UDim2.new(1, -12, 0, 86)
    statusCard.Size = UDim2.fromOffset(170, 50)
    statusTitle.Position = UDim2.fromOffset(6, 4)
    statusTitle.Size = UDim2.new(1, -12, 0, 19)
    statusTitle.TextSize = 12
    statusSub.Position = UDim2.fromOffset(6, 24)
    statusSub.Size = UDim2.new(1, -12, 0, 19)
    statusSub.TextSize = 9
    speedCard.Size = UDim2.fromOffset(180, 138)
    speedCard.Position = UDim2.new(1, -10, 1, -10)
    speedLabel.Size = UDim2.new(0, 105, 0, 70)
    speedLabel.TextSize = 48
    unitsLabel.Position = UDim2.fromOffset(120, 49)
    unitsLabel.Size = UDim2.fromOffset(48, 22)
    unitsLabel.TextSize = 10
    vehicleLabel.Position = UDim2.fromOffset(15, 91)
    vehicleLabel.Size = UDim2.new(1, -28, 0, 19)
    speedHint.Position = UDim2.fromOffset(15, 113)
    speedHint.Size = UDim2.new(1, -28, 0, 17)
    speedHint.Text = "TOUCH DRIVE  •  R RESET"
    controlsCard.Visible = false
    driftButton.Position = UDim2.new(1, -200, 1, -10)
    driftButton.Size = UDim2.fromOffset(92, 58)
end

-- Compact race timer/progress label is separate so the HUD remains readable during driving.
local raceTimer = addLabel(gui, "RaceTimer", "", UDim2.new(0.5, -120, 0, UserInputService.TouchEnabled and 145 or 94), UDim2.fromOffset(240, 30), Enum.Font.GothamBlack, 17, COLORS.text, Enum.TextXAlignment.Center)
raceTimer.Visible = false

local currentCar = nil
local wasDriving = false
local handbrakeHeld = false
local raceStartedAt = nil
local raceBaseElapsed = 0
local wheelAngles = setmetatable({}, {__mode = "k"})
local camera = Workspace.CurrentCamera
local savedFieldOfView = camera.FieldOfView

local function setStatus(title, subtitle, color3)
    statusTitle.Text = title
    statusTitle.TextColor3 = color3 or COLORS.mint
    statusSub.Text = subtitle
end

local function releaseHandbrake()
    if handbrakeHeld and currentCar then
        handbrakeEvent:FireServer(currentCar, false)
    end
    handbrakeHeld = false
end

local function setHandbrake(held)
    held = held == true
    if not currentCar or not currentCar.Parent then
        handbrakeHeld = false
        return
    end
    if handbrakeHeld == held then return end
    handbrakeHeld = held
    handbrakeEvent:FireServer(currentCar, held)
    if held then
        driftButton.BackgroundColor3 = Color3.fromRGB(77, 51, 35)
    else
        driftButton.BackgroundColor3 = COLORS.panel2
    end
end

driftButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setHandbrake(true)
    end
end)
driftButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setHandbrake(false)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Space and currentCar then
        setHandbrake(true)
        return
    end
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R and currentCar then
        actionEvent:FireServer("reset", currentCar)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        setHandbrake(false)
    end
end)

raceEvent.OnClientEvent:Connect(function(eventName, data)
    data = data or {}
    if eventName == "start" then
        raceStartedAt = os.clock()
        raceBaseElapsed = 0
        raceTimer.Visible = true
        raceTimer.Text = "TIME TRIAL  •  0 / 4 CHECKPOINTS"
        setStatus("TIME TRIAL STARTED", "Follow the cyan gates in route order", COLORS.mint)
    elseif eventName == "checkpoint" then
        raceBaseElapsed = data.elapsed or raceBaseElapsed
        raceStartedAt = os.clock() - raceBaseElapsed
        raceTimer.Visible = true
        raceTimer.Text = string.format("CHECKPOINT %d / %d  •  %.1f S", data.index or 0, data.total or 4, raceBaseElapsed)
        setStatus("CHECKPOINT CLEARED", "Keep following the cyan gates", COLORS.mint)
    elseif eventName == "wrong" then
        setStatus("WRONG ORDER", string.format("Hit checkpoint %d next", data.expected or 1), COLORS.red)
    elseif eventName == "complete" then
        raceStartedAt = nil
        raceTimer.Visible = true
        raceTimer.Text = string.format("FINISHED  •  %.2f SECONDS", data.elapsed or 0)
        setStatus("ROUTE COMPLETE", string.format("+%d garage credits  •  Run it again for a better time", data.reward or 0), COLORS.amber)
    end
end)

local function getCharacterHumanoid()
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function findDrivenCar()
    local humanoid = getCharacterHumanoid()
    local seatPart = humanoid and humanoid.SeatPart
    if not seatPart or not seatPart:IsA("VehicleSeat") then return nil end
    local model = seatPart:FindFirstAncestorOfClass("Model")
    if model and model:GetAttribute("IsNeonCar") then
        return model
    end
    return nil
end

local function leaveDrivingMode()
    if not wasDriving then return end
    wasDriving = false
    releaseHandbrake()
    currentCar = nil
    speedCard.Visible = false
    camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    local humanoid = getCharacterHumanoid()
    if humanoid then camera.CameraSubject = humanoid end
    camera.FieldOfView = savedFieldOfView
    setStatus("FREE ROAM", "Find the glowing garage to choose a car", COLORS.mint)
end

RunService.RenderStepped:Connect(function(dt)
    camera = Workspace.CurrentCamera
    local detectedCar = findDrivenCar()
    if detectedCar ~= currentCar then
        if currentCar then releaseHandbrake() end
        currentCar = detectedCar
    end

    if currentCar and currentCar.Parent and currentCar.PrimaryPart then
        if not wasDriving then
            wasDriving = true
            savedFieldOfView = camera.FieldOfView
            setStatus("DRIVE READY", "Build speed, then hold SPACE to drift", COLORS.mint)
        end
        speedCard.Visible = true
        local speed = currentCar:GetAttribute("CurrentSpeed") or currentCar.PrimaryPart.AssemblyLinearVelocity.Magnitude
        local kmh = math.floor(speed * 1.008 + 0.5)
        speedLabel.Text = tostring(kmh)
        vehicleLabel.Text = string.upper(currentCar:GetAttribute("DisplayName") or "NEON RIDGE CAR")
        speedHint.Text = "WASD DRIVE   •   R RESET"

        if raceStartedAt then
            local elapsed = os.clock() - raceStartedAt
            raceTimer.Text = string.format("TIME TRIAL  •  %.1f SECONDS", elapsed)
        end

        -- Smooth third-person camera follows behind and slightly above the vehicle.
        local root = currentCar.PrimaryPart
        local velocity = root.AssemblyLinearVelocity
        local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local cameraDistance = 17 + math.clamp(horizontalSpeed / 25, 0, 5)
        local cameraHeight = 6.3 + math.clamp(horizontalSpeed / 35, 0, 2.5)
        local cameraPosition = root.CFrame:PointToWorldSpace(Vector3.new(0, cameraHeight, cameraDistance))
        local focus = root.Position + root.CFrame.LookVector * 9 + Vector3.new(0, 1.8, 0)
        local target = CFrame.lookAt(cameraPosition, focus)
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = camera.CFrame:Lerp(target, 1 - math.exp(-6 * dt))
        camera.FieldOfView = 70 + math.clamp(horizontalSpeed / 18, 0, 8)
    else
        leaveDrivingMode()
    end

    -- Animate wheel visuals for every visible car (the server still owns vehicle physics).
    local carsFolder = Workspace:FindFirstChild("NeonRidgeCars")
    if carsFolder then
        for _, car in ipairs(carsFolder:GetChildren()) do
            if car:IsA("Model") and car.PrimaryPart then
                local root = car.PrimaryPart
                local wheelSpeed = root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
                for _, descendant in ipairs(root:GetChildren()) do
                    if descendant:IsA("Motor6D") and descendant.Name == "WheelMotor" then
                        wheelAngles[descendant] = (wheelAngles[descendant] or 0) + wheelSpeed * dt / 0.58
                        descendant.Transform = CFrame.Angles(wheelAngles[descendant], 0, 0)
                    end
                end
            end
        end
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    local credits = leaderstats and leaderstats:FindFirstChild("Credits")
    if credits then
        creditsLabel.Text = string.format("%d CR", credits.Value)
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(0.2)
    camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    local humanoid = getCharacterHumanoid()
    if humanoid then camera.CameraSubject = humanoid end
end)

print("[Neon Ridge] Client HUD ready: speedometer, chase camera, race timer, drift and reset controls.")
