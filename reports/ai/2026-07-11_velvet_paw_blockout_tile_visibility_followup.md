# Velvet Paw Blockout Tile Visibility Follow-up

Date: 2026-07-11
Scope: visual-only suppression after the seven-phase collision milestone
Operating mode: narrow follow-up slice, not grouped-milestone mode

## Outcome

Velvet Paw no longer renders the white floor, brown cover, black wall, or black collision-barrier blockout tiles. The authoritative TileMap cells remain serialized and enabled so collision, camera bounds, layout signatures, forward synchronization, dynamic routes, and the wall-seam proxy continue to work.

## Implementation

`scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` now serializes `visible = false` on:

- `GameplayRoot/GameplayFloorLayer`
- `GameplayRoot/GameplayCollisionLayer`
- `GameplayRoot/LayoutRoot/FloorLayer`
- `GameplayRoot/LayoutRoot/WallLayer`
- `GameplayRoot/LayoutRoot/CoverLayer`
- `GameplayRoot/LayoutRoot/CollisionBarrierLayer`

The floor, wall, and collision-barrier source layers were already hidden. This follow-up hid the source cover layer and both runtime destination layers. No layer was cleared or disabled, and runtime `GameplayCollisionLayer.collision_enabled` remains true.

`tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` now asserts all six blockout layers remain hidden before and after forward synchronization, both runtime layers remain enabled, floor collision remains disabled, gameplay collision remains enabled, and synchronized data still matches the authoritative sources.

## Accepted Floor Drift

The first meaningful focused run found that the current production scene already contained 10,058 floor cells, 62 more than the 9,996-cell collision-closeout snapshot. The visibility patch changed only three scene properties and did not modify `tile_map_data`. Jake explicitly chose to preserve the 62 additional non-colliding floor cells.

Current accepted counts:

- Floor: 10,058
- Wall: 1,420
- Collision barrier: 446
- Solid cover: 132
- Runtime blocking union: 1,996
- Wall proxy polygons: 1,420

The production and runtime QA expectations, roadmap, and implementation blueprint now describe the accepted floor count and hidden-rendering requirement. Collision counts and behavior did not change.

## Validation

- Focused six-suite GdUnit gate: PASS 51/51, zero errors, failures, flaky tests, skips, or orphans. Evidence: `reports/velvet_paw_blockout_visibility_focused/report_2/results.xml`.
- Full `tests/mission_authoring`: PASS 449/449 across 57 suites, zero errors, failures, flaky tests, skips, or orphans. Evidence: `reports/velvet_paw_blockout_visibility_full/report_1/results.xml`.
- Level blueprint validator: PASS, 3 specs, 55 mechanic types, zero failures/warnings.
- Mission Dock static validator: PASS, zero failures/warnings.
- Velvet clean-exit harness: PASS, exit 0, `loaded=1 proxy_shapes=1420 freed=1 clean_quit=1`.
- Velvet headless production smoke: PASS, exit 0, mission started and scene loaded.
- Physical wall, solid-cover, barrier, fixed-opening, dynamic-route, seam, perimeter, and teardown tests all passed with the layers hidden.

The initial test command used an invalid GdUnit option (`--report-dir`) and exited during CLI parsing without running tests. The first meaningful focused execution then exposed the pre-existing 62-cell floor drift. After Jake chose to preserve those cells and the contract was updated, the complete focused gate passed.

## Protocol Rule

Future missions using the seven-phase collision protocol must include a final blockout-visual suppression gate:

- Set `visible = false` on all populated source layout floor/wall/cover/collision-barrier layers and synchronized gameplay floor/collision layers.
- Keep the layers enabled and retain their `tile_map_data`.
- Keep runtime gameplay collision enabled.
- Assert hidden visibility, retained cell counts/signatures, collision enablement, physical blocking/openings, camera bounds, and lifecycle cleanliness.
- Prefer serialized visibility over deferred runtime hiding so editor clutter and one-frame flashes are avoided.

The existing Nowledge Mem protocol entry was updated with this rule.

## Runtime Guard Correction

Jake's first normal rendered launch showed that the two destination layers were visible again even though the earlier automated gate had passed. Inspection confirmed a later Godot editor save retained `visible = false` on populated source layers but omitted it from the initially empty `GameplayFloorLayer` and `GameplayCollisionLayer`. Runtime forward synchronization then populated and rendered those default-visible layers.

The scene flags were restored, and `VelvetPawJazzClubMissionController._ready()` now re-hides all six blockout layers before the first rendered frame. A regression deliberately makes all six layers visible and proves the mission controller suppresses them again. Floor validation now protects the 9,996-cell blueprint baseline and exact source-to-runtime equality instead of chasing mutable non-colliding floor additions made in the open editor.

Runtime-guard validation:

- Focused six-suite gate: PASS 52/52, zero errors, failures, flaky tests, skips, or orphans. Evidence: `reports/velvet_paw_blockout_visibility_runtime_guard_focused/report_2/results.xml`.
- Full `tests/mission_authoring`: PASS 450/450 across 57 suites, zero errors, failures, flaky tests, skips, or orphans. Evidence: `reports/velvet_paw_blockout_visibility_runtime_guard_full/report_1/results.xml`.
- Blueprint and Mission Dock validators: PASS with zero failures/warnings.
- Clean-exit harness: PASS, `loaded=1 proxy_shapes=1420 freed=1 clean_quit=1`. The known MCP port conflict appeared because another runtime was open, but did not affect scene load, teardown, or exit.
- `git diff --check`: PASS except the known generated-guide CRLF notice.

## Remaining Manual QA

A headless run cannot visually prove pixel output. Open Velvet Paw normally and confirm no white, brown, or black blockout paint appears, then enable visible collision shapes once to confirm the invisible collision still aligns acceptably with final art and route openings.

No files were staged, committed, or pushed.
