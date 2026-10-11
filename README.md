# Neon Ridge — Roblox Studio starter project

**Neon Ridge** is an original, stylized coastal driving game starter for Roblox Studio. It is not a Project Wheelie clone: it uses a different name, a fictional coastal city, original procedural scenery, fictional cars, and a checkpoint time-trial loop.

## Included

- Procedurally built coastal island, asphalt loop, lane markings, a small skyline, streetlights, trees, a garage, and neon race gates.
- Three fictional cars: **Solar GT**, **Harbor XR**, and **Summit RS**.
- Force-based arcade driving: acceleration, speed-sensitive drag, lateral grip, steering torque, reverse, and a hold-to-drift handbrake.
- Server-validated vehicle reset and drift-credit rewards.
- A saved-in-place safety floor/spawn and boot guard that creates a visible recovery test area if the main map fails to initialize.
- A four-checkpoint time trial with ordered checkpoints and a finish reward.
- Custom HUD, credits counter, speedometer, third-person chase camera, timer, and a touch-screen drift button.
- No external car models, music, images, or third-party packages are required.

## Fastest way to open it

1. Download `NeonRidge_Starter.rbxlx` and open it with Roblox Studio.
2. The file now includes a saved-in-place safety floor, spawn, and a full static road/city preview, so the viewport should not be empty while scripts initialize.
3. Press **Play** (F5). The server script generates the full map. Walk to the garage and use the **E** prompt on a ride pad; the selected ride should spawn.
4. Drive to the green **TIME TRIAL — START** gate. Pass the four cyan checkpoints in order, then cross the orange finish gate.
5. If the full map does not appear after 12 seconds, the boot guard should create a labeled recovery test area and print a warning in **View → Output**. Save or copy any red errors from Output so the exact failing line can be diagnosed.

The `.rbxlx` is a text-format Roblox place file. The saved Workspace includes a safe floor/spawn and a full static map preview; the server boot guard also builds a recovery test area if the full world is missing key objects. The `src` folder contains the same scripts in plain text so you can inspect, edit, or copy them individually.

## Controls

| Action | Keyboard / mouse | Touch devices |
|---|---|---|
| Accelerate / reverse | W / S or arrow keys | Roblox vehicle-seat controls |
| Steer | A / D or arrow keys | Roblox vehicle-seat controls |
| Drift / handbrake | Hold Space | Hold **DRIFT** |
| Recover the vehicle | R | Keyboard is supported when attached |
| Choose a vehicle | Walk to the garage pad and press E | Walk to the garage pad and tap the prompt |

## Script layout

- `src/ServerScriptService/NeonRidgeBootGuard.server.lua` — checks the full map startup and creates a safe recovery test area if key world pieces are missing.
- `src/ServerScriptService/NeonRidgeWorld.server.lua` — environment, lighting, car garage, credits, time-trial gates, rewards, and vehicle creation.
- `src/ServerScriptService/NeonRidgeVehiclePhysics.server.lua` — vehicle forces, yaw steering, speed readout, drift payouts, and validated reset/handbrake remotes.
- `src/ServerScriptService/NeonRidgeMotoPack.server.lua` — original VOLT E-MOTO and TRAIL E-BIKE spawn pads and ride models.
- `src/StarterPlayer/StarterPlayerScripts/NeonRidgeClient.client.lua` — HUD, camera, controls, touch drift button, and time-trial messaging.

## Editing in Studio

The environment is deliberately assembled from standard Roblox Parts and built-in materials. Change the route in `NeonRidgeWorld.server.lua` by editing the `route` vector list; change car handling in the `carSpecs` table; and adjust the force/drag/grip calculations in `NeonRidgeVehiclePhysics.server.lua`.

To publish it, use **File → Publish to Roblox** from Studio and give it your own original title, description, thumbnail, and icon. Keep the game name and promotional art original. No tool can guarantee that a game is legally risk-free; avoid reusing another game's code, assets, map layout, branding, screenshots, or distinctive presentation.

## Important testing note

The XML and package integrity can be checked outside Studio, but Roblox Studio's physics engine, script runtime, client controls, and Output cannot be executed from this environment. Before publishing, run the playtest checklist in `QA_CHECKLIST.md`, fix any Studio Output errors, and test on both keyboard and touch controls. The boot guard is a recovery measure, not proof that all gameplay systems work. Treat this as a starter/prototype, not a certified release build.
