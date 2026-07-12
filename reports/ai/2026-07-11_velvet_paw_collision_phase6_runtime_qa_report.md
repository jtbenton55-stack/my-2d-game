# Velvet Paw Collision Phase 6 Runtime QA Report

Date: 2026-07-11
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: FAILED AND ROLLED BACK; Phase 6 QA is not applied

## Scope And Final State

Executed only the requested Phase 6 runtime/reload/route QA. No Phase 7, roadmap, implementation blueprint, production scene, collision generator, mission controller, teleport, camera, Taco scene/script, shared TileSet, project setting, autoload, commit, push, stage, branch, or history change was made.

The two-attempt gate did not pass. Per the stop rule, the new runtime QA suite and clean-exit harness were removed. The isolated GdUnit reports and checkpoint remain as evidence. Final production is unchanged from the Phase 5 retry:

- Scene SHA-256: `8711593e9f448845dc2960ff0edb78afa27a4c972100ab1677aedd7e328b3e91`.
- Scene Git blob: `2912248da577f51fceea9f4e69dbde55f3f1ece4`.
- Runtime wall proxy remains present and unchanged.
- Six Phase 4 dynamic blocker shapes remain present and unchanged.
- No production repair was attempted because attempt 1 exposed a harness actor classification error, not a production collision failure.

## Checkpoint

