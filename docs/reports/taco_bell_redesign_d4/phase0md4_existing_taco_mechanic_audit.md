# 0M-D4 — Existing Taco Bell mechanic audit

Evidence sources: `IsoMissionBase.gd`, `Phase0J*.gd`, `Phase0K*.gd`, `MissionSceneResolver.gd`, `MissionPauseDataProvider.gd`, `MissionObjectiveBridge.gd`, `MissionToolSurfaceHelper.gd`, `Player.gd` (read-only), `TacoBellIso_Editable_RedesignTest.tscn` grep, `TacoBellExpandedLayoutValidator.gd` / `MissionBlockoutValidator.gd` beam/gate separation notes.

## Must-not-forget crosswalk

| Requirement | Current repo signal | Gap / note |
| --- | --- | --- |
| Beam once per attempt | `alarm_triggered:garage_entry_beam` + one-shot branch disables monitoring | Confirm **all** beam Area2D instances tied to that alarm_id; Louis route must not re-fire incorrectly. |
| Louis bypasses real challenge | `bypasses_challenge_id = "garage_entry_beam"` on Louis route markers | **MechanicRouter** still labels ROUTE_* as `INSPECT_ONLY_DEFERRED` — bypass may be **layout-only** until D5 wires gameplay skip for beam penalties/alarm. |
| Code gate ≠ beam | Separate controllers + validator rules in tooling | Good separation in design; ensure player UX labels differ in HUD/pause copy. |
| Counters reset on restart | `_reset_attempt_runtime_state` | **QuestManager / Phase0K** may need explicit reset on reload — `MissionObjectiveBridge.reset_runtime_objectives_for_mission` is **empty**. |
| Pause owns Obj/Scheme/Clues | `MissionPauseDataProvider.get_pause_payload` | Ensure `mission_id` is non-empty in pause context for `taco_bell_drop`. |
| Poop bags aimed | Player targeting + `MissionToolSurfaceHelper` | Mission must continue to expose `deploy_poop_bag_decoy_at` / `handle_tool_use`. |
| Sprint / dodge | Confirmed by user | Regression-test only in D5. |
| No animation dependency | Walk/idle optional | OK. |
| RedesignTest playable | `MissionSceneResolver` | OK. |

## Classification table (summary)

See `phase0md4_existing_taco_mechanic_audit.json` for per-mechanic `classification` enum.

**Theme:** Most **Phase0J/K** scripts are **Taco-scene-local adapters** today. **Bridges (D2)** exist but **reset + single source of truth** for objectives is the weakest seam (stub + dual writers).

## Spaghetti / duplication risks

1. **Triple objective writes:** `IsoMissionBase` → `MissionObjectiveBridge.publish_primary_objective`, **Phase0K** `_seed_objectives` on QuestManager, **Phase0JObjectiveAdapter** path — D5 must converge on one **publisher** per event type.
2. **Router vs real mechanics:** `Phase0JMechanicRouter` mostly inspect-only for routes — Louis bypass may not yet change alarm graph.
3. **Debug HUD vs pause:** Two channels (`Phase0JDebugHUD`, pause tabs) can disagree until payloads read same mission_id.

Assertions: `taco_mechanics_audited`, `must_not_forget_items_checked`, `reusable_vs_taco_specific_boundary_classified` — true.
