# Velvet Paw Collision Phase 5 Physics Proof Report

Date: 2026-07-11
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: FAILED AND ROLLED BACK; Phase 5 is not applied

## Scope And Final State

Executed only the requested Phase 5 physical movement/seam proof. Phase 6, roadmap, implementation blueprint, shared TileSet collision, Taco's `Phase0JB2WallCellCollisionGenerator.gd`, project settings, autoloads, commit, push, stage, branch, and history were not changed.

The two-attempt gate did not pass. Per the stop rule, all Phase 5 runtime/test changes were removed and the production scene was restored byte-for-byte from the Phase 5 checkpoint. Final production is the exact Phase 4 state:

- Scene SHA-256: `5512dfbb3856e505cff6f61b5d68acec9707a80cb317f137b4279854c99ef440`
- Scene Git blob: `0e0707a6e88c682c400c5c6c884af26cc9127cf2`
- Four `tile_map_data` payloads remain.
- Six Phase 4 blocker shape subresources remain.
- `GeneratedRuntimeCollision` is absent.
- `LayoutWallCellCollisionGenerator.gd` and the focused physics suite are absent after rollback.

## Checkpoint

Created before diagnostics at:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_05_pre_physics_proof/`

| Snapshot | SHA-256 |
| --- | --- |
| `VelvetPawJazzClub_Editable.tscn` | `5512dfbb3856e505cff6f61b5d68acec9707a80cb317f137b4279854c99ef440` |
| `VelvetPawJazzClubProductionSkeletonTest.gd` | `1332a1ecf103c8e67c1745ef5583d04cfb31f59c482786d932146dd0f4b70b1d` |
| `IsoMissionBase.gd` | `8da9a17657c3c1137ac78a11aca707225d7ee0102c98f3536b90aaf4e113450d` |
| `LevelBlueprintLayoutPainter.gd` | `1fd4d3928d456ba65552abb6f2e3c009fdb6a9e414ffc342954f07bf11b5cb30` |

The Phase 4 scene SHA/blob requested by the prompt were recorded before work and reverified after rollback.

## Preflight Diagnostics

All probes used an actual in-tree Velvet scene, `PhysicsDirectSpaceState2D.cast_motion`/`intersect_shape`, collision mask `4`, and a `24x24 RectangleShape2D`.

An initial adjacent-cell perpendicular scan evaluated 20 eligible compact TileMap seam crossings and found no leaks. A named cardinal/diagonal measurement then exposed the missed failure at adjacent wall cells `(54,10)` and `(54,11)`:

| Probe | From | To | Safe fraction | Result |
| --- | --- | --- | ---: | --- |
| Cardinal seam | `(3504,232)` | `(3504,136)` | `1.000000` | LEAK |
| Diagonal seam | `(3482.534,226.9325)` | `(3525.466,141.0675)` | `0.265625` | blocked |

Representative compact-collision preflight fractions:

| Sample | From -> To | Safe fraction |
| --- | --- | ---: |
| Exterior north | `(1600,368) -> (1600,528)` | `0.496094` |
| Owner island north | `(3904,112) -> (3904,272)` | `0.496094` |
| Bar | `(576,1136) -> (576,1424)` | `0.386719` |
| DJ rig | `(1792,432) -> (1792,720)` | `0.053711` |
| Piano | `(864,688) -> (864,976)` | `0.332031` |
| Couch | `(2432,560) -> (2432,816)` | `0.433594` |
| Booth north/south | `(2848,1600) -> (2848,1952)` / `(2848,1984) -> (2848,2336)` | `0.406250` each |
| Desk | `(3968,352) -> (3968,672)` | `0.398438` |
| Rack | `(3872,1760) -> (3872,2048)` | `0.386719` |
| Shelf | `(3968,2208) -> (3968,2496)` | `0.441406` |
| Solid covers | subwoofer/costume/dumpster/crates motions | `0.220703` to `0.277344` |
| Front rope | `(1440,2400) -> (1440,2656)` | `0.433594` |
| Four fixed openings | exact motions below | `1.000000` each |
| Five closed dynamic blockers | exact motions below | `0.039063` to `0.324219` |

The fixed-opening motions were staff `(2976,2400) -> (2976,2656)`, bathroom stage row `(320,928) -> (320,1120)`, bathroom divider `(480,928) -> (704,928)`, and VIP rope `(2528,1696) -> (2784,1696)`. Reverse casts were also clear in the gate runs.

## Authorized Repair Attempt

Because the cardinal compact seam leaked, the authorized narrow repair was implemented before gate attempt 1:

- Temporary generic `@tool StaticBody2D` script: `src/missions/iso/runtime/LayoutWallCellCollisionGenerator.gd`.
- Temporary Velvet-only path: `GameplayRoot/GeneratedRuntimeCollision/WallCollision/WallCellBody`.
- Source: exported `../../../LayoutRoot/WallLayer` path.
- Layer/mask: `4/0`.
- Geometry: transform-aware basis derived through `WallLayer.to_global(...)` then body `to_local(...)`; expanded diamond factor `1.08`.
- Determinism: sorted source cells, deterministic names and source-cell metadata.
- Lifecycle: immediate ownership-safe removal/free before regeneration.
- Runtime proof before rollback: 1,420 source cells/shapes, basis deltas `(64,0)` and `(32,16)`, repeat regeneration retained exact first/last names and count, generation completed under the asserted `500,000 usec` bound, and lifecycle tests reported zero orphans.

The proxy and scene nodes were rolled back after attempt 2 failed.

## Focused Physics Coverage Attempted

The temporary nine-test suite attempted direct physical proof for:

- Exterior and owner/basement island walls from both sides.
- Bar, DJ rig, piano, couch, both booths, desk, rack, shelf, four solid covers, and front rope.
- All four fixed openings in both directions.
- Bar Corner and Dance Floor Silhouette 3x3 query grids.
- Five dynamic blockers closed and after their existing unlock methods.
- Spawn and all three teleport targets using 3x3 query grids; the return target was checked after hatch unlock.
- Eight owner-suite/basement inside-to-void perimeter casts.
- Cardinal and diagonal adjacent-cell seam casts.
- Explicit teardown orphan comparison.

Dynamic motions were:

| Blocker | Motion |
| --- | --- |
| Staff gate | `(2048,928) -> (2048,1184)` |
| Backstage hatch | `(1024,928) -> (1024,1184)` |
| Server vault | `(3936,2016) -> (3936,2272)` |
| Owner stairs attempt 1 | `(3008,1056) -> (3008,1312)` |
| Owner stairs attempt 2 | `(3008,1080) -> (3008,1312)` |
| Escape hatch | `(4224,2560) -> (4224,2816)` |

In both attempts all five closed casts blocked and all five post-unlock casts returned safe fraction `1.000000`. The failure was the additional `intersect_shape` requirement at the owner-stairs start point: both `y=1056` and the one permitted repaired sample `y=1080` overlapped the adjacent permanent wall proxy after unlock. The suite stopped there, so the later landing, island-leak, seam-regression, and explicit teardown cases did not receive a completed final gate execution even though other lifecycle suites remained clean.

## Gate Results

Attempt 1:

- Combined GdUnit: FAIL; console reported 75 cases across 9 suites, 0 errors, 1 assertion failure, 0 flaky/skipped/orphans. XML declares 79 tests and records the same single failure.
- All eight prior Phase 4/3B/promotion/lifecycle/Velvet/resolver suites passed.
- Focused failure: `owner_stairs_open start` at `(3008,1056)`; cast itself was clear at `1.000000`.
- Allowed narrow repair: changed only the focused test start sample to `(3008,1080)`.
- Blueprint validator: PASS, 3 specs, 55 mechanic types, no failures/warnings.

Attempt 2:

- Combined GdUnit: FAIL; same aggregate result and same focused assertion class.
- All eight prior suites again passed.
- Focused failure: `owner_stairs_open start` at `(3008,1080)`; closed cast `0.115234`, open cast `1.000000`, but start still overlapped the permanent wall proxy.
- Blueprint validator: PASS.
- Required action: rollback and stop; performed.

Evidence:

- `reports/velvet_paw_collision_phase5/preflight/`
- `reports/velvet_paw_collision_phase5/preflight_retry/`
- `reports/velvet_paw_collision_phase5/preflight_named/`
- `reports/velvet_paw_collision_phase5/post_repair_preflight/`
- `reports/velvet_paw_collision_phase5/attempt_1/report_1/results.xml`
- `reports/velvet_paw_collision_phase5/attempt_2/report_1/results.xml`

## Validation Not Completed

The two-attempt failure prevented a successful full gate. Velvet/Taco post-gate smokes and a passing final `git diff --check` were not run after rollback because the prompt required stop after attempt 2. The attempt-1 `git diff --check` was blocked only by pre-existing unrelated whitespace in modified `reports/report_104/godot_report_log.html` plus the known generated-guide line-ending warning; that unrelated file was not modified.

Exact permanent counts/signatures remain the Phase 4 values by byte-identical scene rollback: floor 9,996; wall 1,420; barrier 446; solid cover 132; marker 0; union 1,996; six dynamic shapes unchanged. The prior suites passed those contracts in both attempts before rollback.

## Risk And Next Step

Phase 5 remains incomplete. The compact TileMap has a demonstrated cardinal seam leak, while the attempted expanded wall proxy makes the sampled owner-stairs approach overlap the adjacent permanent stage-row wall even though the route cast becomes fully clear after unlock. A future explicitly authorized retry should first map the exact owner-stairs usable approach envelope with point queries, then decide whether a smaller proxy expansion or a different valid lane sample proves both seam sealing and route usability. No further repair was attempted here.

Work stayed in the explicitly requested narrow Phase 5 slice rather than grouped-milestone mode. No roadmap or Phase 6 work occurred.
