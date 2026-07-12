# Velvet Paw Collision Phase 5 Retry Physics Proof Report

Date: 2026-07-11
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 1 of 2
Result: PASS; Phase 5 proxy applied

## Scope And Outcome

Executed only the freshly authorized Phase 5 retry. Restored the validated generic mission-owned wall-cell proxy, added it only to Velvet Paw, corrected the owner-stairs physical model before attempt 1, and completed direct in-tree physics proof with a `24x24 RectangleShape2D`.

No Phase 6, roadmap, implementation blueprint, Taco scene/script, shared TileSet, `IsoMissionBase`, project settings, autoload, commit, push, stage, branch, or history work occurred.

Final files added or changed by this retry:

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/missions/iso/runtime/LayoutWallCellCollisionGenerator.gd`
- `tests/mission_authoring/VelvetPawJazzClubPhysicsTest.gd`
- `reports/ai/2026-07-11_velvet_paw_collision_phase5_retry_physics_proof_report.md`

## Checkpoint

Created before edits:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_05_retry_pre_physics_proof/`

The checkpoint contains the Phase 4 production scene and all eight existing combined-gate test scripts. `planned_new_files.txt` records that the proxy and focused physics suite were absent.

Key checkpoint hashes:

| Snapshot | SHA-256 |
| --- | --- |
| `VelvetPawJazzClub_Editable.tscn` | `5512dfbb3856e505cff6f61b5d68acec9707a80cb317f137b4279854c99ef440` |
| `VelvetPawJazzClubProductionSkeletonTest.gd` | `1332a1ecf103c8e67c1745ef5583d04cfb31f59c482786d932146dd0f4b70b1d` |
| `IsoMissionBaseLifecycleTest.gd` | `39fca8fa0494103c3e4ab45063fa80de730629e3858148c03dcd702779f6f6ba` |
| `LevelBlueprintLayoutPainterTest.gd` | `e071febdbd84890e382ccb5c3aa724e2e8bf36b8b5cf8e70af2adc9ed519fb6b` |
| `TileDataPromotionHelperTest.gd` | `1dd1dc80fb9343336d323fb413f934b2dbaa6d4458cef0a885d7a39d6543cd09` |

Recorded Phase 4 scene Git blob: `0e0707a6e88c682c400c5c6c884af26cc9127cf2`.

## Proxy Implementation

Added generic `@tool StaticBody2D` `LayoutWallCellCollisionGenerator` with:

- Exported `wall_layer_path`, default `../../../LayoutRoot/WallLayer`.
- Expansion factor `1.08`.
- Collision layer `4`, mask `0`.
- Transform-aware basis conversion through source `to_global` and proxy-body `to_local`.
- Source cells sorted by Y then X.
- Deterministic `WallCell_%04d_%d_%d` names.
- `generated_by`, `collision_type`, and `source_cell` metadata.
- Immediate ownership-safe removal and `free()` before regeneration.
- Shape count, source count, basis, and generation-time metadata.

Velvet-only hierarchy:

`GameplayRoot/GeneratedRuntimeCollision/WallCollision/WallCellBody`

Runtime proof:

- Source wall cells: 1,420.
- Generated polygons: 1,420.
- Basis: X `(64,0)`, Y `(32,16)`.
- Focused evidence generation time: `24,287 usec`.
- Repeated regeneration retained exact count and deterministic first/last names.
- Teardown and combined suites reported zero orphans.

Final hashes:

| File | SHA-256 | Git blob |
| --- | --- | --- |
| Production scene | `8711593e9f448845dc2960ff0edb78afa27a4c972100ab1677aedd7e328b3e91` | `2912248da577f51fceea9f4e69dbde55f3f1ece4` |
| Proxy script | `8d0627dc9e1b73d65a1e8631f6c2648e0f31b51faaeb99bbe02dfdae363a1da1` | not recorded |
| Physics test | `78e67631c7039ba8d8eaae3cbc7d30671d51165d93a24db5ce61a18f0290481a` | not recorded |

## Owner Stairs Correction

Points `(3008,1056)` and `(3008,1080)` are non-route diagnostics only. No walkability assertion uses them.

Direct query attribution with the `24x24` shape:

- `(3008,1056)` intersects `GameplayRoot/GameplayCollisionLayer` and proxy source cells `[46,64]` and `[47,64]`.
- Proxy polygons were respectively `[(2924.16,1031.36),(2993.28,1031.36),(3027.84,1048.64),(2958.72,1048.64)]` and `[(2988.16,1031.36),(3057.28,1031.36),(3091.84,1048.64),(3022.72,1048.64)]`.
- `(3008,1080)` intersects only `GameplayRoot/GameplayCollisionLayer`, shape index 13 in that run.

These are measured diagnostics, not assumed attribution. No required valid point failed, so no failure-only collider report was needed.

Owner route proof:

- Closed south cast `(3008,1312) -> (3008,1128)`: blocked at `0.628906`.
- Existing `unlock()` succeeded and `PortalPadShape.disabled == true`.
- Awaited one physics frame and one process frame.
- Open south cast `(3008,1312) -> (3008,1120)`: `1.000000` clear.
- Reverse cast `(3008,1120) -> (3008,1312)`: `1.000000` clear.
- Point queries clear at `(3008,1120)`, `(3008,1216)`, and `(3008,1312)`.
- Exact teleport grid clear: X `2996/3008/3020`, Y `1108/1120/1132`.

