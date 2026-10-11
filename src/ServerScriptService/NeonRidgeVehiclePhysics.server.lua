-- Server-authoritative arcade driving forces for Neon Ridge.
-- Place this Script in ServerScriptService beside NeonRidgeWorld.server.lua.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local carsFolder = Workspace:WaitForChild("NeonRidgeCars")
local remotes = ReplicatedStorage:WaitForChild("NeonRidgeRemotes")
local handbrakeEvent = remotes:WaitForChild("Handbrake")
local actionEvent = remotes:WaitForChild("VehicleAction")

local controllers = {}
local payoutClock = {}
local attributeClock = 0

local function playerDrivingCar(player, car)
    if typeof(car) ~= "Instance" or not car:IsA("Model") then return false end
    if car.Parent ~= carsFolder or not car:GetAttribute("IsNeonCar") then return false end
    if car:GetAttribute("OwnerUserId") ~= player.UserId then return false end
    local seat = car:FindFirstChild("DriverSeat")
    if not seat or not seat:IsA("VehicleSeat") or not seat.Occupant then return false end
    return Players:GetPlayerFromCharacter(seat.Occupant.Parent) == player
end

local function setupCar(car)
    if not car:IsA("Model") or not car:GetAttribute("IsNeonCar") or controllers[car] then return end
    local root = car.PrimaryPart or car:FindFirstChild("Chassis")
    local seat = car:FindFirstChild("DriverSeat")
    if not root or not root:IsA("BasePart") or not seat or not seat:IsA("VehicleSeat") then return end

    local attachment = root:FindFirstChild("NRPhysicsAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "NRPhysicsAttachment"
        attachment.Parent = root
    end

    local driveForce = root:FindFirstChild("NRDriveForce")
    if not driveForce then
        driveForce = Instance.new("VectorForce")
        driveForce.Name = "NRDriveForce"
        driveForce.Attachment0 = attachment
        driveForce.RelativeTo = Enum.ActuatorRelativeTo.World
        driveForce.ApplyAtCenterOfMass = true
        driveForce.Force = Vector3.zero
        driveForce.Parent = root
    end

    local yawTorque = root:FindFirstChild("NRYawTorque")
    if not yawTorque then
        yawTorque = Instance.new("Torque")
        yawTorque.Name = "NRYawTorque"
        yawTorque.Attachment0 = attachment
        yawTorque.RelativeTo = Enum.ActuatorRelativeTo.World
        yawTorque.Torque = Vector3.zero
        yawTorque.Parent = root
    end

    controllers[car] = {
        root = root,
        seat = seat,
        driveForce = driveForce,
        yawTorque = yawTorque,
        lastOccupant = nil,
        lastPayout = 0,
    }

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        if humanoid then
            local player = Players:GetPlayerFromCharacter(humanoid.Parent)
            if player then
                pcall(function() root:SetNetworkOwner(player) end)
            end
            car:SetAttribute("Handbrake", false)
        else
            car:SetAttribute("Handbrake", false)
            pcall(function() root:SetNetworkOwnershipAuto() end)
        end
    end)
end

for _, car in ipairs(carsFolder:GetChildren()) do setupCar(car) end
carsFolder.ChildAdded:Connect(function(car)
    task.defer(setupCar, car)
end)
carsFolder.ChildRemoved:Connect(function(car)
    controllers[car] = nil
    payoutClock[car] = nil
end)

handbrakeEvent.OnServerEvent:Connect(function(player, car, isHeld)
    if not playerDrivingCar(player, car) then return end
    car:SetAttribute("Handbrake", isHeld == true)
end)

actionEvent.OnServerEvent:Connect(function(player, action, car)
    if action ~= "reset" or not playerDrivingCar(player, car) then return end
    local root = car.PrimaryPart
    if not root then return end
    local current = car:GetPivot()
    local uprightPosition = current.Position + Vector3.new(0, 5, 0)
    local look = current.LookVector
    local horizontalLook = Vector3.new(look.X, 0, look.Z)
    if horizontalLook.Magnitude < 0.05 then horizontalLook = Vector3.new(0, 0, -1) end
    car:PivotTo(CFrame.lookAt(uprightPosition, uprightPosition + horizontalLook.Unit))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    car:SetAttribute("Handbrake", false)
end)

