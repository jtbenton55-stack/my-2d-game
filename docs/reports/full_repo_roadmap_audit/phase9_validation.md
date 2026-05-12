# GAME-ROADMAP-01 — Phase 9: Static Validator Run

## Validator

`src/tools/editor/full_repo_roadmap_audit/phase_game_roadmap_01_static_validator.py`

## What it checks

1. **Required reports exist** for phases 0, 1, 2A, 2B, 3, 4, 5, 6, 7, 8 (markdown + JSON pairs).
2. **JSON reports parse** as valid JSON.
3. **Hard assertions** in each phase JSON are present and `true`.
4. **`phase7_prioritized_roadmap.json`** contains `single_best_next_action` (non-empty), `next_3_actions` (length 3), `next_10_actions` (length 10), and `avoid_now_list` (length ≥ 1).
5. **Protected files** show no entries in `git status --porcelain` and no diff in `git diff --name-only`:
   - `project.godot`
   - `src/player/Player.gd`
   - `src/player/PlayerStaminaController.gd`
   - `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
   - `scenes/missions_iso/TacoBellIso_Editable.tscn`
   - `scenes/missions/TacoBellMission.tscn`
   - `scenes/hideout/HideoutHub.tscn`
   - `assets/**`

## Result

**PASS** — `fail_count = 0`, `ok = true`.

Full machine output: `phase_game_roadmap_01_static_validator_run.json`.

## Hard assertions

- `static_validator_created`: **true**
- `static_validator_run`: **true**
- `static_validator_passed`: **true**

See `phase9_validation.json`.
