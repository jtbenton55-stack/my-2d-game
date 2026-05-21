# Packet 2B-8 — RouteUnlockNode Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Goal:** Add reusable route/shortcut/traversal unlock mechanic extending `MechanicAreaBase`, with tests and dev-room validation.

## Files added

| File | Purpose |
|------|---------|
| `src/missions/iso/authoring/mechanics/RouteUnlockNode.gd` | Route unlock node |
| `tests/mission_authoring/RouteUnlockNodeTest.gd` | 12 focused GdUnit4 tests |

## Files modified

| File | Change |
|------|--------|
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | Added `Routes/DevRouteUnlock` |
| `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd` | `_configure_routes()` + status flags |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | Short `RouteUnlockNode` section |

## Existing systems reused

- `MechanicAreaBase` — `activate()`, requirements, success/failure effects
- `RequirementSet` / `MissionFactBridge` — gating (mission flags, cards via facts)
- `EffectSet` / `MissionEffectApplier` — route effects
- `MissionInteractionBridge` — interaction routing
- Collision/visual patterns from `LockedInteractionNode`

## Implementation summary

`RouteUnlockNode` provides `unlock_route()` which calls `MechanicAreaBase.activate()`. On success:

- Sets `route_unlocked` when `mark_unlocked_on_success`
- Sets `route_flag` via `MissionFactBridge`
- Applies `apply_route_targets()` for visuals and collisions
- Returns `route_unlocked` result code

No route manager, mutation manager, card logic in node, or save schema changes.

## Requirement/effect delegation

- Card/route gating uses `RequirementSet` only (e.g. `mission_flag`, `selected_card` facts).
- Dev room gates on `dev_reward_collected` via mission-flag requirement.
- Success effects (e.g. `dev_route_effect_applied`) applied through `EffectSet` in `activate()`.

## Visual/collision target behavior

- `nodes_to_show` / `nodes_to_hide` — CanvasItem/Node2D visibility
- `collisions_to_enable` / `collisions_to_disable` — CollisionShape2D, CollisionPolygon2D, Area2D
- Missing paths produce warnings, no crashes
- `starts_unlocked` applies targets without effects

## Dev room example (`Routes/DevRouteUnlock`)

- Requires `dev_reward_collected` (from `Rewards/DevRewardPickup`)
- Sets `dev_route_open`, `dev_route_effect_applied`
- Shows `RouteOpenVisual`, hides `RouteBlockedVisual`
- Disables `RouteBlocker`, enables `RoutePassageShape`

Runtime flow validated: blocked → collect reward → unlock route → repeat `already_unlocked`.

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `tests/mission_authoring/` | **132/132** pass (120 prior + 12 new) |
| Godot LSP | Clean |
| Godot MCP `validate_script` | Pass |
| Dev room runtime | Full reward→route chain OK |
| MainMenu smoke | Loads (`MainMenu`) |
| Godot DAP | Not needed |

## Kimi K2.6 MCP

Not used.

## Safety confirmation

- No `project.godot`, autoload, production scene, Taco, `IsoMissionBase`, or Phase0J changes
- No `SideObjectiveNode`, route manager, mutation manager, card manager, or save schema
- No git commit/history changes

## Known limitations

- No route manager or production route migration
- `unlock_sound_key` is a placeholder
- Card gating demonstrated via `RequirementSet` delegation, not a dedicated card route script

## Recommended next step

Implement `SideObjectiveNode` or begin production adoption of route unlock nodes after Jake review.
