# Packet 2B-5 — ExtractionZone Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Goal:** Add reusable mission extraction / conditional exit mechanic extending `MechanicAreaBase`, with tests and dev-room validation.

## Files added

| File | Purpose |
|------|---------|
| `src/missions/iso/authoring/mechanics/ExtractionZone.gd` | Reusable extraction zone |
| `src/missions/iso/authoring/mechanics/ExtractionZone.gd.uid` | Godot-generated UID |
| `tests/mission_authoring/ExtractionZoneTest.gd` | 14 focused GdUnit4 tests |

## Files modified

| File | Change |
|------|--------|
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | Added `Exits/DevExtractionZone` sample |
| `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd` | `_configure_exits()` + status flags |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | Short `ExtractionZone` section |

## Existing systems reused

- `MechanicAreaBase` — requirements, `activate()`, success/failure effects, interaction groups
- `RequirementSet` / `EffectSet` / `MissionEffect`
- `ObjectiveStepController` — required/optional objective gating and reporting
- `MissionFactBridge` — alert state read, extraction flag write
- `MissionCompletionBridge.request_complete()` — mission completion (no direct `GameState.complete_mission()` from zone)
- `MissionInteractionBridge` — `interact` / `on_interact` / `use` / `inspect_marker` routing

## Implementation summary

`ExtractionZone` adds extraction-specific state (`extracted`, `last_extraction_result`) and outcome selection:

1. Early return for `already_extracted` when not `stay_available_after_extract`
2. `can_extract()` — enabled, base requirements, required objectives
3. On pass: `activate()` for base requirement/success path
4. Outcome: `clean` | `messy` (alerted + `messy_if_alerted`) | `failed_alerted` (`fail_if_alerted`)
5. Apply `clean_exit_effects` or `messy_exit_effects`; set `extraction_flag`; optional `MissionCompletionBridge.request_complete()`
6. Standard result dict: `ok`, `code`, `message`, `source_id`, `details`

Base requirement failure calls `activate()` so failure effects stay consistent with other mechanics.

## Objective gating

- `required_objective_ids` block extraction via `ObjectiveStepController.is_objective_completed()`
- Missing objectives return `missing_required_objectives` with `missing` list in details
- `optional_objective_ids` are reported in result details (`completed` / `incomplete`) but do not block extraction

## Mission completion bridge

- When `complete_mission_on_success == true`, calls `MissionCompletionBridge.request_complete(mission_id, context)`
- Dev room sets `complete_mission_on_success = false` to avoid ending the test session
- Alert-failure path does not request completion

## Dev room example (`Exits/DevExtractionZone`)

- Prompt: `Press E: Extract`
- Requires `dev_drawer_found_clue` (from `Searches/DevSearchDrawer`)
- On success: `dev_extraction_used`, `dev_clean_extraction` (clean exit effect)
- `complete_mission_on_success = false`

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `tests/mission_authoring/` | **98/98** pass (84 prior + 14 new) |
| Godot LSP `ExtractionZone.gd` | Clean |
| Godot LSP `ExtractionZoneTest.gd` | Clean |
| Godot MCP `validate_script` ExtractionZone | Stale false-negative parse error (same pattern as SearchZone / ObjectiveStepController); LSP + GdUnit authoritative |
| Godot MCP `validate_script` controller | Pass |
| Dev room runtime (`execute_game_script`) | Blocked before clue (`requirements_failed`); after search: `extraction_clean`, flags set |
| MainMenu smoke | `MainMenu.tscn` loads; no Packet 2B-5 parse/autoload errors |
| Godot DAP | Not needed |

## Kimi K2.6 MCP

Not used.

## Safety confirmation

- No `project.godot` changes
- No new autoloads
- No production scene / Taco / `IsoMissionBase` / Phase0J changes
- No `InteractiveContainer`, `RewardNode`, `RouteUnlockNode`, `SideObjectiveNode`
- No git commit/push/history changes

## Known limitations

- Production mission migration not done
- No messy-alert dev toggle in test room (alert path covered by unit tests only)
- MCP `validate_script` may report false parse errors on new `class_name` scripts until editor reload

## Recommended next step

Packet 2B-6 or blueprint next item: `InteractiveContainer` or wire first production extraction using `ExtractionZone` behind a feature flag after Jake review.
