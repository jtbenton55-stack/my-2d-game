# Packet 2B-10 — Construction Kit Validation Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Goal:** Final dev-only validation pass for the plug-and-play mission construction kit: full mechanic chain, multi-instance isolation, unique authoring IDs, and construction-kit readiness (no production adoption).

## Files added

| File | Purpose |
|------|---------|
| `tests/mission_authoring/MissionConstructionKitIntegrationTest.gd` | 4 multi-instance isolation tests (Reward, Search, Route, SideObjective) |
| `reports/ai/2026-05-19_packet_2b10_construction_kit_validation_report.md` | This report |

## Files modified

| File | Change |
|------|--------|
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | Added `MultiInstance/` group (RewardA/B, SearchA/B, RouteA/B) |
| `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd` | `_configure_multi_instance()`, status lines for multi flags |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | Short “Multiple instances in one mission” section |

**No new mechanic scripts, managers, autoloads, or production scenes.**

## Systems validated

| Family | Dev sample | Validated |
|--------|------------|-----------|
| TriggerZone | A–E (always, locked, unlock, failure, dialogue) | Yes |
| LockedInteractionNode | DevLockedGate | Yes |
| SearchZone | DevSearchDrawer | Yes |
| ExtractionZone | DevExtractionZone (`complete_mission_on_success = false`) | Yes |
| InteractiveContainer | DevLocker | Yes |
| RewardNode | DevRewardPickup | Yes |
| RouteUnlockNode | DevRouteUnlock | Yes |
| SideObjectiveNode | DevSideObjective | Yes |
| MissionInteractionBridge | Room bridge | Yes (via node methods / prior packets) |
| RequirementSet / EffectSet | All samples | Yes |
| ObjectiveStepController | Side objective + tests | Yes |

## Full dev-room chain result

**Fresh play session (MCP `execute_game_script` after scene restart):**

| Step | Expected | Observed code |
|------|----------|---------------|
| Gate before unlock flag | Blocked | `requirements_failed` |
| UnlockTrigger (C) | Sets `dev_unlock_flag` | Flag true |
| Gate after unlock | Unlocks | `activation_succeeded` |
| Extraction before clue | Blocked | `requirements_failed` |
| Drawer search | Succeeds | `activation_succeeded` |
| Extraction after clue | Clean extract | `extraction_clean` |
| Locker open/search | Succeeds | `container_opened` |
| Reward collect | Succeeds | `reward_collected` |
| Route after reward | Unlocks | `route_unlocked` |
| Side objective after route | Completes | `side_objective_handled` |
| Failure trigger | Failure effect only | `dev_failure_effect_fired` true |
| Extraction mission complete | Off | `complete_mission_on_success` false; `pending_mission_id` empty |

**Repeat behavior:** Second interactions in same session return `already_unlocked`, `already_searched`, `already_collected`, `already_handled` as expected.

**Dialogue trigger:** `DialogueTrigger.interact()` runs without regression (simple dialogue effect path).

## Multiple-instance validation result

**Dev room `MultiInstance/` (MCP runtime):**

- RewardA collect → RewardB not collected; B flag false until B collected
- SearchA searched → SearchB not searched until B searched
- RouteA unlocked → RouteB not unlocked until B unlocked
- RewardA repeat → `already_collected`

**GdUnit `MissionConstructionKitIntegrationTest.gd` (4 tests):**

- Two `RewardNode`s — unique flags, `reward_id`, `source_id`, repeat codes
- Two `SearchZone`s — unique `searched_flag` / local `searched`
- Two `RouteUnlockNode`s — unique `route_id` / `route_flag` / `route_unlocked`
- Two `SideObjectiveNode`s — unique `objective_id` / flags / QuestManager state

No cross-contamination observed.

## Unique authoring data audit

All dev-room `mechanic_id` values are unique per placed node.

| Node | mechanic_id | Persistent id / flag |
|------|-------------|----------------------|
| AlwaysTrigger | `dev_always_trigger` | effect: `dev_always_trigger_fired` |
| UnlockTrigger | `dev_unlock_trigger` | effect: `dev_unlock_flag` |
| LockedTrigger | `dev_locked_trigger` | effect: `dev_locked_trigger_fired` |
| FailureTrigger | `dev_failure_trigger` | failure: `dev_failure_effect_fired` |
| DialogueTrigger | `dev_dialogue_trigger` | dialogue effect |
| DevLockedGate | `dev_locked_gate` | `dev_locked_gate_open` (flag + success effect — **intentional duplicate key**) |
| DevSearchDrawer | `dev_search_drawer` | `dev_drawer_searched`, `dev_drawer_found_clue` |
| DevExtractionZone | `dev_extraction_zone` | `dev_extraction_used`, `dev_clean_extraction` |
| DevLocker | `dev_locker` | `dev_locker_opened`, `dev_locker_searched`, `dev_locker_found_item` |
| DevRewardPickup | `dev_reward_pickup` | `reward_id` same as mechanic; `dev_reward_collected` |
| DevRouteUnlock | `dev_route_unlock` | `route_id` `dev_shortcut` (distinct from mechanic_id); `dev_route_open` |
| DevSideObjective | `dev_side_objective` | `objective_id` + `dev_side_objective_handled` |
| RewardA/B | `dev_multi_reward_a/b` | unique collected + effect flags |
| SearchA/B | `dev_multi_search_a/b` | unique searched flags |
| RouteA/B | `dev_multi_route_a/b` | unique route + open flags |

No accidental duplicate `mechanic_id` pairs found. `route_id` may differ from `mechanic_id` by design (`dev_shortcut` vs `dev_route_unlock`).

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `tests/mission_authoring/` | **149/149** pass (145 baseline + 4 integration) |
| Godot LSP | Clean on controller + integration test |
| Godot MCP dev room | Full chain + multi-instance OK |
| MainMenu smoke | Loads `MainMenu` |
| Godot DAP | Not needed |

## Kimi K2.6 MCP

Not used.

## Safety confirmation

- No `project.godot`, autoload, production scene, Taco, `IsoMissionBase`, Phase0J, or manager changes
- No `MissionModifierSet`, production adoption, visual tile painting, save schema, or card/route/mutation managers
- No git commit/history changes

## Known limitations

- Construction kit validated in **dev room only**; production Taco adoption is a separate packet (blueprint Packet 6)
- MCP full-chain script mutates live play state; restart scene for clean-step codes
- `MissionModifierSet` / scheme-card modifiers not implemented (deferred per roadmap)
- No mission rating/result UI

## Recommended next step

1. **Production adoption (Packet 6):** One non-critical Taco route/search/extraction slice using these nodes, keeping Phase0J path intact.  
2. **Or roadmap visual pass** before `MissionModifierSet` / heist-kit inventory per Jake’s priority.

**Construction kit status: READY for dev authoring and staged production adoption.**
