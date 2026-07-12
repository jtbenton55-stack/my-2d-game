# Velvet Paw Collision Phase 3B Retry 2 Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: ROLLED BACK; Phase 3B not applied

## Outcome

Executed only the explicitly authorized fresh Phase 3B retry. The guarded candidate-first painter, complete blocking-overlap evidence, persisted-layout tests, independently derived runtime union tests, Phase 3A teardown assertions, and ignored apply driver were implemented temporarily.

Attempt 2 passed candidate inspection, production reload inspection, blueprint validation, 63/63 combined GdUnit with zero orphans, and both production smokes. The final structural scene diff nevertheless failed: `PackedScene.pack()` serialized three unrelated existing-script default properties in addition to the intended tile data. The two-attempt limit therefore required exact rollback. Phase 4 was not started.

## Retry 2 Checkpoint

Created and verified before any implementation or scene edit:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03b_retry2_pre_apply/`

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | 85,690 | `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c` |
| `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd` | 19,436 | `c4fc9581dca94952a050744cf2a1a1b981c646eff41d802e9ae72061bd3fa697` |
| `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd` | 6,960 | `e80b8edc8f2ae962a3d5e5856b4d6295b7b0e5ab6ef4179e075d2f667782a769` |
| `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` | 11,139 | `4a6a018425192a0514f1cf6868069a004f68845dd0692d61acffe7020928296b` |
| `tests/mission_authoring/IsoMissionBaseLifecycleTest.gd` | 3,699 | `39fca8fa0494103c3e4ab45063fa80de730629e3858148c03dcd702779f6f6ba` |
| `src/levels/IsoMissionBase.gd` | 284,909 | `8da9a17657c3c1137ac78a11aca707225d7ee0102c98f3536b90aaf4e113450d` |

Manifest hash/size checks passed 6/6 before implementation and after rollback.

## Temporary Implementation

The painter retained dry-run default behavior. Non-dry apply required all of:

- `allow_apply=true`
- Exact current `expected_source_sha256`
- Explicit `res://` target ending in `.tscn`
- Valid source `0` and required atlas tiles
- Empty approved layout layers unless explicit replacement
- Successful pack before save

The ignored driver used explicit types for every local declaration under warnings-as-errors.

The painter temporarily reported:

- Complete sorted pairwise intersections: wall/barrier, wall/cover, barrier/cover
- Complete sorted triple intersection
- Complete sorted unique blocking union
- Blueprint diamond semantic wall/barrier overlap coordinates
- Actual Godot stacked-map persisted overlap coordinates

Coordinate evidence:

- Requested semantic contract: `(99,57)`, `(100,58)`
- Corresponding persisted stacked-map intersections: `(23,156)`, `(23,158)`
- Wall/cover: empty
- Barrier/cover: empty
- Triple intersection: empty
- Independently derived unique persisted blocking union: 1,996 cells

## Candidate And Temporary Production Evidence

Candidate SHA-256: `1e48bc6b0c4943760d3aea228ac5cdeb6dfe3d0fd3978f5fb8c45ec7dfef417d`

Temporary production SHA-256: `d487f7b303a1a7152b1930d402734d508b665fe72d4fd855ea8ad3fd3658a5e7`

Both candidate and production reload inspections proved:

| Layer | Cells | Source | Atlas |
| --- | ---: | ---: | --- |
| Floor | 9,996 | 0 | `(0,0)` |
| Wall | 1,420 | 0 | `(1,0)` |
| Collision barrier | 446 | 0 | `(1,0)` |
| Solid cover | 132 | 0 | `(2,0)` |
| Marker | 0 | n/a | n/a |

Additional inspection:

- 152 scene nodes
- Blueprint mechanics 68/68; zero missing or mismatched
- Representative player-start and terminal positions unchanged
- Staff entrance retained a connected lane with no barrier or solid-cover cells
- Front crowd rope remained blocked
- Safe covers emitted no cells
- Owner-suite and basement islands remained represented and contained
- No RouteBlockers
- `ArtRoot` had zero cells and zero collision nodes
- No candidate scene-header UID or UID sidecar

## Runtime Sync Evidence

