# 2026-06-23 - Taco Bell D5-01 Attempt Reset Contract

## Scope

D5-01 implemented the narrow attempt-reset contract from the D4 D5 implementation spec: reset Taco attempt-local objective display state, make Phase0K objective seeding re-invokable, and route the Taco debug restart through the canonical mission start path.

This stayed in the narrow D5-01 slice rather than broad grouped-milestone mode. No Player, project settings, or Taco scene files were intentionally edited for this pass.

## Files Changed

- `src/missions/objectives/MissionObjectiveBridge.gd`
- `src/missions/iso/runtime/Phase0JInteractablePickup.gd`
- `src/missions/iso/runtime/Phase0JMissionStateAdapter.gd`
- `src/missions/iso/runtime/Phase0JRuntimeMarkerLabel.gd`
- `src/missions/iso/runtime/Phase0KBagObjectiveInteractable.gd`
- `src/missions/iso/runtime/Phase0KMissionCompletionController.gd`
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `tests/mission_authoring/PhaseD501AttemptResetContractTest.gd`
- `src/tools/editor/taco_bell_redesign_d5_01/phase0md5_01_static_validator.py`
- `docs/reports/taco_bell_redesign_d5_01/phase0md5_01_static_validator_run.json`

## Implementation Notes

- Added `MissionObjectiveBridge.seed_runtime_objectives_for_mission()` so runtime controllers can reseed QuestManager objective rows through one seam.
- Implemented `MissionObjectiveBridge.reset_runtime_objectives_for_mission()` to clear only the target mission's `QuestManager` maps and active line when that mission owns the active quest.
- Added `Phase0KMissionCompletionController.reset_attempt_state()` to clear bag/code/exit/completion flags and reseed the open-gate, recover-bag, and return-to-Louis objectives.
- Hooked `IsoMissionBase.reset_mission_runtime_for_new_attempt()` to reset runtime systems, clear objective state, call the Phase0K reset hook when present, and store `d5_01_attempt_reset` metadata for debugging.
- Follow-up fix after Jake's live QA: `Reset Attempt` now also resets the scene-local delivery bag interactables/labels/collision state. This covers the older generated `Interactable_OBJ_bag_recovery` and the Phase0K `DeliveryBagObjective`, so the F12 model and in-world bag visual should both return to uncollected without a scene reload.
- Follow-up fix: Taco garage beam runtime summary now treats either `alarm_triggered:garage_entry_beam` or `alarm_triggered:AMBUSH_security_beam` as the garage beam having tripped, matching the current authored red beam used in RedesignTest.
- Changed `IsoMissionDebugPanel._on_restart()` to call `GameState.start_mission(mid)` before resolving and changing to the playable mission scene.

## Validation

- PASS: `python "src/tools/editor/taco_bell_redesign_d5_01/phase0md5_01_static_validator.py"` (`33` checks after live-QA bag/beam follow-up)
- PASS: `addons/gdUnit4/runtest.cmd --godot_binary "Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe" -a "res://tests/mission_authoring/PhaseD501AttemptResetContractTest.gd"`
- GdUnit result after live-QA bag/beam follow-up: `4/4` passed, `0` failures, `0` errors, `0` orphans. HTML/XML report: `reports/report_89/`.
- PASS: `addons/gdUnit4/runtest.cmd --godot_binary "Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe" -a "res://tests/mission_authoring/SecurityReadabilityLiteTest.gd"`; `7/7` passed, report `reports/report_90/`.
- PARTIAL: Taco RedesignTest headless smoke loaded the scene and edited scripts, then hit the existing shutdown leak/orphan noise and timed out before a clean process exit. Do not count this as manual gameplay signoff.
- Earlier same-session affected regression result before this report: `17/17` passed.
- Earlier same-session Taco headless smoke loaded through mission startup; it still emitted existing Godot/MCP shutdown noise and orphan/leak warnings, so it is smoke evidence only, not manual gameplay signoff.

## Known Noise

- GdUnit startup logs still include the existing remote debugger port `0` warning, controller mapping `misc2` warnings, Vulkan loader registry warning, and MCP port bind warning.
- The current worktree contains many unrelated modified, deleted, and untracked files from other phases/generated reports. This pass did not revert or stage them.

## Remaining Risks

- D5-01 does not implement D5-02 pause mission-context hardening or D5-03 Louis beam-bypass runtime behavior.
- Manual gameplay validation is still recommended: collect the delivery bag, press F12 `Reset Attempt`, confirm the bag visual/interaction returns to uncollected without `Restart Scene`, then cross the red beam and confirm the F12 Garage beam badge changes to `TRIPPED`.
- `QuestManager` internals are accessed directly by `MissionObjectiveBridge` for reset because that is the current authoritative storage seam; future refactors should preserve a single reset API rather than duplicating direct map clears.

## Suggested Next Steps

1. D5-02: pin pause payload mission context to `taco_bell_drop` in RedesignTest and validate pause tabs.
2. D5-03: wire Louis route/bypass behavior so it changes the garage beam challenge outcome without affecting the main path.
3. Run a manual Taco restart/reload QA pass before any grouped D5 milestone commit.
