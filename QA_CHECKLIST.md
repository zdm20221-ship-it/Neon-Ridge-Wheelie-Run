# Neon Ridge QA checklist

This checklist separates source review from tests that must be run in Roblox Studio.

## Static review passes completed for this package

1. **Project hierarchy:** four server scripts belong under `ServerScriptService`; the HUD LocalScript belongs under `StarterPlayer > StarterPlayerScripts`.
2. **Remote contracts:** the world script creates `NeonRidgeRemotes.Handbrake`, `VehicleAction`, and `RaceUpdate`; the client and physics script wait for the same names.
3. **Vehicle creation:** each car has a `Chassis` primary part, a `DriverSeat`, distinct attributes, welded visual body parts, and decorative wheel motors.
4. **Spawn lifecycle:** a player's existing car is removed before a replacement spawns; the selected garage spec is captured for that prompt; ownership is stored on the car.
5. **Physics signals:** controller setup is connected to `NeonRidgeCars.ChildAdded`, forces are attached to the chassis, and removed models are removed from the controller table.
6. **Driving math:** velocity is reduced to the horizontal plane for speed and drift calculations; acceleration, drag, grip, handbrake, and yaw torque use the vehicle's assembly mass.
7. **Remote validation:** handbrake and reset requests require the player's owned car and require that the player is actually seated in it.
8. **Race order:** the server tracks start time and the next expected checkpoint; checkpoints 1–4 must be crossed in order before the finish awards credits.
9. **HUD / input:** the HUD handles vehicle entry/exit, keyboard Space and R, touch drift press/release, credit updates, chase camera, and race messages.
10. **Visual / setup integrity:** map generation is self-contained and uses standard Parts, materials, and Lighting effects; no imported asset IDs or external packages are required.
11. **Startup safety:** the saved place contains a floor, spawn, and full static road/city preview; a boot guard creates a recovery scene and logs a warning if key world elements are missing.
12. **Motorcycle wheel geometry:** tire cylinders use an axle along X, sit near the chassis ground plane, and the client spins those wheels around X.

## Required Studio playtest before publishing

- [ ] Open `NeonRidge_Starter.rbxlx`; confirm the saved safety floor, spawn and neon preview are visible before Play.
- [ ] Press **Play** and watch **View → Output** for errors.
- [ ] Confirm Output reports the boot check passed; if not, inspect the warning and any earlier red script errors.
- [ ] Confirm the island, road loop, city, garage, streetlights, and six gates appear.
- [ ] Walk to each of the three car garage pads and both e-moto/e-bike pads; the name and color should match the pad.
- [ ] Confirm the player is seated automatically after spawning and can accelerate, reverse, and steer.
- [ ] Check that the camera follows the car while driving and returns to the character on exit.
- [ ] Hold Space while moving, then release it; confirm grip changes while held and the HUD remains responsive.
- [ ] Hold Space through a sustained sideways slide and confirm credits increase only during a qualifying slide.
- [ ] Press R while seated; confirm the car is moved upward, upright, and its velocity resets.
- [ ] Touch the green start gate, drive through checkpoints 1, 2, 3, and 4 in order, then finish; confirm the reward appears.
- [ ] Skip a checkpoint and try the finish; it should report the next checkpoint instead of granting the reward.
- [ ] Test touch controls on a phone/tablet emulator or actual device, especially the hold-to-drift release behavior.
- [ ] Use **Test → Start** with two players and verify each player can spawn a car and receive their own credits/race updates.
- [ ] Publish only after the Output window is clean and the handling feels right in repeated playtests.

A source review cannot replace Roblox Studio runtime validation. The checklist is intentionally left unchecked until you perform those tests in Studio.
