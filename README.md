# Tornado — Roblox Physics Simulation
 
Two tornado simulations (one client prototype, one full server implementation) using parametric math and TweenService to animate debris absorption and realistic tornado movement.
 
## Versions
 
**Client prototype** (`StarterPlayer/.../LocalScript`) — Simple version. A single static tornado uses `GetPartsInPart` on a hitbox each frame, calculates per-part absorption probability based on mass, distance, and wind speed, then animates absorbed parts spiralling into the vortex using coroutines and timed lerps.
 
**Server implementation** (`ServerScriptService/Script`) — Full version with additional features:
- Procedural tornado shape (cone, stovepipe, wedge) using particle emitters sized per height
- Sinusoidal funnel oscillation controlled by a live `AMOUNT_OF_SIN_TAKEN` variable that smoothly transitions between random targets
- Random movement across a zone using periodic `ORIGINAL_POS` updates
- Lightning spawning coroutine (random positions under the cloud base)
- Animated cloud ring with scale-in and rotation tweens
- Fire tornado variant: absorbed parts turn black/cracked lava, fire spreads to nearby parts
- Absorption chance formula based on mass, wind speed, tornado size, and distance; separate fire spread formula
 
## Key formulas
 
Both use exponential absorption chance: `P = (windspeed^(1 + ws/2000) / mass^(1 + m/2000)) * exp(-dist^1.5 / divisor) / 2`
 
## Author
 
Roblox project, 2025