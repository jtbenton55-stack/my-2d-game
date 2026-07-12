# Velvet Paw Collision Phase 3B Permanent Layout Retry Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: ROLLED BACK; Phase 3B not applied

## Scope And Outcome

Executed only the authorized Phase 3B retry. The previously proven guarded apply extension, persisted-layout tests, detached direct-sync test, full enter-tree sync/teardown test, and ignored candidate-first driver were implemented temporarily. Candidate validation and explicit production promotion both produced the exact deterministic permanent layout. The complete attempt-2 gate then found that the expected runtime collision-layer count in two new assertions was wrong: the persisted wall, barrier, and cover sets contain two overlapping cells, so runtime synchronization correctly produced 1,996 unique collision cells rather than the asserted sum of 1,998.

The two-attempt limit prohibited a second repair. All five checkpointed files were restored byte-for-byte, the candidate/apply driver/evidence tree and generated residue were removed, and the Phase 3A/Phase 2 baseline was rerun successfully. Phase 4 was not started.

## Exact Checkpoint

Created before any implementation or scene edit:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03b_pre_apply_retry/`

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | 85,690 | `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c` |
| `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd` | 19,436 | `c4fc9581dca94952a050744cf2a1a1b981c646eff41d802e9ae72061bd3fa697` |
| `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd` | 6,960 | `e80b8edc8f2ae962a3d5e5856b4d6295b7b0e5ab6ef4179e075d2f667782a769` |
| `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` | 11,139 | `4a6a018425192a0514f1cf6868069a004f68845dd0692d61acffe7020928296b` |
| `src/levels/IsoMissionBase.gd` | 284,909 | `8da9a17657c3c1137ac78a11aca707225d7ee0102c98f3536b90aaf4e113450d` |

Manifest: `phase_03b_pre_apply_retry/manifest.json`. Source/snapshot hash and size equality passed 5/5 before implementation and again after rollback.

## Temporary Guarded Apply

The temporary painter extension preserved dry-run as the default and rejected unauthorized non-dry calls without mutation. Authorized apply required:

- `allow_apply=true`
- Exact `expected_source_sha256`
- Explicit `res://` `target_scene_path` ending in `.tscn`
- Valid source `0` and required atlas tile on each painted layer
- Empty approved layout layers unless `replace_existing_layout=true`
- Successful `PackedScene.pack()` before `ResourceSaver.save()`

Only these deterministic sets were written:

| Kind | Persisted cells | Source | Atlas |
| --- | ---: | ---: | --- |
| Floor | 9,996 | 0 | `(0,0)` |
| Wall | 1,420 | 0 | `(1,0)` |
| Collision barrier | 446 | 0 | `(1,0)` |
| Solid cover | 132 | 0 | `(2,0)` |
| Marker | 0 | n/a | n/a |

Safe covers, dynamic blockers, node movement, mechanics, Resources, and `ArtRoot` were not changed.

## Candidate Evidence

The ignored candidate was packed, saved, loaded with `CACHE_MODE_IGNORE`, instantiated, and inspected before production promotion.

- Candidate SHA-256: `b83d4d1953588744ace265367d96d5c01bc1ed6f8f40066a065ae58f573ba6f3`
- Root: `VelvetPawJazzClub_Editable`
- Nodes: 152
- Exact persisted counts and source/atlas identities: PASS
- Blueprint mechanics: 68/68, zero missing, zero mismatched
- Representative player-start and terminal positions: unchanged
- Staff entrance: connected clear lane; zero barrier cells; zero solid-cover cells; two wall-edge candidates accepted
- Front crowd rope: barrier-blocked
- Owner-suite and basement islands: represented and contained
- Safe covers: absent from painted cover cells
- RouteBlockers: zero
- `ArtRoot`: zero used cells and zero collision nodes
- Candidate scene-header UID: absent
- Candidate `.uid` sidecar: absent

The separate production command re-inspected this candidate before writing. Temporary production SHA-256 was `d487f7b303a1a7152b1930d402734d508b665fe72d4fd855ea8ad3fd3658a5e7`, matching the previously proven Phase 3 temporary output. Immediate reload/inspection repeated all candidate checks successfully.

## Attempts

### Attempt 1

Result: FAIL before candidate creation.

