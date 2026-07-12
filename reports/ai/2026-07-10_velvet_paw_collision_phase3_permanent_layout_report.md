# Velvet Paw Collision Protocol Phase 3 Permanent Layout Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: ROLLED BACK; Phase 3 not applied

## Scope And Outcome

Executed only Phase 3. A guarded apply extension, focused persisted/runtime tests, and an ignored candidate-first driver were implemented temporarily. Candidate save and inspection passed, and the separately explicit production apply produced the expected persisted layout. The full gate did not pass within two attempts, so the production scene, painter, and both tests were restored byte-for-byte from the Phase 3 checkpoint as required. Phase 4 was not started.

Final production state is exactly the Phase 2 state. There are no permanent layout cells, no painter apply API, and no Phase 3 test changes after rollback.

## Pre-Apply Checkpoint

Created before implementation:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03_pre_apply/`

Verified exact source/snapshot hash and size equality for all four files:

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | 85,690 | `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c` |
| `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd` | 19,436 | `c4fc9581dca94952a050744cf2a1a1b981c646eff41d802e9ae72061bd3fa697` |
| `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd` | 6,960 | `e80b8edc8f2ae962a3d5e5856b4d6295b7b0e5ab6ef4179e075d2f667782a769` |
| `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` | 11,139 | `4a6a018425192a0514f1cf6868069a004f68845dd0692d61acffe7020928296b` |

Manifest: `phase_03_pre_apply/manifest.json`. The scene began at required Git blob `46dfb24634c626bccaa65b6f054120bc4b9cbc86`.

## Temporary Implementation

The temporary painter extension preserved dry-run default behavior and required all of the following for non-dry apply:

- `allow_apply=true`
- Explicit `target_scene_path` under `res://` ending in `.tscn`
- Exact `expected_source_sha256`
- Empty approved source layout layers unless `replace_existing_layout=true`
- TileSet source `0` and required atlas tile existence
- Successful `PackedScene.pack()` before `ResourceSaver.save()`

It painted only deterministic floor, wall, movement-blocking barrier, and movement-blocking cover cells. Markers, safe covers, mechanics, resources, nodes, and `ArtRoot` were not changed. Unauthorized non-dry apply remained non-mutating.

## Candidate Evidence

The candidate was saved under the ignored recovery tree, reloaded with `CACHE_MODE_IGNORE`, instantiated, and inspected before production apply.

- Candidate SHA-256: `b74e5af364668dd5fb5644ad8e84c81b15cb8ae4ad7dfd639e86ebaffd8646e9`
- Root: `VelvetPawJazzClub_Editable`
- Node count: 152
- Scene header UID: absent, so the ignored candidate did not create a duplicate scene UID
- Mechanic coverage: 68/68; zero missing; zero mismatched
- `ArtRoot`: zero used cells; zero collision nodes
- Dynamic/RouteBlocker nodes: zero
- Pack result: `OK`
- Save result: `OK`
- Flags: scene pack called, pack validated, save called, PackedScene saved, Resource saved

Candidate cells:

| Kind | Cells | Source | Atlas |
| --- | ---: | ---: | --- |
| Floor | 9,996 | 0 | `(0,0)` |
| Wall | 1,420 | 0 | `(1,0)` |
| Collision barrier | 446 | 0 | `(1,0)` |
| Solid cover | 132 | 0 | `(2,0)` |
| Marker | 0 | n/a | n/a |

All ten barriers, including the front rope, and all four solid covers were represented. `Bar Corner` and `Dance Floor Silhouette` emitted no cover cells.

## Temporary Production Apply

The production driver first re-inspected the candidate successfully and then applied from the still-protected source SHA-256.

- Source SHA-256 before: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Temporary production SHA-256 after: `d487f7b303a1a7152b1930d402734d508b665fe72d4fd855ea8ad3fd3658a5e7`
- Blueprint before/after: `c2ac059bfd98e476f056fc3ea34250b13721497d4e1863bc81bdb3c8d206e3f9`
- Cells written: floor 9,996; wall 1,420; barrier 446; cover 132; marker 0
- Pack result: `OK`
- Save result: `OK`
- Immediate production inspection: exact expected counts, 152 nodes, 68/68 coverage, root unchanged, `ArtRoot` empty/collision-free, no dynamic blockers

