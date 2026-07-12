# Velvet Paw Collision Phase 3B Retry 4 Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 1 of 2
Result: PASS; Phase 3B applied

## Outcome

Executed only the explicitly authorized Phase 3B retry 4. The retry 3 surgical byte-promotion pipeline was reimplemented with its scratch integration fixture corrected before attempt 1. Candidate generation remained confined to ignored recovery storage, and production was promoted only from the whitelist-patched staged bytes through atomic `.NET System.IO.File.Replace`.

Attempt 1 passed every gate. Production remains painted. Phase 4 was not started.

## Checkpoint

Created and verified before implementation:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03b_retry4_pre_promotion/`

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | 85,690 | `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c` |
| `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd` | 19,436 | `c4fc9581dca94952a050744cf2a1a1b981c646eff41d802e9ae72061bd3fa697` |
| `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd` | 6,960 | `e80b8edc8f2ae962a3d5e5856b4d6295b7b0e5ab6ef4179e075d2f667782a769` |
| `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` | 11,139 | `4a6a018425192a0514f1cf6868069a004f68845dd0692d61acffe7020928296b` |
| `tests/mission_authoring/IsoMissionBaseLifecycleTest.gd` | 3,699 | `39fca8fa0494103c3e4ab45063fa80de730629e3858148c03dcd702779f6f6ba` |
| `src/levels/IsoMissionBase.gd` | 284,909 | `8da9a17657c3c1137ac78a11aca707225d7ee0102c98f3536b90aaf4e113450d` |

## Surgical Promotion

`TileDataPromotionHelper.gd` is separate from geometry analysis and accepts only exact node blocks for:

- FloorLayer, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `2053303541`
- WallLayer, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `1291381707`
- CoverLayer, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `680121401`
- CollisionBarrierLayer, `TileMapLayer`, `GameplayRoot/LayoutRoot`, unique ID `898422279`

Marker data remains absent. The helper rejects missing or duplicate blocks, wrong name/type/parent/ID/TileSet, existing baseline tile data, malformed/multiline/empty payloads, mixed newlines, invalid UTF-8, marker tile data, and the three retry-2 unrelated defaults.

Candidate TileSet references must resolve exactly once to the canonical `IsoBlockoutTileset_Clean.tres`. Baseline insertion remains anchored to the exact `tile_set = ExtResource("3")` line. Candidate `tile_map_data` is treated as an opaque ResourceSaver payload.

## Fixture Correction

The integration test never uses production as an unpainted fixture. Before every run it:

1. Verifies the immutable retry 4 checkpoint snapshot SHA against `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`.
2. Copies the checkpoint bytes to ignored `integration_unpainted_baseline.tscn`.
3. Verifies the scratch baseline SHA again.
4. Calls `stage_files` with the ignored scratch baseline, ignored candidate, and ignored staged output.
5. Verifies the scratch baseline remains unchanged and span removal reconstructs the checkpoint bytes.

The full suite ran before and after production promotion, proving fixture independence.

## Byte Proof

- Candidate SHA-256: `7a46bf573686af75fd617053eaeeb7b8d752cb6135433515263c2190bd8a547f`
- Staged and production SHA-256: `3505da8385648c4bc02f6c51b4f6336c5b1515153265a467bc51fa0ed74a0ea2`
- Production Git blob: `7ea65f62045208be4c9b9911fdcd439735bc7e52`
- Baseline size: 85,690 bytes
- Inserted size: 192,064 bytes
- Staged size: 277,754 bytes
- Size formula: PASS
- Recorded spans: four
- Span removal reconstructed baseline byte-for-byte
- Reconstruction SHA-256: `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c`
- Production diff: exactly four additions, zero removals, four hunks
- All four additions are single-line `tile_map_data = PackedByteArray(...)` properties
- Known retry-2 defaults absent
- All baseline bytes and order preserved

## Geometry And Runtime

| Layer | Cells | Source | Atlas |
| --- | ---: | ---: | --- |
| Floor | 9,996 | 0 | `(0,0)` |
| Wall | 1,420 | 0 | `(1,0)` |
| Collision barrier | 446 | 0 | `(1,0)` |
| Solid cover | 132 | 0 | `(2,0)` |
| Marker | 0 | n/a | n/a |

- Persisted wall/barrier overlap: `(23,156)`, `(23,158)`
- Wall/cover, barrier/cover, and triple intersections: empty
- Independently derived unique blocking union: 1,996
- Complete runtime collision set equals the persisted union
- Atlas precedence: wall, then cover, then barrier
- Persisted source layers unchanged by forward synchronization
- Reverse synchronization untouched
- Blueprint mechanics: 68/68
- Staff entrance lane clear; front crowd rope blocked
- Safe covers emit no cells
- Owner-suite and basement closed islands represented
- No RouteBlockers
- ArtRoot has zero tile cells and collision nodes
- Phase 3A lifecycle teardown remains zero-orphan

## Atomic Promotion

Immediately before promotion, production still matched the baseline SHA. Staged bytes were copied to an adjacent non-resource replacement temp and hash-verified. `.NET System.IO.File.Replace` atomically replaced production while creating an adjacent exact-baseline backup. No direct overwrite or fallback path was used.

Immediate production hash, ResourceLoader reload, instantiation, and persisted counts passed. The exact-baseline adjacent rollback backup was retained through all post-promotion validation and removed only after every gate passed.

## Validation

- Blueprint validator: PASS, 3 specs, 55 mechanic types, no failures or warnings
- Candidate inspection: PASS
- Staged inspection and byte proof: PASS
- Pre-promotion combined GdUnit: PASS 67/67 across 8 suites, zero errors/failures/skips/flaky/orphans, exit 0
- Atomic promotion and immediate reload: PASS
- Post-promotion combined GdUnit: PASS 67/67 across 8 suites, zero errors/failures/skips/flaky/orphans, exit 0
- Velvet production smoke: PASS, mission started and loaded, exit 0
- Taco production smoke: PASS, mission started and loaded, exit 0; known invalid-UID text-path fallback warning only
- Exact scene diff: PASS, four additions and zero removals
- `git diff --check`: PASS except the pre-existing generated-guide line-ending warning

Evidence:

- `reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_03b_retry4_work/`
- `reports/velvet_paw_collision_phase3b_retry4/`

No roadmap edit, Phase 4 work, stage, commit, push, branch change, or history operation occurred. Work stayed in the explicitly requested narrow Phase 3B slice.
