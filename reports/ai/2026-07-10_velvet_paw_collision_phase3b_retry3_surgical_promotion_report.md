# Velvet Paw Collision Phase 3B Retry 3 Surgical Promotion Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: ROLLED BACK; Phase 3B not applied

## Outcome

Executed only the explicitly authorized Phase 3B retry 3. A reusable fail-closed GDScript byte promotion helper, ignored PackedScene candidate pipeline, staged-scene validator, atomic `.NET System.IO.File.Replace` promotion, complete persisted/runtime tests, and focused byte patcher tests were implemented temporarily.

Attempt 2 reached successful atomic production promotion and immediate reload. The final combined test gate then failed one scratch integration assertion because that test incorrectly used the production scene as its unpainted baseline after production had been promoted. The helper correctly rejected the painted production blocks as already containing `tile_map_data`. The two-attempt limit required atomic rollback rather than repair. Phase 4 was not started.

## Retry 3 Checkpoint

Created and verified before implementation:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03b_retry3_pre_promotion/`

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | 85,690 | `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c` |
| `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd` | 19,436 | `c4fc9581dca94952a050744cf2a1a1b981c646eff41d802e9ae72061bd3fa697` |
| `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd` | 6,960 | `e80b8edc8f2ae962a3d5e5856b4d6295b7b0e5ab6ef4179e075d2f667782a769` |
| `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` | 11,139 | `4a6a018425192a0514f1cf6868069a004f68845dd0692d61acffe7020928296b` |
| `tests/mission_authoring/IsoMissionBaseLifecycleTest.gd` | 3,699 | `39fca8fa0494103c3e4ab45063fa80de730629e3858148c03dcd702779f6f6ba` |
| `src/levels/IsoMissionBase.gd` | 284,909 | `8da9a17657c3c1137ac78a11aca707225d7ee0102c98f3536b90aaf4e113450d` |

All six source files matched the manifest before implementation and after rollback.

## Temporary Byte Promotion Helper

The temporary `TileDataPromotionHelper.gd` was separate from geometry analysis and accepted only exact node blocks for:

- `FloorLayer`, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `2053303541`
- `WallLayer`, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `1291381707`
- `CoverLayer`, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `680121401`
- `CollisionBarrierLayer`, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `898422279`

It rejected missing/duplicate/wrong name, parent, type, ID, TileSet, existing baseline data, empty payload, malformed payload, multiline payload, marker payload, invalid UTF-8, mixed newlines, and the three retry-2 unrelated defaults. Candidate payloads were treated as opaque single-line `PackedByteArray` assignments. The helper inserted each assignment immediately before the baseline block's exact `tile_set = ExtResource("3")` line.

Candidate TileSet IDs were allowed to be ResourceSaver-generated only when the ID resolved exactly once to the canonical `IsoBlockoutTileset_Clean.tres`; the baseline insertion anchor remained exact.

Focused pre-promotion GdUnit passed 13/13 across helper and painter suites, with zero errors, failures, skips, flaky tests, or orphans.

## Candidate And Staged Proof

Candidate SHA-256: `123e5baed11ef88e86c769c43269365949ffc094956c64a5bd531f1380ec1dec`

Staged SHA-256: `3505da8385648c4bc02f6c51b4f6336c5b1515153265a467bc51fa0ed74a0ea2`

Byte proof:

- Baseline size: 85,690 bytes
- Inserted size: 192,064 bytes
- Staged size: 277,754 bytes
- Size formula: PASS
- Recorded spans: four
- Span removal reconstructed SHA-256 `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Byte-for-byte reconstruction equality: PASS
- Staged diff against checkpoint: four added lines, zero removed lines, four hunks
- Known unrelated retry-2 defaults absent: PASS
- Production source remained baseline SHA before promotion: PASS

Recorded spans:

| Layer | Offset | Length |
| --- | ---: | ---: |
| FloorLayer | 36,646 | 159,976 |
| WallLayer | 196,771 | 22,760 |
| CoverLayer | 219,680 | 2,152 |
| CollisionBarrierLayer | 221,992 | 7,176 |

Both candidate and staged inspections passed:

| Layer | Cells | Source | Atlas |
| --- | ---: | ---: | --- |
| Floor | 9,996 | 0 | `(0,0)` |
| Wall | 1,420 | 0 | `(1,0)` |
| Collision barrier | 446 | 0 | `(1,0)` |
| Solid cover | 132 | 0 | `(2,0)` |
| Marker | 0 | n/a | n/a |

Additional staged evidence:

- Persisted wall/barrier overlap exactly `(23,156)` and `(23,158)`
- Wall/cover, barrier/cover, and triple intersections empty
- Independently derived blocking union: 1,996 cells
- Blueprint mechanics: 68/68, no missing or mismatched nodes
- Staff lane clear and front rope blocked
- Safe covers absent; required closed islands represented
- No RouteBlockers
- ArtRoot had zero cells and collision nodes

## Atomic Promotion

Production was never replaced with the packed candidate. Immediately before promotion, the source hash was rechecked against the baseline. Staged bytes were copied to an adjacent non-resource replacement temp, verified against the staged SHA, and promoted with `.NET System.IO.File.Replace` using an adjacent rollback backup. No direct overwrite or fallback path was used.

Temporary production SHA-256: `3505da8385648c4bc02f6c51b4f6336c5b1515153265a467bc51fa0ed74a0ea2`

The adjacent backup SHA-256 was the exact baseline. Immediate production hash, ResourceLoader reload, instantiation, and all five persisted counts passed.

## Attempts

### Attempt 1

Result: FAIL before staging or production.

The helper initially required the candidate block to use the baseline literal `tile_set = ExtResource("3")`. ResourceSaver correctly generated `ExtResource("3_rxdo7")` for the ignored candidate. The permitted narrow repair required exactly one candidate TileSet reference resolving exactly once to the canonical TileSet path, while retaining the exact baseline `ExtResource("3")` anchor.

### Attempt 2

Result: FAIL final combined test gate; mandatory rollback.

- Blueprint validator: PASS, 3 specs, 55 mechanic types
- Candidate validation: PASS
- Staged validation and byte proof: PASS
- Pre-promotion focused tests: PASS 13/13, zero orphans
- Atomic promotion and immediate production reload: PASS
- Production geometry/runtime/lifecycle assertions: PASS
- Combined test run: 67/67 executed, 66 passed, 1 failed, zero errors/skips/flaky/orphans

Failed assertion:

`TileDataPromotionHelperTest.test_real_candidate_stages_only_in_ignored_scratch_and_loads`

The test called `stage_files(PRODUCTION, CANDIDATE, SCRATCH)` after production promotion. The helper correctly rejected all four production baseline blocks because they now contained `tile_map_data`. The integration test should instead have copied the unpainted checkpoint bytes into ignored scratch and used that scratch file as its baseline. No repair was made because attempt 2 exhausted the gate.

## Rollback Validation

The adjacent baseline backup was restored atomically with `System.IO.File.Replace`. The other five protected files were restored from the exact checkpoint, and temporary helper/test source files were removed.

Final production scene:

- SHA-256: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Git blob: `46dfb24634c626bccaa65b6f054120bc4b9cbc86`
- Permanent Phase 3B cells: zero

Restored baseline validation:

- Checkpoint hash/size verification: PASS 6/6
- Blueprint validator: PASS, 3 specs, 55 mechanic types
- GdUnit shared baseline: PASS 59/59, zero errors/failures/skips/flaky/orphans, exit 0
- Velvet production smoke: PASS, mission started and loaded, exit 0
- Taco production smoke: PASS, mission started and loaded, exit 0; known invalid-UID fallback warning only

## Remaining State

Phase 3B remains incomplete. The surgical byte promotion itself passed candidate, staged, byte, atomic replacement, and production runtime validation. A future separately authorized attempt would need only the narrow test-scope correction described above, but this retry made no such repair after the two-attempt limit.

Evidence is retained under:

- `reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_03b_retry3_work/`
- `reports/velvet_paw_collision_phase3b_retry3/`

No roadmap edit, Phase 4 work, stage, commit, push, branch change, or history operation occurred. Work stayed in a narrow Phase 3B slice.