## Physical Evidence

All tests used the actual in-tree physics world, collision mask `4`, and `PhysicsDirectSpaceState2D.cast_motion` or `intersect_shape` with a `24x24 RectangleShape2D`.

Representative walls, both directions:

| Motion | Forward | Reverse |
| --- | ---: | ---: |
| Exterior north `(1600,368) <-> (1600,528)` | `0.269531` | `0.011230` |
| Owner north `(3904,112) <-> (3904,272)` | `0.269531` | `0.011230` |
| Basement north `(3904,1648) <-> (3904,1808)` | `0.269531` | `0.011230` |

Permanent blockers:

| Blocker | Safe fraction |
| --- | ---: |
| Bar counter | `0.386719` |
| DJ rig | `0.039063` |
| Grand piano | `0.332031` |
| Green-room couch | `0.433594` |
| VIP booths north/south | `0.406250` each |
| Owner desk | `0.398438` |
| Server rack | `0.091797` |
| Storage shelf | `0.441406` |
| Subwoofer solid cover | `0.253906` |
| Costume rack solid cover | `0.277344` |
| Dumpster / basement crates | `0.220703` each |
| Front crowd rope | `0.433594` |

All four fixed openings passed in both directions at `1.000000`:

- Staff side: `(2976,2400) <-> (2976,2656)`.
- Stage-row bathroom: `(320,928) <-> (320,1120)`.
- Bathroom divider: `(480,928) <-> (704,928)`.
- VIP rope: `(2528,1696) <-> (2784,1696)`.

Bar Corner and Dance Floor Silhouette each passed all nine 3x3 query points.

Other dynamic blockers:

| Blocker | Closed | Open after existing method and flush |
| --- | ---: | ---: |
| Staff gate | `0.324219` | `1.000000` |
| Backstage hatch | `0.324219` | `1.000000` |
| Server vault | `0.324219` | `1.000000` |
| Escape hatch | `0.197266` | `1.000000` |

Every configured target shape was asserted disabled after its existing unlock method.

Landing clearance passed with no blocked samples:

- Spawn `(256,2880)`, 3x3 spacing 24.
- Basement target `(3616,2944)`, 3x3 spacing 24.
- Suite target `(3616,1216)`, 3x3 spacing 24.
- Return target `(1024,1120)`, 3x3 spacing 24 after backstage-hatch unlock and physics flush.

Owner-suite and basement leak proof blocked all eight inside-to-void casts. Safe fractions ranged from `0.068359` to `0.355469`.

Seam regression:

- Previously leaking cardinal `(3504,232) -> (3504,136)`: now blocked at `0.033203`.
- Diagonal `(3482.534,226.9325) -> (3525.466,141.0675)`: blocked at `0.167969`.

## Gate Attempt 1

- Combined GdUnit: PASS `80/80` across 9/9 suites, 0 errors/failures/flaky/skipped/orphans, exit 0.
- Focused physics suite: PASS `10/10`, including explicit teardown, 0 orphans.
- Blueprint validator: PASS, 3 specs, 55 mechanic types, no failures/warnings.
- Phase 3B permanent contract: PASS through prior suites; floor 9,996, wall 1,420, barrier 446, solid cover 132, marker 0, union 1,996.
- Phase 4 contract: PASS; five blocker bodies and six shapes unchanged.
- Tile payload comparison: 4 before / 4 after, exact string equality.
- Scene structural whitelist: PASS. Exact scene diff is one proxy script ext-resource plus `GeneratedRuntimeCollision`, `WallCollision`, and `WallCellBody`; no removals or rewrites.
- Velvet headless smoke: PASS; reached mission start and `Loaded level: VelvetPawJazzClub_Editable`.
- Taco headless smoke: PASS; reached mission start and `Loaded level: TacoBellIso_Editable`; existing Taco generator produced 2,380 polygons.
- Taco proxy, Taco scene, and shared TileSet diffs: empty.
- Targeted diff checks for the scene, proxy, and focused test: clean.
- Global `git diff --check`: exit 0 with only the known generated-guide CRLF warning.
- Godot DAP: not needed; no unexplained runtime failure remained.

Evidence:

- `reports/velvet_paw_collision_phase5_retry/attempt_1/report_1/results.xml`
- `reports/velvet_paw_collision_phase5_retry/focused_evidence/report_1/results.xml`
- `reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_05_retry_pre_physics_proof/`

## Risks And Rollback

The proxy creates 1,420 runtime `CollisionPolygon2D` nodes for Velvet. Measured generation was about 24 ms in the focused run and teardown was clean, but lower-spec hardware was not profiled. Compact TileMap collision remains present beneath the proxy; the proxy is additive and mission-local.

Rollback is the checkpoint scene plus removal of `LayoutWallCellCollisionGenerator.gd` and `VelvetPawJazzClubPhysicsTest.gd`.

Work stayed in the explicitly requested narrow Phase 5 slice rather than grouped-milestone mode. Phase 6 was not started.
