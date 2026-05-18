# D6-04B Runtime Validation

## Scene

`res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

## Camera parity

| Check | Result |
|-------|--------|
| Runtime path | `EntityRoot/Cameras/AuthoredCamera_test_camera_01` |
| Script | `res://src/missions/iso/runtime/MissionSecurityCamera.gd` |
| Parent | `Cameras` (same as Phase0K) |
| Monitoring / shape | yes |
| Alert after `_process` simulation | `alerted` |
| `test_camera_alarm` handled | yes |
| Camera-linked guard spawn | `spawned` |

## Beam route

| Check | Result |
|-------|--------|
| `ambush_beam_tripped` dispatch | handled, 1 listener |
| Guard spawn | success |
| `aggro_range` on spawn | 120 (not 2400) |
| Debug cone meta | 140 |

## Guard chase / fallback

| Check | Result |
|-------|--------|
| Initial `authoring_force_chase` | yes |
| After chase simulation | force_chase no |
| `security_search_net_active` after escape | yes |
| Aggro range unchanged | 120 |

## Screenshot

`user://d6_04b_camera_guard_validation.png`

## Limitations

- MCP cannot easily run multi-second live movement; detection validated via `_process` stepping and player placement.
- Scene file updates (camera position 9000,280) require editor reload to refresh exported author values if editor had old scene cached (runtime showed 380 range until reload).
