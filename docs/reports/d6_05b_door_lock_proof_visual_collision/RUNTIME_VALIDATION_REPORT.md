# D6-05B — Runtime Validation Report

**Scene:** `TacoBellIso_Editable_RedesignTest.tscn`  
**Tool:** Godot MCP Pro

| Check | Result |
|-------|--------|
| `CollisionShape2D` present | PASS — size (140, 32) |
| Initial unlocked | `collision_shape_enabled: false`, layer 0 |
| `d6_05a_lock_test_door` | PASS — locked, shape enabled, layer 4 |
| `d6_05a_unlock_test_door` | PASS — unlocked, shape disabled, layer 0 |
| `test_camera_alarm` | PASS — locks door |
| `ambush_beam_tripped` | PASS — door **stays locked** (`ambush_unlocked_door: false`) |
| F10 collision fields | PASS — `collision_enabled`, `collision_layer` |
| Script compile | PASS |

**World position (door):** ~(7970, 369)

**Screenshot:** MCP capture timed out this session; manual verification: red/green block + labels at proof cluster.

**GdUnit4:** No relevant tests — skipped.  
**DAP:** Not needed — collision state inspected via `get_runtime_debug_state()`.
