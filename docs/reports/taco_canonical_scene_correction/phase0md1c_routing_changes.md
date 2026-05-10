# 0M-D1C — Routing changes (Phase 3)

## Authoritative **playable expanded** iso scene

`res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

## Legacy **smaller / bake-output** scene (preserved)

`res://scenes/missions_iso/TacoBellIso_Editable.tscn` — **not deleted**, **not edited** in this pass.

## Code edits

1. **`HideoutMissionBoardController.gd`** — `TACO_BELL_SCENE` → `…RedesignTest.tscn`
2. **`HideoutStationCatalog.gd`** — same constant (mission slot 0 path)
3. **`SceneManager.gd`** — debug `taco_bell_drop` iso override → `…RedesignTest.tscn`
4. **`IsoMissionDebugPanel.gd`** — `_on_restart` → `…RedesignTest.tscn`
5. **`phase0md1b_rt_static_validator.py`** — add `TacoBellIso_Editable_RedesignTest.tscn` to required scene existence list (both tacos must exist for D1B-RT preflight)

## Docs

- **`DECISIONS.md`** — amended 2026-05-10 entry: playable vs bake-output roles
- **`CHANGELOG.md`** — 0M-D1C bullet

## Non-goals honored

No `.tscn` map edits, no `project.godot`, no `Player.gd` / `player.tscn` changes for routing.
