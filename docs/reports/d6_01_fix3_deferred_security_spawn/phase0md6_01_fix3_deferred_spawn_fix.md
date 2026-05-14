# Deferred spawn fix

`spawn_attack_guard_near_player` appends `source_id` to `_pending_security_guard_source_ids` and schedules **`call_deferred("_flush_deferred_security_guard_spawns")`**. Flush performs `_spawn_guard_for_spawn` + meta + reposition + patrol + counters.
