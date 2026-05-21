# Packet 2B-9 — SideObjectiveNode Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Goal:** Add reusable optional/side objective placed mechanic extending `MechanicAreaBase`, delegating objective mutations to `ObjectiveStepController`, with tests and dev-room validation.

## Files added

| File | Purpose |
|------|---------|
| `src/missions/iso/authoring/mechanics/SideObjectiveNode.gd` | Side/optional objective node |
| `src/missions/iso/authoring/mechanics/SideObjectiveNode.gd.uid` | Godot-generated UID |
| `tests/mission_authoring/SideObjectiveNodeTest.gd` | 13 focused GdUnit4 tests |

## Files modified

| File | Change |
|------|--------|
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | Added `Objectives/DevSideObjective` |
| `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd` | `_configure_side_objectives()`, status lines, QuestManager snapshot/restore |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | Short `SideObjectiveNode` section |

## Existing systems reused

- `MechanicAreaBase` — `activate()`, requirements, success/failure effects, interaction routing
- `ObjectiveStepController` — activate/complete/fail/query objectives (wraps `QuestManager`)
- `MissionFactBridge` — mission flags for `objective_flag` persistence
- `RequirementSet` / `EffectSet` / `MissionEffectApplier`
- `MissionInteractionBridge` — `interact` / `on_interact` / `use` / `inspect_marker` compatibility

## Implementation summary

`SideObjectiveNode` provides `handle_objective()` which:

1. Returns `already_handled` when `handled` and not `stay_available_after_handled`
2. Calls `MechanicAreaBase.activate()` for requirement/effect evaluation (no duplication)
3. On activation success, calls `apply_objective_action()` via `ObjectiveStepController` (`ACTIVATE` / `COMPLETE` / `FAIL`)
4. Sets `handled` when `mark_handled_on_success` and action succeeds
5. Sets `objective_flag` via `MissionFactBridge` when configured

No direct `QuestManager` calls, no new objective manager, no mission rating/result UI.

**Fix during validation:** Renamed `_resolved_mission_id(context)` to `_mission_id_from_context(context)` to avoid shadowing `MechanicAreaBase._resolved_mission_id()`.

## ObjectiveStepController delegation

| `objective_action` | Controller call |
|--------------------|-----------------|
| `ACTIVATE` | `ObjectiveStepController.activate_objective(...)` |
| `COMPLETE` | `ObjectiveStepController.complete_objective(...)` |
| `FAIL` | `ObjectiveStepController.fail_objective(...)` |
| Status query | `ObjectiveStepController.is_objective_active/completed/failed(...)` |

Mission id resolved from `mission_id_override`, context, or `MissionFactBridge` patterns (same as other mechanics).

## Multiple-instance behavior

Each placed node uses instance-local `handled` and exports (`objective_id`, `objective_flag`, `mechanic_id`). No static shared state. Tests verify two nodes with distinct ids/flags do not cross-contaminate.

## Dev room example (`Objectives/DevSideObjective`)

- Mission: `mechanic_authoring_test`
- Pre-activates `dev_side_objective` on room ready via `ObjectiveStepController.activate_objective`
- Requires `dev_route_open` (from `Routes/DevRouteUnlock` after `dev_reward_collected`)
- Action: `COMPLETE` on `dev_side_objective`
- Sets `dev_side_objective_handled` and `dev_side_objective_effect_applied`
- Status label shows handled/effect/completed flags

**Validated chain (MCP runtime):** blocked without route → set `dev_route_open` → handle succeeds → flags/effect/completed true → repeat `already_handled`, availability false.

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `tests/mission_authoring/` | **145/145** pass (132 prior + 13 new) |
| GdUnit4 `SideObjectiveNodeTest.gd` | 13/13 pass |
| Godot LSP (`SideObjectiveNode.gd`, test, controller) | Clean (no diagnostics) |
| Godot MCP `validate_script` | Pass |
| Dev room runtime (MCP `execute_game_script`) | Route-gated objective flow OK |
| MainMenu smoke | Loads `MainMenu`, no new errors observed |
| Godot DAP | Not needed |

## Kimi K2.6 MCP

Not used.

## Safety confirmation

- No `project.godot`, autoload, production scene, Taco, `IsoMissionBase`, or Phase0J changes
- No `MissionModifierSet`, `SchemeCardTriggerNode`, `MutationActivatorNode`, route save schema, card manager, or mission rating UI
- No git commit/history changes

## Known limitations

- Uses existing `QuestManager` behavior only through `ObjectiveStepController`
- `objective_sound_key` is a placeholder
- No mission rating/result screen integration
- Dev room side objective requires route unlock chain (drawer → extraction → reward → route) for full manual playthrough; script smoke validates objective node directly with flag injection

## Recommended next step

Implement `MissionModifierSet` or begin production adoption of side objective nodes after Jake review.
