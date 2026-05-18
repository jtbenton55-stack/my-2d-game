# D6-06 Runtime Validation (Godot MCP Pro)

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Date:** 2026-05-17

## Spawn check

`GameplayRoot/RuntimeSystems/AuthoredCollectibles` contained 4 children:

- `AuthoredPickup_d6_06_proof_poop`
- `AuthoredPickup_d6_06_proof_money`
- `AuthoredPickup_d6_06_proof_polaroid`
- `AuthoredPickup_d6_06_proof_tiny`

`d6_06_runtime_pickup_count` = 4

## Collection check (try_collect at player position)

| Pickup | Result |
|--------|--------|
| poop | `collected` — poop inv count 1 |
| money | `proof_collected` |
| polaroid | `collected` |
| tiny | `collected` |

After collection, duplicate `try_collect` returned empty (pickups freed by one-shot).

## Security regression (same session)

- `d6_03_security_router_active`: true
- `d6_05a_test_door_lock_state`: unlocked

## Screenshot

`user://d6_06_collectible_proof.png` (960×540)

## Limitations

- MCP used direct `try_collect()` rather than walking player into overlap (acceptable per task fallback).
- Editor compile log may show autoload identifier warnings when scripts reload outside play mode; play mode succeeded.
