# Wrong Code Reachable Spawn Restore

Headless runtime probe directly called spawn_attack_guard_near_player("wrong_code_phase0kb"). Result: success, mode player_near, chosen/actual (-2338,185), distance 220, invalid 0. Wrong-code security events still route through the same shared selector and do not directly add persistent heat. Failed/invalid spawned guards are queue_freed and do not count functional.

## Assertions
- ASSERT wrong_code_reachable_guard_spawn_restored_or_runtime_validation_required == true
- ASSERT wrong_code_does_not_directly_increase_heat == true
- ASSERT failed_wrong_code_spawn_does_not_consume_cap == true
