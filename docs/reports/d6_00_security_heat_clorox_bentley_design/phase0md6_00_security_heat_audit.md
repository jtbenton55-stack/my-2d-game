# 0M-D6-00 — Security / alert / heat audit (repo truth)

## Scope

Iso Taco path (`IsoMissionBase` + `src/missions/iso/runtime/**`) vs legacy `TacoBellMission.gd` (non-iso classic scene). Canonical play is **RedesignTest** iso; classic mission still contains alarm-trip narrative for comparison only.

## 1. Alert / security systems that exist

| System | Location | Role |
|--------|----------|------|
| **MissionAlertController** | `src/missions/iso/runtime/MissionAlertController.gd` | Attempt-local FSM: `normal` → `suspicious` → `alerted` → `resolved`; exposure score; ties to **HUD** via `EventBus.detection_state_changed`. |
| **MissionSecurityCamera** | `src/missions/iso/runtime/MissionSecurityCamera.gd` | Cone LOS sweep; calls `_controller.accumulate_exposure` / `decay_exposure`; group `iso_security_camera`. |
| **Guards / vision** | `src/enemies/**`, `vision_cone.gd`, iso patrol spawners | Guard alert duration etc.; alarm path can `spawn_attack_guard_near_player` from `MissionAlertController.record_alarm_event`. |
| **Code gate wrong entry** | `Phase0JCodeGateController.gd`, `Phase0KBWrongCodeAttackGuardSpawner.gd` | Counts wrong attempts vs **dynamic threshold** from heat profile; spawns `WrongCodeAttackGuard_*` with meta `spawn_reason=wrong_code`. |
| **Placeholder code gate** | `MissionCodeGatePlaceholder.gd` | Records `wrong_code_attempts` performance, increments attempt counter, may `register_detection_event(..., "wrong_code_alarm")` on alarm threshold. |
| **Scent trail wrong path** | `MissionScentTrailPlaceholder.gd` | Can `increment_attempt_counter("wrong_scent", penalty)` — feeds **performance** / **perfect_moment** logic. |
| **Garage beam (debug/runtime summary)** | `IsoMissionDebugPanel.gd` | Surfaces `garage_beam_armed/triggered` from runtime summary; not full alarm stack documentation in this audit file. |
| **Legacy TacoBellMission** | `src/missions/TacoBellMission.gd` | Alarm panel, trip zone, `_trip_security` — **parallel** security story for classic mission surface; do not assume 1:1 with iso stack. |

## 2. Heat data in GameState

- **`failed_attempts: Dictionary`** — keyed by `mission_id`; integer count of failures (or attempts, naming legacy).
- **`get_mission_heat(mission_id)`** — returns `mini(5, failed_attempts.get(mission_id, 0))` — **persistent per mission ID**, capped at 5.
- **`mission_heat_states`** — snapshot dict per mission: `heat_level`, `active_extra_guards`, `active_camera_state`, `friend_hint_level`, mutation selection, etc. Updated via `_update_mission_heat_state`.
- **`mission_mutation_state`** — RNG table persisted per mission for restart mutations (seed ties to mission + failed count).
- **Comment in GameState** — “heat is derived from failed_attempts (capped)”.

## 3. Per-mission vs global

- **Primary mechanical heat:** **per `mission_id`**, not a single global int (though UX copy sometimes speaks globally).
- **Hideout narrative layer:** `HideoutStateController.gd` uses `taco_bell_heat`, `heat_state` strings (`low/medium/high`) for **hideout UI / dialogue** — related but not identical API to `get_mission_heat`.

## 4. Runtime heat changes

- Increments when missions fail / attempts recorded (exact increment sites spread across missions + iso attempt counters — **D6-01 must centralize policy**).
- `IsoMissionDebugPanel._set_heat` writes `GameState.failed_attempts[mid] = heat` — **debug harness can mutate heat** (treat as dev-only surface).

## 5. Heat effects today (iso)

- **`IsoMissionBase._apply_heat_profile()`** — reads `GameState.get_mission_heat`, sets `_heat_profile`: wrong-code threshold, camera rate/sweep multipliers, `extra_camera`, `extra_guard_pressure`, `fake_scent_penalty`; copies into `_active_mutations` for debug/UI.
- **`IsoMissionBase._initial_objective_text()`** — appends **Louis hint tiers** based on heat / fails.
- **`TacoBellMission._spawn_taco_heat_extras`** (legacy) — spawns extras when heat thresholds met — **iso Taco should not be assumed to call this**.

## 6. Beams vs alarms vs heat

- Beam state is surfaced in **debug/runtime summary** and Phase0J markers (`ALARM_beam_escalation` in tooling docs). **Full beam → MissionAlertController wiring** must be verified in D6-01 implementation pass; risk: beam only increments attempt counters without unified `SecurityEvent` record.

## 7. Wrong-code guards

- **Yes**, via `Phase0KBWrongCodeAttackGuardSpawner` after threshold; also placeholder gate may raise **alarm-class** detection event.

## 8. Cameras vs guards

- **Shared path:** cameras feed `MissionAlertController`; guards feed detection / combat; **alarm recording** shares `record_alarm_event` for performance counters.

## 9. Reusable vs Taco-specific

- **`MissionAlertController`**, **`MissionSecurityCamera`**, heat profile hooks in **`IsoMissionBase`** — **reusable** iso mission kit.
- **Louis hint strings** and Taco-specific spawn tables — **Taco-flavored** but built on generic heat integers.

## 10. Stale / duplicated / debug-only

- **Dual Taco surfaces:** classic `TacoBellMission` vs iso `IsoMissionBase` — risk of **stale mental model** if docs reference only one.
- **Hideout “Lower Heat Run”** — `HideoutManager` placeholder text: heat gameplay **explicitly deferred** in UI feedback.
- **Phase0JMechanicRouter** maps `ALARM` → `SEPARATE_PASS_REQUIRED` — signals incomplete central alarm productization.

## 11. Legacy surfaces

- Trust **iso + GameState + MissionAlertController** as primary for D6-01; treat **TacoBellMission** alarm blocks as **legacy reference** unless actively launched.

## Assertions

| Assertion | Value |
|-----------|--------|
| security_heat_audit_completed | true |
| existing_heat_state_identified_or_missing_reported | true |
| guard_camera_beam_wrong_code_systems_mapped | true |
