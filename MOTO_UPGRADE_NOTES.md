# Neon Ridge — E-Moto / E-Bike Upgrade

## Added original rides
- **VOLT E-MOTO**: compact electric dirt-bike silhouette, number plate, fork tubes, battery pack, motor case, fenders, neon trim and headlamp.
- **TRAIL E-BIKE**: lighter trail-bike silhouette with pedal crank, pedals, frame, reflectors and a different handling tune.
- Both spawn from their own proximity pads using E, automatically seat the player, and use the existing force-based server vehicle controller.
- Cylinder wheel geometry was corrected so wheel axles run left-to-right and the client rotates the wheels around their axle.
- Spawning either bike removes a previously active car/bike for that player.

## Important physics limitation
These are an arcade prototype using Roblox `VehicleSeat` input and force-based chassis movement. They are not yet a physically complete motorcycle simulation: the visible wheels are welded decorative geometry, suspension travel and wheel-ground raycasts are not implemented, and a physically realistic lean/steer controller needs iterative Studio tuning. This is disclosed rather than advertised as perfect.

## Studio test plan
1. Open `NeonRidge_Starter.rbxlx`, press Play, and verify the two extra spawn pads appear near the garage.
2. Press E at VOLT E-MOTO and TRAIL E-BIKE pads; confirm each ride appears and the player can sit.
3. Check W/S throttle, A/D steering, Space drift, R recovery, road collisions and spawn overlap with two players.
4. Test at low speed first. Check upright stability, wheel clipping, seat orientation, braking distance, and network ownership.
5. Test touch controls on a device/emulator. Adjust `Power`, `MaxSpeed`, `Grip`, and `Steering` attributes in `NeonRidgeMotoPack.server.lua` only after observing actual handling.

## Rebuild
`make_place.py` embeds the current server and client scripts into the `.rbxlx` place. The ZIP contains the source files and this checklist.