Focused assertions also proved the staff-side entrance retained a connected clear lane with no barrier or solid-cover obstruction, the front entrance was barrier-blocked, owner-suite/basement perimeter representation persisted, safe covers were absent, representative mechanic positions remained, and runtime scene-authored sync populated both gameplay layers.

## Gate Attempts

### Attempt 1

Result: FAIL.

- Blueprint validator: PASS; 3 specs, 55 mechanic types, 0 failures, 0 warnings.
- Painter tests: passed through all 9 cases.
- Production suite failed a new assertion that required every staff-opening wall candidate cell to be empty. The unchanged algorithm correctly reported two wall-edge cells while preserving the required connected clear lane.
- Allowed narrow repair: changed only that test to assert the actual contract: connected nonempty clear lane, no barrier cells, and no solid-cover cells.

### Attempt 2

Result: FAIL full gate; rollback required.

- Blueprint validator: PASS; 3 specs, 55 mechanic types, 0 failures, 0 warnings.
- Assertions: PASS 28/28 across painter, Velvet production, and resolver suites.
- GdUnit process result: exit `101` because the runtime enter-tree test left 20 orphan Node2D/TileMapLayer objects and CanvasItem RIDs.
- The runtime test did prove mission startup and nonempty `GameplayFloorLayer`/`GameplayCollisionLayer`, but the orphan result violates the clean full-gate requirement.
- No third repair or attempt was made. Remaining production smoke/structural-diff checks were not used to override the failed gate.

## Rollback

Restored from exact snapshots:

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd`
- `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd`

Removed the ignored candidate, temporary apply driver, apply evidence JSON, failed Phase 3 isolated GdUnit output, and two Godot-generated painter/test `.uid` sidecars that were absent at baseline. Kept the checkpoint snapshots/manifest and rollback evidence.

Final restored hashes exactly match the checkpoint. The final production scene is:

- SHA-256: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Git blob: `46dfb24634c626bccaa65b6f054120bc4b9cbc86`
- Permanent Phase 3 cells/nodes/files applied: zero

## Rollback Validation

- Production headless smoke: PASS; reached `Mission started: velvet_paw_jazz_club` and `Loaded level: VelvetPawJazzClub_Editable`.
- Known forced-quit CanvasItem/ObjectDB detached-node leak noise remained, matching the prior Phase 1/2 runtime behavior.
- Prior Phase 2 isolated GdUnit baseline: PASS 24/24, 0 errors, 0 failures, 0 skipped, 0 flaky, 0 orphans.
- XML: `reports/velvet_paw_collision_phase3_rollback/report_1/results.xml`.
- Checkpoint source/snapshot integrity: PASS 4/4 exact hashes and sizes.
- `git diff --check`: PASS after rollback/report creation.

## Files Remaining From This Attempt

- `reports/ai/2026-07-10_velvet_paw_collision_phase3_permanent_layout_report.md`
- `reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03_pre_apply/manifest.json`
- Four exact non-importable snapshot files in that checkpoint
- `reports/velvet_paw_collision_phase3_rollback/` rollback test evidence

The production scene, painter, and both tests have no Phase 3 net changes. Blueprint, generated guide, roadmap, implementation blueprint, `IsoMissionBase`, `ArtRoot`, requirements/effects/resources, mechanics, `project.godot`, and autoloads remain untouched.

## Risks And Boundary

- Phase 3 is not complete and must not be treated as applied.
- The candidate and production paint itself matched all expected deterministic counts; the blocker was clean runtime-test teardown, not geometry or save correctness.
- Any future retry requires new authorization and a new checkpoint. It should isolate runtime sync proof in a teardown-safe scene/process or explicitly free runtime-generated detached nodes before the GdUnit orphan audit.
- Work stayed as one narrow Phase 3 slice, not grouped-milestone mode, because the user explicitly prohibited Phase 4.

No stage, commit, push, branch change, history rewrite, roadmap edit, implementation-blueprint edit, or Phase 4 work occurred.
