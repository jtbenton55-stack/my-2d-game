# 2026-06-24 - Taco Bell D5-01A Beam Reset And Guard Spawn Follow-Up

## Scope

Narrow D5-01 follow-up based on Jake's live QA: bag reset worked, but the garage beam did not reliably re-trip after `Reset Attempt`, and repeated post-reset crossings spawned extra guards.

Jake's second live QA after the first fix confirmed `READY -> TRIPPED -> READY` for the first reset cycle, then found a remaining issue: the next crossing after reset did not update F12 back to `TRIPPED`, three guards spawned, and guards could jam around the beam route.

Jake's third live QA confirmed reset and the first guard wave worked, but the beam still did not change to `TRIPPED` and spawned no guard after `Reset Attempt` and a second crossing. That pointed to the physical `AMBUSH_security_beam` trigger not being synchronously rebuilt/armed after reset, even though the F12 model returned to `READY`.

Jake's fourth live QA confirmed the beam reset was working, then found reset accumulated a second camera cone and did not clear extra spawned guards. That pointed to live security actors under `EntityRoot/Cameras` and `EntityRoot/Enemies` not being cleared before runtime rebuild.

2026-06-30 closeout: Jake manually confirmed D5-01A-E successful after the final follow-up. Beam reset works, the first guard wave behaves, reset no longer duplicates the camera cone, and old spawned guards disappear on reset.

This stayed in a narrow D5-01A/D5-01B/D5-01C/D5-01D/D5-01E slice rather than grouped-milestone mode. No scene files, Player files, project settings, or unrelated systems were intentionally edited.

## Files Changed

- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/MissionAlertController.gd`
- `tests/mission_authoring/PhaseD501AttemptResetContractTest.gd`
- `reports/ai/D5_PENDING_ITEMS.md`
- `reports/ai/2026-06-24_taco_bell_d5_01a_beam_reset_guard_spawn_report.md`

## Implementation Notes

- `reset_mission_runtime_for_new_attempt()` now includes a D5 security reset result in its `d5_01_attempt_reset` metadata.
- Added `_reset_d5_attempt_security_runtime()` to rearm one-shot alarm zones and remove attempt-local security response guards from `EntityRoot/Enemies`.
- Runtime bucket clearing now removes children from the tree before `queue_free()`, preventing immediate rebuilds from finding stale queued alarm-zone nodes.
- Reused/rebuilt `AMBUSH_security_beam` alarm areas are explicitly rearmed with `monitoring = true`, `monitorable = true`, and player collision mask restored.
- Authored beam guard spawns are now tagged as response spawns and are blocked after the first successful beam-triggered author spawn per attempt.
- `_security_event_router` is cleared during runtime-system rebuild and `get_security_event_router()` rejects invalid, queued, or not-in-tree routers so reset does not reuse a stale router.
- Authored beam trip events now mark the same canonical attempt-runtime flag used by the F12 garage beam dashboard: `alarm_triggered:AMBUSH_security_beam`, plus `beam_trip` and `d5_01_authoring_beam_trip_marked`.
- F12 garage beam state now treats either `garage_entry_beam` or `AMBUSH_security_beam` as the beam trip source.
- `MissionAlertController` routes `AMBUSH_security_beam` alarm-zone events as `beam_trip`, matching the legacy `garage_entry_beam` path.
- D5-01D: `reset_mission_runtime_for_new_attempt()` now synchronously ensures the authored Taco beam runtime exists before reporting reset metadata, instead of relying on the boot-only deferred `_ensure_d6_fix5_runtime_helpers()` path.
- D5-01D: Added `_arm_d5_attempt_alarm_area()` so reused/rebuilt beam areas always have `body_entered` connected, monitoring/monitorable restored, collision mask restored, and child collision shapes enabled.
- D5-01D: Both authored and fallback `AMBUSH_security_beam` setup paths now use the same arming helper.
- D5-01E: `reset_mission_runtime_for_new_attempt()` now clears live attempt-local security actors before rebuilding runtime systems, including all `EntityRoot/Cameras` children, tagged runtime/response guards under `EntityRoot/Enemies`, and queued deferred guard spawn requests.
- D5-01E: Runtime definition guards and cameras are now tagged when spawned so future resets can remove stale attempt-local actors without depending on node names.

## Validation

- PASS: `git diff --check -- "src/levels/IsoMissionBase.gd" "src/missions/iso/runtime/MissionAlertController.gd" "tests/mission_authoring/PhaseD501AttemptResetContractTest.gd" "reports/ai/D5_PENDING_ITEMS.md" "reports/ai/2026-06-24_taco_bell_d5_01a_beam_reset_guard_spawn_report.md"`
- PASS: `python "src/tools/editor/taco_bell_redesign_d5_01/phase0md5_01_static_validator.py"`
- PASS: `addons/gdUnit4/runtest.cmd --godot_binary "Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe" -a "res://tests/mission_authoring/PhaseD501AttemptResetContractTest.gd"`; `9/9` passed, latest report `reports/report_100/`.
- PASS: `addons/gdUnit4/runtest.cmd --godot_binary "Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe" -a "res://tests/mission_authoring/SecurityReadabilityLiteTest.gd"`; `7/7` passed, latest report `reports/report_101/`.
- PASS: Jake manual Taco QA confirmed D5-01A-E after the final follow-up.

## Manual Retest Checklist

1. Start Taco Bell, collect the delivery bag, and deliver it.
2. Cross the garage/security beam once and confirm F12 changes `Garage beam` from `READY` to `TRIPPED`.
3. Confirm only the intended first guard wave appears for that attempt.
4. Use `Reset Attempt`.
5. Confirm F12 returns `Garage beam` to `READY`.
6. Cross the beam again and confirm F12 changes `READY` to `TRIPPED` again.
7. Cross the beam additional times without another reset and confirm no extra guard waves spawn.
8. Press `Reset Attempt` again and confirm camera cones do not duplicate.
9. Confirm spawned guards from the previous attempt are removed before the next attempt starts.
10. Confirm spawned guards do not jam at or near the beam route.

## Known Noise

- GdUnit startup still logs the existing remote debugger port `0` warning, controller mapping `misc2` warnings, and Vulkan loader registry warning.
- The GdUnit wrapper prints `'Godot_v4.6.2-stable_win64.exe' is not recognized...` before the bundled Godot executable still launches and completes the tests.

## Remaining Risks

- Broader Taco restart/reload manual QA is still required before any grouped D5 milestone commit.
- D5-02 and D5-03 were implemented in the 2026-06-30 grouped closeout packet and are tracked in `reports/ai/2026-06-30_taco_bell_d5_02_d5_03_closeout_report.md` plus `reports/ai/D5_PENDING_ITEMS.md`.
- This D5-01A/B/C/D/E stabilization slice remained narrow when implemented; it was then included in the grouped D5 closeout after manual confirmation.
