# Velvet Paw Collision Phase 3A Lifecycle Fix Report

Date: 2026-07-10
Branch baseline: existing working tree, no branch change
Gate attempts used: 2 of 2
Result: PASS

## Scope

Executed only the authorized Phase 3A lifecycle repair. No collision was painted, no production scene was edited, and Phase 3B was not started. The change is limited to ownership cleanup in `IsoMissionBase._ensure_node()`, a focused GdUnit regression suite, checkpoint/evidence files, and this report.

## Root Cause And Exact Count Correspondence

`IsoMissionBase._ensure_iso_structure()` always constructs a fallback node before calling `_ensure_node()`. Before this fix, `_ensure_node()` returned a same-named authored child without attaching or freeing the unused detached fallback. GdUnit therefore found detached `Node2D`/`TileMapLayer` objects after the temporary Phase 3 runtime test.

The prior rollback reported exactly 20 orphan objects. The current Velvet scene has exactly 20 same-named children at the paths exercised by `_ensure_iso_structure()`:

- 1 root `GameplayRoot`
- 1 root `ArtRoot`
- 3 gameplay tile layers
- 1 `SpawnPoints`
- 1 `LayoutRoot` plus 5 authored layout tile layers
- 1 `MarkerRoot` plus its authored `Spawns` category
- 6 authored art tile layers: ground, wall, prop, decor below, decor above, and lighting

Total: `1 + 1 + 3 + 1 + 6 + 2 + 6 = 20`. Each existing child caused one unused fallback, matching the rollback's 20 orphan objects one-for-one. Other requested structural children were absent and their fallback nodes were attached normally, so they were not orphans.

## Checkpoint

Created before production/test edits:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03a_pre_lifecycle_fix/`

- `src_levels_IsoMissionBase.gd.snapshot`: 284,843 bytes; SHA-256 `0c2268e26c6793889e8369ff61f427457d5271488eba2a652f49adf9c834d5fa`
- Manifest: `manifest.json`
- No existing tests were modified, so no test snapshot was required.
- Recorded production scene: 85,690 bytes; SHA-256 `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Post-run snapshot verification matched the manifest hash and size exactly.

## Production Fix

`src/levels/IsoMissionBase.gd` now frees the supplied fallback only when a same-named child already exists, the fallback is not that existing child, and the fallback instance is valid. It then returns the existing child as before. The missing-child path is unchanged: name the valid fallback, attach it to the parent, and return it. No caller or factory was refactored.

Final production script: 284,909 bytes; SHA-256 `8da9a17657c3c1137ac78a11aca707225d7ee0102c98f3536b90aaf4e113450d`.

## Regression Coverage

Added `tests/mission_authoring/IsoMissionBaseLifecycleTest.gd` (3,699 bytes; SHA-256 `39fca8fa0494103c3e4ab45063fa80de730629e3858148c03dcd702779f6f6ba`) with four tests:

1. Existing named child is returned and the unused detached fallback ID becomes invalid; `node == existing` and null/invalid fallback guards preserve the existing node.
2. Missing child attaches and returns the valid fallback.
3. A minimal new `IsoMissionBase` enters the tree and tears down through physics/process frames without new orphan IDs.
4. The production Velvet scene enters the tree, flushes deferred startup, queues free, flushes physics/process teardown, and introduces no orphan IDs; the complete lifecycle repeats twice to detect accumulation.

The suite resets relevant `GameState` Velvet mission fields/flags and `QuestManager` objective collections before and after each test. Velvet provides the representative authored ISO lifecycle; adding another heavy Taco lifecycle to GdUnit was unnecessary because Taco received a separate production headless smoke.

## Attempts

### Attempt 1: FAIL

- Blueprint validator: PASS, 3 specs, 55 mechanic types, 0 failures, 0 warnings.
- Combined GdUnit: 59 cases executed; 58 assertions/cases completed successfully, but overall result was 1 runtime error and 1 orphan, exit `100`.
- Failure: the test attempted to pass a previously freed typed `Node` through dynamic `call()`. Godot rejected the argument before `_ensure_node()` ran. The aborted test then left its detached test receiver as the single orphan.
- Evidence: `reports/velvet_paw_collision_phase3a/attempt_1/report_1/results.xml`.
- Allowed narrow repair: replaced the uncallable freed-object argument with `null`, Godot's representable invalid `Node` value. Production code was unchanged.
- A preliminary command before Attempt 1 found the old repo-local Godot path absent and created no report or process; the authorized `GODOT_BIN` under `C:/Users/jtben/Documents/PBD 2026/tools` was then used. This path correction did not consume a complete gate attempt.

### Attempt 2: PASS

- Blueprint validator: PASS, 3 specs, 55 mechanic types, 0 failures, 0 warnings.
- Combined GdUnit: PASS 59/59 across 7 suites, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans; process exit `0`.
- New lifecycle suite: PASS 4/4, including two complete Velvet cycles and minimal `IsoMissionBase` lifecycle.
- Existing suites: painter 8/8, Velvet production 12/12, resolver 4/4, Milestone A runtime degate 2/2, Milestone A thin authorables 17/17, Phase D5.01 attempt reset 12/12.
- Evidence: `reports/velvet_paw_collision_phase3a/attempt_2/report_1/results.xml`.
- Velvet headless smoke: reached `Mission started: velvet_paw_jazz_club` and `Loaded level: VelvetPawJazzClub_Editable`; no error/leak/orphan markers; exit `0`.
- Taco headless smoke: reached `Mission started: taco_bell_drop` and `Loaded level: TacoBellIso_Editable`; no error/leak/orphan markers; exit `0`.
- Smoke logs: `reports/velvet_paw_collision_phase3a/attempt_2/velvet_headless_smoke.log` and `taco_headless_smoke.log`.
- `git diff --check`: PASS; only an existing line-ending warning for the already-modified Velvet build guide was printed.
- Scene diff check: no `.tscn`/`.scn` paths in `git diff`.
- Velvet production scene final SHA-256: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`.

## Files Changed Or Added

- `src/levels/IsoMissionBase.gd`
- `tests/mission_authoring/IsoMissionBaseLifecycleTest.gd`
- `reports/ai/2026-07-10_velvet_paw_collision_phase3a_lifecycle_fix_report.md`
- `reports/velvet_paw_collision_phase3a/`
- Ignored checkpoint manifest and snapshot under `phase_03a_pre_lifecycle_fix/`

Existing unrelated blueprint, guide, report, painter, and test working-tree changes were preserved and not modified by Phase 3A.

## Risks And Phase 3B Entry Condition

- The fix changes shared `IsoMissionBase` ownership behavior only for a supplied fallback that loses to an existing same-named child. Current callers create detached fallbacks, which is the ownership case covered here.
- Directly passing an already-freed typed `Node` is rejected by Godot before method entry; the runtime guard is covered with null/invalid and same-instance cases.
- Controller mapping warnings in headless output are engine/input-database noise and did not affect process cleanliness.
- Phase 3B may begin only under separate authorization, with a new exact checkpoint, the production scene still at the required SHA-256 above, and this Phase 3A gate remaining green. Phase 3B must retain zero GdUnit orphans and clean process exits before any collision-paint promotion.

Work stayed in one narrow Phase 3A slice rather than grouped-milestone mode because the user explicitly prohibited Phase 3B and collision painting. No stage, commit, push, branch change, roadmap edit, blueprint edit, or scene edit occurred.
