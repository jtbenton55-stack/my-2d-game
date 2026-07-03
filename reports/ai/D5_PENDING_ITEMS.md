# Taco Bell D5 Pending Items

Last updated: 2026-07-03

## Open

- None. D5-01, D5-02, and D5-03 are manually QA-passed as of 2026-07-03.

## Fixed And Manually Confirmed

- D5-01A: `Reset Attempt` should rearm the garage beam so the next crossing changes the dashboard from `READY` to `TRIPPED` again.
- D5-01B: Beam-triggered guards should spawn only on the first successful beam trip per attempt. Repeated beam crossings without another reset, disconnect, or bypass should not spawn additional guard waves.
- D5-01C: Authored `AMBUSH_security_beam` trips should update the same F12/canonical beam-trip state after reset, and runtime rebuilds should not reuse stale security event routers.
- D5-01D: `Reset Attempt` should synchronously rebuild and arm the authored `AMBUSH_security_beam` Area2D so the second post-reset crossing physically fires again.
- D5-01E: `Reset Attempt` should remove stale live camera nodes, spawned/response guards, and queued deferred guard spawns before rebuilding the next attempt.

## Fixed And Manually Confirmed

- D5-02: Pause mission-context hardening now resolves the active Taco mission from the mission node when `GameState.current_mission_id` is empty/stale, and the Taco pause Objectives tab includes mission name/id, heat line, attempt context, objectives, schemes, and clues through `MissionPauseDataProvider`.
- D5-03: Louis delivery route now bypasses/neutralizes the garage beam path without marking the beam as tripped or routing alert/guard response, while the no-route main path still trips the beam. F12 reports route/bypass status.

## Notes

- Jake confirmed bag delivery/reset worked during live QA.
- Jake confirmed the dashboard changed `Garage beam` from `READY` to `TRIPPED`, then back to `READY` after reset.
- Jake observed that after reset, crossing the beam did not show `TRIPPED` again and repeated crossings spawned additional guards.
- Jake's second live QA found the first post-fix cycle worked, but the next post-reset beam crossing still failed to show `TRIPPED`, spawned three guards, and guards could jam near the beam route.
- Jake's third live QA found reset and the first guard wave worked, but after reset the next beam crossing did not show `TRIPPED` and spawned no guard.
- Jake's fourth live QA found the beam reset working, but reset duplicated a security camera cone and did not remove extra spawned guards.
- Jake manually confirmed the D5-01A-E follow-up: beam reset works, the first guard wave behaves, reset does not duplicate the camera cone, and old spawned guards disappear on reset.
- Latest automated validation after D5-01E follow-up: `PhaseD501AttemptResetContractTest.gd` passed `9/9` in `reports/report_100/`; `SecurityReadabilityLiteTest.gd` passed `7/7` in `reports/report_101/`.
- Latest D5-02/D5-03 automated validation: D5 static validator PASS; `PhaseD501AttemptResetContractTest.gd` passed `12/12` in `reports/report_104/`; `SecurityReadabilityLiteTest.gd` passed `7/7` in `reports/report_105/`; Taco headless scene smoke loaded `TacoBellIso_Editable_RedesignTest.tscn` and started `taco_bell_drop`.
- Jake reported on 2026-07-03 that D5-02, D5-01, and D5-03 all passed manual QA.
- Future regression retests should still cover pause Objectives/Scheme/Clues tabs during Taco, no-route beam trip + first guard wave, reset, Louis route grant/equip, route beam bypass with no extra guard wave, no duplicate camera cones, old spawned guards removed, repeated crossings without extra guard waves, and guard movement around the beam route.