RunService.Heartbeat:Connect(function(dt)
    for car, controller in pairs(controllers) do
        if not car.Parent or not controller.root.Parent then
            controllers[car] = nil
            continue
        end

        local root = controller.root
        local seat = controller.seat
        local occupant = seat.Occupant
        if not occupant or occupant.Health <= 0 then
            controller.driveForce.Force = Vector3.zero
            controller.yawTorque.Torque = Vector3.zero
            car:SetAttribute("Handbrake", false)
            continue
        end

        local player = Players:GetPlayerFromCharacter(occupant.Parent)
        local mass = math.max(root.AssemblyMass, 1)
        local velocity = root.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = horizontalVelocity.Magnitude

        local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        if forward.Magnitude < 0.05 then forward = Vector3.new(0, 0, -1) end
        forward = forward.Unit
        local right = Vector3.new(root.CFrame.RightVector.X, 0, root.CFrame.RightVector.Z)
        if right.Magnitude < 0.05 then right = Vector3.new(1, 0, 0) end
        right = right.Unit

        local forwardSpeed = horizontalVelocity:Dot(forward)
        local sidewaysSpeed = horizontalVelocity:Dot(right)
        local throttle = math.clamp(seat.ThrottleFloat, -1, 1)
        local steering = math.clamp(seat.SteerFloat, -1, 1)
        local power = car:GetAttribute("Power") or 32
        local maxSpeed = car:GetAttribute("MaxSpeed") or 115
        local grip = car:GetAttribute("Grip") or 2.6
        local steeringRate = car:GetAttribute("Steering") or 1
        local handbrake = car:GetAttribute("Handbrake") == true

        local engineScale = 1
        if throttle > 0 and forwardSpeed > maxSpeed * 0.9 then
            engineScale = math.clamp((maxSpeed - forwardSpeed) / (maxSpeed * 0.1), 0, 1)
        elseif throttle < 0 and forwardSpeed < -maxSpeed * 0.42 then
            engineScale = math.clamp((-maxSpeed * 0.42 - forwardSpeed) / (maxSpeed * 0.1), 0, 1)
        end
        local engineAcceleration = forward * (throttle * power * engineScale)

        -- Speed-dependent drag, sideways tire grip, and a handbrake mode for controlled slides.
        local dragCoefficient = 0.11 + speed * 0.00125
        local dragAcceleration = -horizontalVelocity * dragCoefficient
        local lateralGrip = handbrake and grip * 0.18 or grip
        local lateralAcceleration = -right * sidewaysSpeed * lateralGrip
        local rollingBrake = Vector3.zero
        if math.abs(throttle) < 0.05 and speed > 0.8 then
            rollingBrake = -horizontalVelocity.Unit * math.min(speed * 0.6, 12)
        end
        if handbrake and math.abs(forwardSpeed) > 8 then
            rollingBrake += -forward * math.sign(forwardSpeed) * 5.5
        end

        controller.driveForce.Force = (engineAcceleration + dragAcceleration + lateralAcceleration + rollingBrake) * mass

        -- Yaw torque increases with speed but is limited by a stable arcade handling curve.
        local yawStrength = mass * (2.4 + math.min(speed, maxSpeed) * 0.12) * steeringRate
        if handbrake then yawStrength *= 1.2 end
        controller.yawTorque.Torque = Vector3.new(0, -steering * yawStrength, 0)

        if player and handbrake and speed > 35 and math.abs(sidewaysSpeed) > 7 then
            local now = os.clock()
            if now - controller.lastPayout >= 0.85 then
                controller.lastPayout = now
                local leaderstats = player:FindFirstChild("leaderstats")
                local credits = leaderstats and leaderstats:FindFirstChild("Credits")
                if credits then
                    local reward = math.clamp(math.floor(math.abs(sidewaysSpeed) / 5), 1, 8)
                    credits.Value += reward
                end
            end
        end
    end
end)

-- Publish a low-frequency speed value for the HUD without replicating at render rate.
task.spawn(function()
    while true do
        task.wait(0.1)
        for car, controller in pairs(controllers) do
            if car.Parent and controller.root.Parent then
                local velocity = controller.root.AssemblyLinearVelocity
                car:SetAttribute("CurrentSpeed", Vector3.new(velocity.X, 0, velocity.Z).Magnitude)
            end
        end
    end
end)

print("[Neon Ridge] Vehicle physics ready: force-based acceleration, grip, yaw steering, drift payouts, reset validation.")
