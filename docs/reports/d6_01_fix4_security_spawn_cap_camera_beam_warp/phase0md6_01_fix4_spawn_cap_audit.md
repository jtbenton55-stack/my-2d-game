# Spawn cap / active guard accounting audit

## Cap definition

- **`_get_security_spawn_cap()`** in `IsoMissionBase.gd`: `mini(6, 4 + GameState.get_mission_heat(mission_id))`.

## Root cause of “cap reached (4)” with no visible guards

1. **`_flush_deferred_security_guard_spawns`** called **`_spawn_guard_for_spawn`**, then treated **`EntityRoot/Enemies` last child** as the new attack guard.
2. **`Enemies`** already contains patrol / definition guards; the last child is often **not** the newly spawned reinforcement.
3. Meta **`security_response_spawn`** could attach to the **wrong** node while **`attack_guard_spawned`** still incremented → cap filled with **no** functional security response guard.

## Plan

- Return the **actual** spawned `Node2D` from **`_spawn_guard_for_spawn`**.
- Gate spawns using **`_count_live_security_response_guards()`** (meta `security_response_spawn`, valid, in-tree).
- Sync **`attack_guard_spawned`** to live count after successful spawn only.

See `phase0md6_01_fix4_spawn_cap_audit.json`.
