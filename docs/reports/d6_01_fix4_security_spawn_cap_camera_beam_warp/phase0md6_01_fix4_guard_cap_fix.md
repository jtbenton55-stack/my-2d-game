# Guard cap accounting fix

- Gate **`spawn_attack_guard_near_player`** and flush loop on **`_count_live_security_response_guards() >= cap`**.
- **`_spawn_guard_for_spawn`** returns **`Node2D`**; null on failure → **no** meta/counter update.
- **`attack_guard_spawned`** synced to **live** count after successful reinforcement.

See `phase0md6_01_fix4_guard_cap_fix.json`.
