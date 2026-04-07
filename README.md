# Tornado — Roblox Physics Simulation

A server-side tornado simulation using parametric math and TweenService to animate debris absorption and realistic tornado movement.

## How it works

`spawnTornado` handles the full lifecycle of a tornado:

1. A cloud ring animates down from above using `generateCloudCircle` (scale-in + rotation tween).
2. The tornado MeshPart descends and grows to its full `width` over 2 seconds, absorbing nearby parts during expansion.
3. Once fully formed, the tornado roams randomly within a zone for a random lifetime (10–16 seconds), continuously rotating, moving the cloud model in sync, and running `absorbAttempt` every 0.2 seconds.
4. On expiry, the tornado shrinks and the cloud disperses. Any still-flying parts are fade-destroyed.

Supports two types: `normal` and `fire`. Fire tornadoes char absorbed parts black (CrackedLava material) and can spread fire to nearby parts via `setFire`, which burns, darkens, then destroys the part and optionally spreads further.

## Key formulas

**Absorption chance** (exponential decay with distance, scaled by wind/mass):
```
P = (windspeed^(1 + ws/2000) / mass^(1 + m/2000)) * exp(-dist^1.5 / divisor) / 2
```

**Fire spread chance** (similar decay, scaled by fire spread parameter):
```
P = exp(-dist^1.5 / (3*fireSpread + tornadoSize + 50)) * (10*fireSpread + 10) / 1000
```

Both results are randomized slightly on each call to avoid determinism.

## Parameters (`spawnTornado`)

| Parameter | Description |
|-----------|-------------|
| `windspeeds` | Absorption power — higher = pulls heavier/farther parts |
| `width` | Tornado radius (`realSize = width * 4`) |
| `movementSpeed` | Studs per second across the zone |
| `tornadoType` | `"normal"` or `"fire"` |

## Absorption behavior

On each `absorbAttempt`, parts in the hitbox that pass the probability check are either faded out (`destroyPart`) or animated into the vortex (`absorbPart`), with a cap of 50 spiralling parts at once. `absorbPart` uses two lerp phases: a quadratic pull toward the funnel wall, then a tight upward spiral into the core.

## Author

Roblox project, 2025