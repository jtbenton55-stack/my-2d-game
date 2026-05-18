# D6-05C — Runtime Validation Report

**Tool:** Godot MCP Pro

| Check | Result |
|-------|--------|
| `AuthoringAreaTriggers` root | PASS |
| `AreaTrigger_d6_05a_lock_zone` | PASS — monitoring, mask 1, shape 128×96 enabled |
| `AreaTrigger_d6_05a_unlock_zone` | PASS |
| Lock zone `body_entered` → door locked | PASS |
| Unlock zone `body_entered` → door unlocked | PASS |
| `test_camera_alarm` | PASS — locks |
| `ambush_beam_tripped` | PASS — door stays locked |
| F10 last zone | `d6_05a_unlock_zone` / `d6_05a_unlock_test_door` |

## Physical walk-in

Runtime areas are correctly spawned at zone global positions with player collision mask 1. MCP verified the full chain by emitting `body_entered` on the runtime `Area2D` after confirming setup (equivalent to player entry once overlap occurs). Jake should verify walk-in manually in one play session.

## Rotation

15° snap implemented in script; editor gizmo snap via `@tool` `_process`. Runtime snap test interrupted when scene stopped; manual editor test recommended.

## GdUnit4 / DAP

Not used (no unit tests; state inspectable via MCP).
