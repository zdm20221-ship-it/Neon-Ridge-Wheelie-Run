-- Neon Ridge original e-moto / e-bike pack. Place in ServerScriptService.
-- Uses the existing server-authoritative NeonRidgeVehiclePhysics controller.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cars = Workspace:WaitForChild("NeonRidgeCars")
local world = Workspace:WaitForChild("NeonRidgeWorld")
local black = Color3.fromRGB(20, 23, 28)
local steel = Color3.fromRGB(100, 112, 126)
local function part(model, root, name, size, cf, color, material, shape)
 local p = Instance.new("Part")
 p.Name=name; p.Size=size; p.CFrame=root.CFrame*cf; p.Color=color; p.Material=material or Enum.Material.Metal
 if shape then p.Shape=shape end
 p.Anchored=false; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.Parent=model
 local w=Instance.new("WeldConstraint"); w.Part0=root; w.Part1=p; w.Parent=p
 return p
end
local specs={
 {Id="VoltE",DisplayName="VOLT E-MOTO",Power=29,MaxSpeed=92,Grip=3.6,Steering=0.72,Color=Color3.fromRGB(255,105,48),Accent=Color3.fromRGB(65,245,220),Kind="Moto"},
 {Id="TrailE",DisplayName="TRAIL E-BIKE",Power=20,MaxSpeed=66,Grip=4.1,Steering=0.9,Color=Color3.fromRGB(114,240,95),Accent=Color3.fromRGB(75,185,255),Kind="Bike"},
}
local function build(player,spec)
 -- Enforce one active ride per player across the car and e-moto garages.
 for _, existing in ipairs(cars:GetChildren()) do
  if existing:GetAttribute("OwnerUserId") == player.UserId then existing:Destroy() end
 end
 local lane=(player.UserId%5)-2
 local model=Instance.new("Model"); model.Name=spec.Id.."_"..player.UserId
 for k,v in pairs({IsNeonCar=true,OwnerUserId=player.UserId,VehicleId=spec.Id,DisplayName=spec.DisplayName,Power=spec.Power,MaxSpeed=spec.MaxSpeed,Grip=spec.Grip,Steering=spec.Steering,Handbrake=false,CurrentSpeed=0,VehicleType=spec.Kind}) do model:SetAttribute(k,v) end
 local root=Instance.new("Part"); root.Name="Chassis"; root.Size=Vector3.new(1.5,1.05,3.5); root.CFrame=CFrame.new(-220+lane*5,2,112); root.Transparency=1; root.Anchored=false; root.CanCollide=true; root.CustomPhysicalProperties=PhysicalProperties.new(0.8,0.7,0.03,1,1); root.Parent=model; model.PrimaryPart=root
 -- Longitudinal frame, battery pack, seat, and distinct body panels.
 part(model,root,"Frame",Vector3.new(.28,.32,2.35),CFrame.new(0,.18,.05),steel)
 part(model,root,"BatteryPack",Vector3.new(.62,.66,.78),CFrame.new(0,-.03,.12),black,Enum.Material.Metal)
 part(model,root,"BatteryAccent",Vector3.new(.66,.08,.62),CFrame.new(0,.18,.12),spec.Accent,Enum.Material.Neon)
 part(model,root,"Seat",Vector3.new(.48,.2,1.0),CFrame.new(0,.58,.25),black,Enum.Material.SmoothPlastic)
 part(model,root,"RearFender",Vector3.new(.46,.1,.8),CFrame.new(0,.48,1.1),spec.Color,Enum.Material.SmoothPlastic)
 part(model,root,"FrontForkL",Vector3.new(.09,.95,.1),CFrame.new(-.18,.05,-1.15)*CFrame.Angles(math.rad(-12),0,0),steel)
 part(model,root,"FrontForkR",Vector3.new(.09,.95,.1),CFrame.new(.18,.05,-1.15)*CFrame.Angles(math.rad(-12),0,0),steel)
 part(model,root,"Handlebar",Vector3.new(1.0,.09,.12),CFrame.new(0,.68,-1.25),black)
 part(model,root,"Headlight",Vector3.new(.32,.25,.12),CFrame.new(0,.53,-1.45),Color3.fromRGB(225,250,255),Enum.Material.Neon)
 part(model,root,"SidePanelL",Vector3.new(.08,.42,.55),CFrame.new(-.34,.2,-.25)*CFrame.Angles(0,0,math.rad(-12)),spec.Color,Enum.Material.SmoothPlastic)
 part(model,root,"SidePanelR",Vector3.new(.08,.42,.55),CFrame.new(.34,.2,-.25)*CFrame.Angles(0,0,math.rad(12)),spec.Color,Enum.Material.SmoothPlastic)
 part(model,root,"TailLamp",Vector3.new(.26,.12,.1),CFrame.new(0,.5,1.3),Color3.fromRGB(255,60,80),Enum.Material.Neon)
 for _,z in ipairs({-1.25,1.22}) do
  local wheel=part(model,root,z<0 and "FrontWheel" or "RearWheel",Vector3.new(.34,.78,.78),CFrame.new(0,-.1,z),Color3.fromRGB(24,26,31),Enum.Material.Rubber,Enum.PartType.Cylinder)
  part(model,root,z<0 and "FrontHub" or "RearHub",Vector3.new(.36,.26,.26),CFrame.new(0,-.1,z),spec.Accent,Enum.Material.Metal,Enum.PartType.Cylinder)
 end
 if spec.Kind=="Moto" then
  part(model,root,"MotorCase",Vector3.new(.48,.42,.5),CFrame.new(0,-.27,.55),steel,Enum.Material.Metal,Enum.PartType.Cylinder)
  part(model,root,"FrontNumberPlate",Vector3.new(.52,.48,.12),CFrame.new(0,.45,-1.28)*CFrame.Angles(math.rad(-12),0,0),spec.Color,Enum.Material.SmoothPlastic)
 else
  part(model,root,"PedalCrank",Vector3.new(.6,.08,.08),CFrame.new(0,-.48,.25),steel)
  part(model,root,"LeftPedal",Vector3.new(.24,.07,.12),CFrame.new(-.35,-.48,.25),black)
  part(model,root,"RightPedal",Vector3.new(.24,.07,.12),CFrame.new(.35,-.48,.25),black)
  part(model,root,"FrontReflector",Vector3.new(.2,.08,.08),CFrame.new(0,.27,-1.4),spec.Accent,Enum.Material.Neon)
 end
 local seat=Instance.new("VehicleSeat"); seat.Name="DriverSeat"; seat.Size=Vector3.new(.8,.45,.8); seat.CFrame=root.CFrame*CFrame.new(0,.72,.25); seat.Transparency=1; seat.Anchored=false; seat.CanCollide=false; seat.Massless=true; seat.HeadsUpDisplay=false; seat.Parent=model
 local weld=Instance.new("WeldConstraint"); weld.Part0=root; weld.Part1=seat; weld.Parent=seat
 model.Parent=cars
 task.delay(0.3,function()
  if player.Parent ~= Players or not model.Parent or not seat.Parent then return end
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if humanoid and humanoid.Health > 0 then seat:Sit(humanoid) end
 end)
end
-- Simple original garage prompt pads; existing cars remain available.
local garage=world:FindFirstChild("Garage") or world
for i,spec in ipairs(specs) do
 local pad=Instance.new("Part"); pad.Name=spec.Id.."_DisplayPad"; pad.Size=Vector3.new(5,.35,5); pad.Anchored=true; pad.CanCollide=true; pad.Material=Enum.Material.Neon; pad.Color=spec.Accent; pad.CFrame=CFrame.new(-232+(i-1)*10,.2,101); pad.Parent=garage
 local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Spawn ride"; prompt.ObjectText=spec.DisplayName; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.HoldDuration=.25; prompt.MaxActivationDistance=12; prompt.Parent=pad
 prompt.Triggered:Connect(function(player) build(player,spec) end)
end
print("[Neon Ridge] E-moto and e-bike pack loaded")