Both detached direct sync and full enter-tree startup temporarily passed.

- Expected gameplay collision was independently rebuilt from complete persisted `WallLayer`, `CoverLayer`, and `CollisionBarrierLayer` sets.
- Complete sorted gameplay collision cells equaled the derived union, not a summed or hardcoded count.
- Atlas precedence matched `IsoMissionBase` forward sync: wall `(1,0)`, then cover `(2,0)`, then barrier `(1,0)`.
- Complete gameplay floor cells matched persisted floor cells.
- Marker gameplay layer remained empty.
- All five persisted source-layer cell/source/atlas signatures were identical before and after forward sync.
- Reverse gameplay-to-layout sync was not invoked or modified.
- Full startup used process, physics, and two teardown process frames; explicit orphan snapshot passed.

## Attempts

### Attempt 1

Result: FAIL candidate contract check.

- Blueprint validator: PASS, 3 specs, 55 mechanic types, zero failures/warnings.
- Candidate geometry, counts, union size, and all other inspection checks passed.
- The candidate driver compared the requested diamond semantic coordinates directly against Godot stacked-map coordinates. Actual persisted intersections were `(23,156)` and `(23,158)`.
- One permitted narrow repair: report and assert both coordinate spaces explicitly while continuing to derive the blocking union only from persisted cells.

### Attempt 2

Result: FAIL final structural gate; mandatory rollback.

- Blueprint validator: PASS.
- Candidate inspection: PASS.
- Explicit production promotion and immediate inspection: PASS.
- Combined GdUnit: PASS 63/63 across 7 suites; zero errors, failures, flaky, skipped, or orphans; exit `0`.
- Velvet headless smoke: PASS, exit `0`.
- Taco headless smoke: PASS, exit `0`.
- Structural scene diff: FAIL.

`PackedScene.pack()` added the intended four `tile_map_data` properties but also serialized unrelated defaults:

- `BelievableTaskZone_velvet_paw_jazz_club_believable_task_zone_01.locked_prompt_text = "Task would look suspicious"`
- `BentleyCrawlspaceConnector_velvet_paw_jazz_club_bentley_crawlspace_connector_01.shape_size = Vector2(112, 112)`
- `DisruptionActionNode_velvet_paw_jazz_club_disruption_action_node_01.locked_prompt_text = "Disruption unavailable"`

These values reflected current script defaults rather than requested Phase 3B changes, but their serialization still violated the tile-data-only structural gate. No second repair or third attempt was made.

Attempt-2 evidence retained under `reports/velvet_paw_collision_phase3b_retry2_rollback/`.

## Rollback Validation

All six checkpointed files were restored byte-for-byte. The ignored candidate, driver, evidence, and generated residue were removed.

Final production scene:

- Before: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Temporary production: `d487f7b303a1a7152b1930d402734d508b665fe72d4fd855ea8ad3fd3658a5e7`
- After rollback: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Final Git blob: `46dfb24634c626bccaa65b6f054120bc4b9cbc86`
- Permanent Phase 3B cells: zero

Restored baseline validation:

- Blueprint validator: PASS, 3 specs, 55 mechanic types, zero failures/warnings
- Combined Phase 3A/Phase 2 baseline: PASS 59/59, zero orphans, exit `0`
- Velvet baseline headless smoke: PASS, exit `0`
- Taco baseline headless smoke: PASS, exit `0`
- Final production scene diff: none
- `git diff --check`: PASS except the pre-existing generated-guide line-ending warning

## Remaining Files And Risk

Remaining Phase 3B retry-2 artifacts:

- This report
- Exact `phase_03b_retry2_pre_apply` checkpoint
- Failure and rollback evidence under `reports/velvet_paw_collision_phase3b_retry2_rollback/`

Phase 3B remains incomplete. A future separately authorized retry must use a tile-data-only scene update strategy or otherwise prove that generic scene packing cannot serialize unrelated defaults. It should retain the complete persisted-union and precedence tests established here.

No roadmap edit, Phase 4 work, stage, commit, push, branch change, or history operation occurred. Work stayed in a narrow Phase 3B slice because Phase 4 was explicitly prohibited.
