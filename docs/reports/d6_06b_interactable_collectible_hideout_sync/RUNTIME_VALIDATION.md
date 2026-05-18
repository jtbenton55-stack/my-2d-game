# D6-06B Runtime Validation

**Tool:** Godot MCP Pro (`play_scene`, `execute_game_script`)  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

## Checks performed

| Step | Result |
|------|--------|
| Play Taco editable scene | PASS |
| Auto-spawn 4 authored interactables | PASS (`d6_06_runtime_pickup_count=4`, path `phase0j_interactable`) |
| Nodes in `interactable` group | PASS (Phase0J `_ready`) |
| Collect via `_collect_with_state_adapter()` (same path as E-interact) | PASS — pending recorded, `real_system_updated: false` until commit |
| Collect all 4 types + `_commit_pending_authored_collectibles()` | PASS — `committed: 4` |
| GameState poop count after commit | PASS — `0 → 1` |
| Hideout flag `hideout_display:polaroid_taco_bell` | PASS — `true` after commit |
| `fail_level()` clears pending | PASS — `pending=0`, reason `mission_failed` |
| Duplicate attempt same id | PASS — `already_done: true` (separate call) |

## Not fully verified in MCP session

- **Player walk + E key** on proof nodes: `interact()` via MCP timed out (debugger pause / game command timeout); collection path validated through `_collect_with_state_adapter()` which `interact()` calls internally.
- **Visual HideoutHub shelf update:** manager flag verified; no hideout scene load in this pass.
- **Full mission exit completion flow:** commit API validated directly; not full playthrough to exit door.

## GdUnit4

No D6-06-specific tests found under `tests/`.

## Godot LSP

Workspace scan returned 0 issues after fixes. `validate_script` on `IsoMissionBase.gd` reported stale failure until `MissionCollectibleHideoutSync.gd` compile fix; editor `load()` succeeded after fix.

## DAP

Not required — state confirmed via MCP `execute_game_script` and runtime dictionaries.
