# Camera / wrong-code spawn path

Both paths end in **`IsoMissionBase.spawn_attack_guard_near_player`** → **`_spawn_guard_for_spawn`**. Failure was synchronous tree mutation during physics flush, not resolver/cooldown.
