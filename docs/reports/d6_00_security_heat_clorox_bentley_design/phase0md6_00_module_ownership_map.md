# 0M-D6-00 — Module ownership map

| Responsibility | Current owner | Proposed D6 owner | Reusable? | D6 phase | Save/load | UI/F10 |
|----------------|---------------|---------------------|------------|----------|-----------|--------|
| Security event reporting | Scattered (`MissionAlertController`, placeholders, gates) | **`MissionSecurityEventAdapter`** (new) | Yes | D6-01 | None new (uses existing performance) | F10 lines |
| Guard detection | Guard + vision cone + iso spawners | Adapter → `MissionAlertController` | Yes | D6-01 | — | F10 |
| Camera detection | `MissionSecurityCamera` | Adapter (wrap accumulate) | Yes | D6-01 | — | F10 |
| Beam alarm | Iso runtime / summary (verify) | Adapter emits `beam_trip` | Taco first | D6-01 | Optional perf flag | F10 |
| Wrong-code penalty | `Phase0JCodeGateController` + spawner + placeholder | Adapter centralizes | Yes | D6-01 | — | F10 |
| Reinforcement spawn | `MissionAlertController` + scene hooks | Scene implements spawn; **adapter** decides *when* | Yes | D6-01 | — | debug |
| Local alert state | `MissionAlertController` | **Keep** | Yes | D6-01 | Attempt-local (reset API exists) | HUD stealth meter |
| Persistent heat | `GameState.failed_attempts` + `_update_mission_heat_state` | **GameState** owns numbers; **adapter policy** owns increments | Yes | D6-01 | Existing keys | Pause summary |
| Heat HUD | Mostly none on compact strip | **Defer** numeric HUD; pause only MVP | — | D6-01 | — | Pause |
| Clorox wipeable traces | *Missing in Taco iso* | **`WipeableTrace` interactable** + mission markers | Start Taco | D6-02 | Serialize via mission save if needed | F10 counter |
| Clorox hold interaction | *N/A* | `MissionMechanicHook` or small `InteractableHold` mixin | Yes | D6-02 | — | SFX line |
| Cleanup bonus / Clean getaway | `mission_performance` + hideout placeholders | Extend **performance finalize** rules | Yes | D6-02 | Existing perf dict | Results screen later |
| Case pulse | `Player.gd` | **Keep Player owner**; **optional** small helper module for group lists | Yes | D6-03 | — | F10 |
| Q input | `project.godot` (read-only this pass) | No rebind in D6-03 unless spec | — | D6-03 | — | Controls overlay |
| Highlight rendering | `Player.gd` modulate hack | Consider **shared HighlightService** later | Maybe | D6-03 | — | — |
| Minimap | None | **Forbidden** until dedicated milestone | — | defer | — | — |

### Must-not-touch (from this design pass forward until approved)

- `IsoMissionBase.gd` broad refactors — **split reads vs edits** in implementation specs; prefer adapter injection points already used (`increment_attempt_counter`, `MissionAlertController`).

### Spaghetti risks

- **Double counting** heat vs alarms — mitigated by adapter policy table.
- **Dual Taco missions** — implementation always targets **iso canonical** first.

## Assertions

| Assertion | Value |
|-----------|--------|
| module_ownership_map_created | true |
| no_major_responsibility_unowned | true |
| taco_specific_vs_reusable_boundary_defined | true |
