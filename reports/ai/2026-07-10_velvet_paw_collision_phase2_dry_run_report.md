# Velvet Paw Collision Protocol Phase 2 Dry-Run Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: PASS

## Scope

Executed only Phase 2 of the approved Velvet Paw collision protocol. Added a reusable editor-only deterministic dry-run analyzer and focused GdUnit coverage. The analyzer loads the supplied production scene cache-safely, instantiates it only in memory, resolves the five approved `LayoutRoot` `TileMapLayer` nodes, computes candidate cell sets through each layer's transforms, and frees the instance. It does not paint, pack, save, or mutate the scene or blueprint.

Phase 3 was not started. The production scene, blueprint, generated guide, roadmap, and implementation blueprint were not modified.

## Pre-Edit Checkpoint

Created before implementation:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_02_pre_dry_run/manifest.json`

The manifest records the protected scene, blueprint, and guide SHA-256 values, the production scene Git blob SHA-1, and all planned authored files. All planned implementation files were new, so no content snapshot was required.

## Files Added

- `src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd`
- `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd`
- `reports/ai/2026-07-10_velvet_paw_collision_phase2_dry_run_report.md`
- Phase 2 checkpoint manifest listed above
- Isolated GdUnit evidence under `reports/velvet_paw_collision_phase2/report_1/` and `report_2/`
- Preliminary focused development evidence under `reports/velvet_paw_collision_phase2_focus/`

Godot did not generate a `.uid` for the new painter during headless GdUnit/load validation, so no `.uid` was added manually.

## API

```gdscript
LevelBlueprintLayoutPainter.run(options: Dictionary = {}) -> Dictionary
```

Options:

- `scene_path: String`: required supplied scene path.
- `blueprint_path: String`: required supplied blueprint JSON path.
- `dry_run: bool`: defaults to `true`; `false` is refused with `Phase 2 is dry-run-only; save/apply requests are refused.`

The class is `@tool`, extends `RefCounted`, and has no autoload or runtime manager. Scene loading uses `ResourceLoader.CACHE_MODE_IGNORE`; blueprint loading and validation reuse `LevelBlueprintSpec.load_spec()`, `regions()`, `grid_size()`, `REGION_KINDS`, and `PAINT_LAYER_BY_KIND`.

## Functions

Public:

- `run(options)`

Analysis and geometry:

- `_resolve_layers(scene_root, result)`
- `_analyze(spec, contract, layers, result)`
- `_rect_cells(layer, world_rect)`
- `_polyline_cells(layer, points, thickness)`
- `_raster_line(start, finish)`
- `_minimum_world_cell_span(layer)`
- `_analyze_cover(spec, contract, cover_cells)`
- `_analyze_openings(contract, layers, wall_cells, barrier_cells, solid_cover_cells)`
- `_has_continuous_clear_lane(layer, clear_cells, world_rect)`
- `_analyze_closed_islands(contract, wall_layer, floor_layer, wall_cells, floor_cells, wall_thickness)`
- `_representative_data(layers, cells_by_kind)`

Determinism, conversion, and protection:

- `_empty_result(scene_path, blueprint_path, dry_run)`
- `_used_cell_counts(layers)`
- `_rect_from_array(value)`
- `_points_from_array(value)`
- `_sorted_cells(cells)`
- `_sorted_cell_arrays(cells)`
- `_sorted_strings(value)`
- `_contract_label(region_label, contract_labels)`
- `_sha256(path)`
- `_finalize_hashes(result)`

All world/cell conversions use the instantiated layer's `to_local()`, `local_to_map()`, `map_to_local()`, and `to_global()` methods. No blueprint coordinate is converted to a cell by manual division.

## Report Schema

Top-level fields:

- `ok`, `dry_run`, `errors`, `warnings`
- `scene_path`, `blueprint_path`
- `source_hashes.scene.before/after`, `source_hashes.blueprint.before/after`
- `layer_paths`
- `per_kind_cell_counts`
- `per_region[]`: `index`, `kind`, `label`, `blocks_movement`, `cell_count`, sorted `cells`
- `opening_analysis[]`: id/state/classification, sorted candidate/clear/blocker cells and counts, connected-lane result, current-barrier result, `future_blocker_painted=false`
- `closed_island_analysis[]`: perimeter/represented/contained counts, sorted perimeter cells, representation booleans
- `cover_analysis`: sorted safe/solid labels, semantic counts, solid cell count, sorted region classifications
- `representative_data[]`: kind, approved layer path, cell, world point, and round-trip cell
- `in_memory_layer_cell_counts.before/after`
- `mutation_flags`: scene, blueprint, in-memory tiles, tile writes, node additions, node removals
- `save_flags`: any save, scene pack, packed scene save, resource save

All mutation and save flags are `false` on the successful run. In-memory layer used-cell counts are identical before and after. Arrays are blueprint-order or explicitly sorted by cell, label, opening id, or island id.

## Semantic Results

- Regions: 54 total: 7 floor, 25 wall, 10 movement-blocking collision barriers, 6 cover, and 6 marker records.
- Floor regions: exactly 7.
- Movement-blocking barrier regions: exactly 10, including `Front Entrance Crowd Rope`.
- Solid cover labels: exactly 4: `Alley Dumpster`, `Basement Crates`, `Costume Rack`, `Subwoofer Stack`.
- Safe non-solid cover labels: exactly 2: `Bar Corner`, `Dance Floor Silhouette`.
- Non-solid cover regions contribute zero cover paint cells.
- Openings: exactly 9: 4 `fixed_open/usable_route`, 1 `permanent_blocker/crowd_rope`, 3 `dynamic/gate`, and 1 `dynamic/portal_gated`.
- All four fixed-open openings have a connected clear candidate component spanning the passage axis.
- `staff_side_club_entrance` is clear with 10 clear candidate cells.
- `front_entrance_crowd_rope` is blocked by its current collision barrier across all 12 candidate cells.
- Dynamic openings report current geometry but never add their future blockers.
- `owner_suite` containment is represented by 210/210 perimeter cells with 1,064 contained floor cells.
- `basement` containment is represented by 234/234 perimeter cells with 1,232 contained floor cells.
- All five approved layer paths resolve to `TileMapLayer` instances.

## Unique Cell Counts

Counts are transform-derived from the scene's actual isometric `TileMapLayer` setup and are not hardcoded test expectations:

| Kind | Unique cells |
| --- | ---: |
| Floor | 9,996 |
| Wall | 1,420 |
| Collision barrier | 446 |
| Solid movement-blocking cover | 132 |
| Marker | 0 |

Marker circles are semantic/debug records and are not part of Phase 2's requested floor/wall/barrier/solid-cover cell computation.

## Tests

Added `LevelBlueprintLayoutPainterTest.gd` with 8 focused cases:

1. Dry-run success, protected production SHA-256, mutation/save flags.
2. Seven floor regions and nonempty wall/barrier/solid-cover sets; ten barriers including front rope.
3. Four solid and two safe non-solid cover labels; only solid cover emits cells.
4. Nine exact opening state/classification pairs; staff lane clear; front gap barrier-blocked.
5. Owner-suite and basement closed-island containment.
6. Five approved layer paths.
7. Non-dry-run rejection without mutation.
8. Repeated-run deterministic counts, representative data, and opening analysis.

Final isolated combined GdUnit command covered the new painter tests plus existing Velvet production and mission resolver tests.

Result: PASS, 24/24, 0 errors, 0 failures, 0 skipped, 0 flaky, 0 orphans.

Final XML: `reports/velvet_paw_collision_phase2/report_2/results.xml`.

## Gate Attempts

Attempt 1: FAIL after command-level checks passed. Self-review found that safe non-solid cover regions were correctly classified but still entered the aggregate cover candidate set. This violated the Phase 2 rule that only `blocks_movement=true` cover may produce cells.

Allowed narrow repair: guarded cover geometry collection by `blocks_movement`, passed `solid_cover_cells` into cover analysis, and strengthened the existing cover test to require zero cells for non-solid regions and nonzero cells for solid regions. No blueprint or guide repair was needed.

Attempt 2: PASS complete gate.

## Validation

1. Godot script parse/load through focused and combined GdUnit: PASS.
2. Final isolated GdUnit (`report_2`): PASS 24/24.
3. Blueprint validator: PASS; 3 specs, 55 mechanic types, 0 failures, 0 warnings.
4. Production scene Git blob hash: PASS `46dfb24634c626bccaa65b6f054120bc4b9cbc86`.
5. Protected SHA-256 values: PASS 3/3 against checkpoint.
6. Production scene headless smoke: PASS, exit 0; reached `Mission started: velvet_paw_jazz_club` and `Loaded level: VelvetPawJazzClub_Editable`.
7. `git diff --check`: PASS. Existing generated-guide CRLF/LF notice only.
8. Scene-file status verification: PASS; zero scene files changed.

The production forced-quit smoke retained the known CanvasItem/ObjectDB leak and detached-node path noise documented in Phase 1. It did not produce a parse/load failure.

## Protected Hashes

| File | SHA-256 |
| --- | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | `d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c` |
| `docs/blueprints/velvet_paw_jazz_club.blueprint.json` | `c2ac059bfd98e476f056fc3ea34250b13721497d4e1863bc81bdb3c8d206e3f9` |
| `docs/blueprints/velvet_paw_jazz_club.build_guide.md` | `af7eb7386a46368489c0760c1f1b73f2112321b26c06c18ec3121c2e0c4bc58f` |

## Risks

- Phase 2 proves deterministic candidate geometry, not runtime collision behavior; no cell was painted.
- Counts are intentionally based on actual layer transforms and TileSet layout. A future layer transform or TileSet topology change should alter the report and trigger review rather than preserve stale totals.
- Opening analysis validates connected candidate-cell lanes against planned wall, barrier, and solid-cover sets. It does not replace Phase 3 physics/navigation playtesting with the player body.
- Dynamic gates and portal blockers are classified but deliberately absent from paint sets.
- The production headless forced-quit leak noise remains pre-existing.

## Phase 3 Entry Contract

Phase 3 may begin only under separate explicit authorization. It must:

1. Start from the verified production scene Git blob `46dfb24634c626bccaa65b6f054120bc4b9cbc86` and the protected Phase 1 blueprint/guide hashes above.
2. Create its own pre-apply checkpoint and manifest before any scene edit.
3. Consume the Phase 2 deterministic sets without changing the collision contract unless a separately gated hard data bug is proven.
4. Paint only the approved floor, wall, movement-blocking barrier, and solid-cover sets; keep safe cover and future dynamic blockers unpainted.
5. Preserve the nine opening classifications, all fixed-open connected lanes, the front-rope blocker, and both closed teleport islands.
6. Save only through a separately authorized Phase 3 apply path, then rerun static validation, GdUnit, production hash/change audit, headless smoke, and manual collision QA.

Work stayed as one narrow Phase 2 slice rather than grouped-milestone mode because the user explicitly prohibited Phase 3. No stage, commit, push, branch change, history rewrite, roadmap edit, implementation-blueprint edit, blueprint edit, guide edit, or production-scene save occurred.
