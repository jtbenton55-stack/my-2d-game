# Camera Reachable Spawn Restore

Headless runtime probe directly called spawn_attack_guard_near_player("garage_fallback_camera"). Result: success, mode player_near, requested (-2558,185), chosen/actual (-2338,185), distance 220, invalid 0. This verifies the shared camera spawn entry point no longer leaves the guard at the far-left patrol-snapped position. Full human cone exposure/cooldown playtest remains manual.

## Assertions
- ASSERT camera_reachable_guard_spawn_restored_or_runtime_validation_required == true
- ASSERT no_camera_event_spam == true
- ASSERT camera_midrun_heat_policy_preserved == true
