# 2026-07-03 - Taco Bell D6 Player-Facing Polish

## Goal

Implement the grouped D6 player-facing Taco polish packet after D5 manual QA signoff:

- Pause next-objective highlighting.
- HUD objective ticker plus stamina/poop-bag status continuation.
- Taco three-bag pickup/status contract.
- Mission result / return-to-hideout copy polish.
- First Sterling clue posting to the Evidence Board on Taco success.

## Mode

Stayed in accelerated grouped-milestone mode. The work used existing seams (`GameState`, `MissionPauseDataProvider`, `MissionHudDataProvider`, `MissionResult`, HUD, and pause menu) rather than adding a new manager.

## Files Changed

- `src/autoload/GameState.gd`
- `src/missions/ui/MissionPauseDataProvider.gd`
- `src/missions/ui/MissionHudDataProvider.gd`
- `src/ui/HUD.gd`
- `src/ui/MissionResult.gd`
- `src/ui/test_ui/pause_menu.gd`
- `scenes/ui/MissionResult.tscn`
- `tests/mission_authoring/PhaseD6PlayerFacingPolishTest.gd`
- `src/tools/editor/taco_bell_redesign_d6_player_facing_polish/phase0md6_player_facing_polish_static_validator.py`
- `docs/CHANGELOG.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`

## Implementation Notes

- `GameState.complete_mission()` and `fail_mission()` now annotate result payloads with mission name, return label, and poop-bag status.
- Taco success posts `taco_bell_sterling_route_invoice` through `ensure_and_discover_sterling_clue()`, which also updates `evidence_clues` through existing `record_evidence_clue()` behavior.
- Taco success result payload exposes `evidence_clues` and `next_steps` for `MissionResult.gd`.
- `MissionPauseDataProvider.get_next_objective_text()` identifies the next Taco beat from Phase0K/Quest facts and marks active objective rows with `is_next`.
- `src/ui/test_ui/pause_menu.gd` shows a `Next:` line and prefixes the matching active objective with `NEXT -`.
- `MissionHudDataProvider` uses the same next-objective seam and exposes `poop_bags_collected_this_attempt`, `poop_bag_bonus_target`, and `poop_bag_status_text`.
- HUD poop line now displays inventory plus run progress as `Bags: N | Run: X/3`.
- `MissionResult.tscn` has a taller result panel and smaller result text for the richer result payload.

## Validation

- PASS: `python src/tools/editor/taco_bell_redesign_d6_player_facing_polish/phase0md6_player_facing_polish_static_validator.py`
- PASS: `python src/tools/editor/taco_bell_redesign_d5_01/phase0md5_01_static_validator.py`
- PASS: `git diff --check`
- BLOCKED: `godot --version` failed because `godot` is not on PATH in this OpenCode shell.

## Not Run

- GdUnit4 tests were added but not run in this shell because no Godot executable is currently available on PATH.
- Taco production scene runtime smoke was not run from OpenCode for the same reason.

## Manual QA Checklist

1. Launch `taco_bell_drop` from the hideout mission board.
2. Confirm HUD shows the current objective and `Bags: N | Run: X/3` while in mission.
3. Open pause Objectives and confirm `Next:` plus `NEXT -` on the matching active objective.
4. Pick up Taco poop bags and confirm HUD run progress advances toward `3/3`.
5. Complete Taco through Louis exit and confirm result screen shows the poop-bag status, Evidence Board clue, and next steps.
6. Return to hideout and open Evidence Board; confirm Louis's Sterling route invoice is present/discovered.

## Risks / Follow-Ups

- The result screen is still a Label-based layout, not a full scrollable rich result screen; very long future result adapters could still overflow.
- GdUnit and runtime scene proof remain required once Godot is available.
- If manual QA shows the Taco next-objective order should prefer code gate before bag, update only `MissionPauseDataProvider.get_next_objective_text()`.
