# Security / heat wiring audit (pre-D6-01 implementation)

## MissionAlertController

- **Owner:** Attempt-local alert FSM (`normal/suspicious/alerted/resolved`), `record_alarm_event`, `register_detection_event`, `accumulate_exposure`.
- **Per-scene:** Node in group `iso_alert_controller` (one per iso mission scene).
- **Performance:** `GameState.record_mission_performance_event` + `increment_attempt_counter` on scene for alarms/guards/cameras.

## Cameras (`MissionSecurityCamera`)

- Calls `_controller.accumulate_exposure` each frame in cone; **adapter does not** subscribe per-frame — normalized **`camera_detection`** comes from **`record_alarm_event`** when exposure trips full alarm path.

## Beam (`IsoMissionBase._on_runtime_alarm_zone_entered`)

- One-shot `alarm_triggered:garage_entry_beam`; calls `register_detection_event(..., "alarm_zone")` → **`record_alarm_event`** → normalized **`beam_trip`** when source contains `garage_entry_beam`.

## Wrong code

- **`MissionCodeGatePlaceholder`:** GameState perf + attempt counter; at threshold `register_detection_event(..., "wrong_code_alarm")` + guard spawn.
- **`Phase0JCodeGateController` / `Phase0KBWrongCodeAttackGuardSpawner`:** alternate tooling path; both now emit adapter **`wrong_code`**; spawner emits **`reinforcement_spawned`** on guard spawn.

## Persistent heat

- **`GameState.fail_mission`:** sole increment `failed_attempts[mission_id]` (+1) found in this audit scope for mission failure heat.
- **`get_mission_heat`:** `min(5, failed_attempts)`.

## Safe D6-01 call sites

- End of **`record_alarm_event`** (single funnel for alarm-class events).
- Placeholder / Phase0J / Phase0KB explicit hooks (no IsoMissionBase broad edits).

## Deferred

- Extra guard patrol LOS beyond `_on_runtime_guard_spotted` already wired — no change.
- No second parallel counter system added beyond adapter attempt-local ring buffer.
