# D6-05D — Runtime Validation Report

**Tool:** Godot MCP Pro

| Step | lock_state | collision_enabled | layer |
|------|------------|-------------------|-------|
| Start unlocked | unlocked | false | 0 |
| `d6_05a_lock_test_door` (zone) | locked | **true** | 4 |
| `d6_05a_unlock_test_door` | unlocked | false | 0 |
| `test_camera_alarm` | locked | true | 4 |
| `ambush_beam_tripped` | locked (no unlock) | true | 4 |
| Lock after 45° rotation | locked | true | 4 |

Zone lock dispatch: `handled: true`, listener `DoorLock_Lock_Author`.

F10: visual `locked`, collision `true`, no mismatch.

**GdUnit4 / DAP:** Not used.

**Walk-through:** Not automated; physics verified via runtime state inspection.