Created and hash-verified before edits:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_06_pre_runtime_qa/`

| Snapshot | SHA-256 | Git blob |
| --- | --- | --- |
| `VelvetPawJazzClub_Editable.tscn` | `8711593e9f448845dc2960ff0edb78afa27a4c972100ab1677aedd7e328b3e91` | `2912248da577f51fceea9f4e69dbde55f3f1ece4` |

The production scene and checkpoint were re-hashed after attempt 2 and remained exact.

## Temporary QA Coverage

The rolled-back `VelvetPawJazzClubRuntimeQATest.gd` contained three in-tree tests:

1. Three complete instantiate/start/physics-flush/free cycles with source signatures and orphan comparison.
2. One sequential critical-route run through existing mechanic methods and legitimate predecessor facts/items/objectives.
3. Runtime spawn, 24x24 teleport clearance, camera, patrol waypoint, ArtRoot, and authoring-overlay checks.

A rolled-back report-local `SceneTree` harness was prepared to instantiate the production scene, verify 1,420 proxy shapes, queue-free the mission, await physics/process flushes, and then call `quit(0)` without `--quit-after`.

## Three-Cycle Result

PASS in both attempts. Every fresh cycle reported:

| Cycle | Gameplay floor | Gameplay collision union | Proxy shapes | Dynamic shapes enabled | Duplicate generated roots | Orphan growth |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 9,996 | 1,996 | 1,420 | 6 | 0 | 0 |
| 2 | 9,996 | 1,996 | 1,420 | 6 | 0 | 0 |
| 3 | 9,996 | 1,996 | 1,420 | 6 | 0 | 0 |

Additional cycle assertions passed:

- Exactly one `GeneratedRuntimeCollision` and one `RouteBlockers` root existed per cycle.
- `RouteBlockers` retained five bodies and six enabled shapes on every fresh instance.
- Source-layer signatures for floor, wall, cover, collision barrier, and marker layers were identical across all three cycles.
- Staff badge inventory, staff-gate flag, escape-hatch flag, and Velvet hostile state were fresh at the start of every cycle.
- All three teardown comparisons found zero new orphan IDs.

## Critical Route Result

The route test used a controlled `Node2D` in the legitimate `player` group on attempt 2. It used existing mechanic methods and set only authored predecessor facts or required objectives.

Passed route evidence:

- Initial staff entrance motion was physically clear; front crowd rope was physically blocked.
- Staff gate rejected unlock before the badge.
- Existing badge `collect()` succeeded; existing staff-gate `unlock()` succeeded; both staff shapes disabled after a physics/process flush; all unrelated blockers remained enabled.
- Backstage hatch rejected unlock before setlist completion and physically blocked.
- Authored clue predecessor facts were set; existing setlist terminal `hack()` succeeded; existing hatch `unlock_route()` succeeded; hatch collision disabled after flush; unrelated later blockers remained enabled.
- Basement teleport requirement passed, target resolved to `(3616,2944)`, activation succeeded, and the 24x24 target/arrival query was clear.
- Server vault rejected unlock before power and physically blocked.
- Authored Yordano briefing predecessor was set; existing power `check_circuit()` succeeded; vault `unlock()` succeeded; vault collision disabled after flush; unrelated later blockers remained enabled.
- Existing shard and basement-keycard `collect()` calls succeeded.
- Owner stairs physically blocked while closed.
- Return teleport requirement passed, target resolved to `(1024,1120)`, activation succeeded, and the 24x24 target/arrival query was clear.
- Existing owner-stairs `unlock()` then succeeded from the authored shard/keycard requirements; collision disabled and the valid south route became physically clear after flush.
- Suite teleport requirement passed, target resolved to `(3616,1216)`, activation succeeded, and the 24x24 target/arrival query was clear.
- Escape hatch rejected unlock before the briefcase and physically blocked.
- Existing owner challenge completion and briefcase collection succeeded.
- Existing escape `unlock_route()` succeeded; escape collision disabled and became physically clear after flush.
- All six dynamic shapes were disabled at the end of the route.
- `can_extract()` returned `ok=true`, `code=can_extract` after the five authored required objectives were completed.

Failed route evidence:

- Immediately after the successful return teleport, explicit controller synchronization still left `VelvetPawJazzClubMissionController.returned_upstairs_with_shard == false`.
- `GameState.velvet_paw_club_hostile` also remained `false`.
- These were the only two assertion failures in attempt 2. The route continued because the authored owner-stairs requirement is satisfied by shard plus basement keycard; hostile state was not required by that gate.

This is a concrete Phase 6 runtime integration failure in the return-teleport-to-hostile transition. It was not repaired because it was discovered on the final allowed attempt.

## Camera, Patrol, Art, And Overlay

The third focused test did not execute after the two failures in the preceding route test; GdUnit's XML declared three cases in the suite but emitted only the first two test-case records. Therefore no Phase 6 final-gate claim is made for camera limits, six patrol waypoint 24x24 queries, runtime ArtRoot collision, or runtime overlay absence.

Evidence still retained from the passing prior 80 tests:

- Phase 5 physical suite passed spawn and all three teleport landing 3x3 clearance grids with a 24x24 shape.
- The prior production suite passed teleport target resolution, two patrol route links with at least two waypoints each, and detached ArtRoot collision/tile absence.
- Those prior tests do not replace the unexecuted Phase 6 runtime camera and patrol-position checks.

Pause/restart was not exercised because no pause/restart behavior was relevant to the isolated return-transition failure.

## Gate Attempts

Attempt 1:

- Combined GdUnit XML: 83 declared cases across 10 suites; 0 errors, 49 assertion failures, 0 skipped, 0 flaky, 0 orphans; exit 100.
- All prior 80 tests passed.
- Three-cycle test passed all three cycles.
- Route failures cascaded from the temporary actor not being in the production `player` group; every mechanic correctly returned `actor_not_allowed`.
- Allowed narrow repair: added the temporary controlled actor to the `player` group. No production file changed.
- Evidence: `reports/velvet_paw_collision_phase6/attempt_1/report_1/results.xml`.

Attempt 2:

- Combined GdUnit XML: 83 declared cases across 10 suites; 0 errors, 2 assertion failures, 0 skipped, 0 flaky, 0 orphans; exit 100.
- All prior 80 tests passed.
- Three-cycle test passed all three cycles.
- Critical route passed every mechanic, collision, teleport, and extraction assertion except the two return/hostile state assertions.
- Required action: rollback and stop; performed.
- Evidence: `reports/velvet_paw_collision_phase6/attempt_2/report_1/results.xml`.

## Validation Not Completed

The exhausted two-attempt failure gate prevented the following post-gate checks:

- Blueprint validator.
- Separate production clean-exit harness execution.
- Velvet production smoke.
- Taco production smoke.
- Final camera-limit and patrol-waypoint runtime case.
- Final structural/signature script checks beyond the passing cycle signatures and unchanged scene hash/blob.
- Final global `git diff --check` after rollback.

No runtime errors, GdUnit errors, skipped cases, flaky cases, or orphan reports were emitted by either combined attempt. The two final failures were behavioral assertions attributable to the pre-existing return transition, not warnings or errors introduced by a production change.

Godot MCP Pro was unavailable in this OpenCode toolset. No screenshots or input automation are claimed. Godot 4.6.2 CLI, GdUnit4, in-tree scene instances, direct physics-space queries, and XML reports provided the evidence.

## Files And Boundary

Final file added:

- `reports/ai/2026-07-11_velvet_paw_collision_phase6_runtime_qa_report.md`

Retained ignored evidence:

- `reports/velvet_paw_collision_phase6/attempt_1/`
- `reports/velvet_paw_collision_phase6/attempt_2/`
- `reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_06_pre_runtime_qa/`

Rolled back files:

- `tests/mission_authoring/VelvetPawJazzClubRuntimeQATest.gd`
- `reports/velvet_paw_collision_phase6/production_scene_clean_exit_harness.gd`

Work stayed in the explicitly requested narrow Phase 6 QA slice rather than grouped-milestone mode. No roadmap was edited and Phase 7 was not started.

## Risk And Next Step

Phase 6 remains incomplete. A future explicitly authorized retry should isolate why the successful return teleport's `activation_succeeded` transition does not leave `returned_upstairs_with_shard` and `GameState.velvet_paw_club_hostile` true in the production in-tree sequence. It should then restore the rolled-back QA suite, rerun the three-cycle and full-route proof, and complete the deferred camera, patrol, clean-exit harness, validator, smokes, structural, and diff checks.