- Blueprint validator: PASS, 3 specs, 55 mechanic types, zero failures, zero warnings.
- Godot rejected one inferred `Variant` local in the ignored apply driver because warnings are treated as errors.
- Permitted narrow repair: explicitly typed the popped node as `Node`. No production code, test assertion, geometry, or scene was changed by the repair.

### Attempt 2

Result: FAIL complete gate; mandatory rollback.

- Blueprint validator: PASS, 3 specs, 55 mechanic types, zero failures, zero warnings.
- Candidate validation: PASS with the evidence above.
- Explicit production apply and immediate inspection: PASS.
- Combined GdUnit: 62 cases, 0 errors, 2 failures, 0 flaky, 0 skipped, 0 orphans; process exit `100` because of failures.
- Both failures were new runtime-count assertions: detached direct sync and full enter-tree startup expected 1,998 collision cells but observed exactly 1,996.
- The full startup test reached mission startup and populated gameplay layers. The GdUnit session itself reported zero orphans, but the failed assertion aborted that test before its explicit post-`queue_free` orphan snapshot assertion could complete.
- Failure XML retained at `reports/velvet_paw_collision_phase3b_rollback/attempt_2_failed_results.xml`.
- No second repair or third attempt was made.

## Structural Review

Before rollback, the production scene diff was eight added lines and one removed line. Review showed the intended `tile_map_data` additions on the four approved layout layers only. Root, 152-node structure, ext/subresources, mechanics, representative positions, `ArtRoot`, and RouteBlocker count were unchanged by load/inspection evidence. No scene or sidecar UID residue was created.

## Rollback And Baseline

Restored from the exact checkpoint:

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd`
- `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd`
- `src/levels/IsoMissionBase.gd`

Removed the ignored candidate, temporary apply driver, temporary apply evidence, failed Phase 3B report tree after retaining its XML, and generated residue. The existing tracked Velvet test UID remains intact.

Final production scene:

- SHA-256 before: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Temporary applied SHA-256: `d487f7b303a1a7152b1930d402734d508b665fe72d4fd855ea8ad3fd3658a5e7`
- SHA-256 after rollback: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Git blob after rollback: `46dfb24634c626bccaa65b6f054120bc4b9cbc86`
- Permanent Phase 3B cells: zero

Rollback validation:

- Blueprint validator: PASS, 3 specs, 55 mechanic types, zero failures/warnings.
- Phase 3A/Phase 2 combined baseline: PASS 59/59 across 7 suites; 0 errors, failures, flaky, skipped, or orphans; exit `0`.
- Baseline XML: `reports/velvet_paw_collision_phase3b_rollback/baseline/report_1/results.xml`.
- Velvet headless smoke: PASS, exit `0`; reached mission start and loaded `VelvetPawJazzClub_Editable`; no error/leak/orphan markers.
- Taco headless smoke: PASS, exit `0`; reached mission start and loaded `TacoBellIso_Editable`; no error/leak/orphan markers on the final isolated run.
- `git diff --check`: PASS except the existing generated-guide line-ending warning.
- Final scene diff: none.

## Files Remaining

- `reports/ai/2026-07-10_velvet_paw_collision_phase3b_permanent_layout_retry_report.md`
- Exact checkpoint and manifest under `phase_03b_pre_apply_retry/`
- Rollback evidence under `reports/velvet_paw_collision_phase3b_rollback/`

There are no net Phase 3B changes to the production scene, painter, painter test, Velvet production test, or `IsoMissionBase.gd`. Roadmap and implementation-blueprint files were not edited.

## Risk And Boundary

- Phase 3B is not complete and must not be treated as applied.
- The apply geometry and persistence path passed. The remaining retry issue is test expectation: runtime collision sync uses unique cells, yielding 1,996 because two cells overlap across persisted wall/barrier/cover sets.
- A future separately authorized retry should assert the proven unique runtime count of 1,996, or derive and assert the unique union explicitly, while retaining the exact persisted per-layer counts.
- No Phase 4 work, commit, push, stage, branch change, roadmap edit, or history operation occurred.

Work stayed in one narrow Phase 3B retry slice rather than grouped-milestone mode because the user explicitly prohibited Phase 4. The attempt limit forced rollback to the validated Phase 3A/Phase 2 boundary.
