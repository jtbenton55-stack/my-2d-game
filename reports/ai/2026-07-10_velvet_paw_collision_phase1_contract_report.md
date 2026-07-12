# Velvet Paw Collision Protocol Phase 1 Contract Report

Date: 2026-07-10
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 1 of 2
Result: PASS

## Scope

Executed only Phase 1 of the approved Velvet Paw collision protocol. This phase made collision intent explicit in blueprint data and made wall openings visible in the existing authoring overlay by splitting continuous wall polylines into separate region records. No scene, runtime script, test, roadmap, implementation blueprint, `project.godot`, or autoload was modified.

## Pre-Edit Checkpoint

Created exact non-importable snapshots under:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_01_pre_contract/`

Files:

- `velvet_paw_jazz_club.blueprint.json.snapshot`: 30244 bytes, SHA-256 `951c42fe703d813e5ab643de0fb3e5683f09d7ce4f3dbcab24832cf7673cbf74`
- `velvet_paw_jazz_club.build_guide.md.snapshot`: 35732 bytes, SHA-256 `5b397aad7d294e7abdb6a0d28fd551c1daf681f2c3de0f033da7b98a18a775e2`
- `manifest.json`: checkpoint metadata and source/snapshot hashes

Post-gate checkpoint verification passed 2/2 hash and size checks.

## Files Changed

- `docs/blueprints/velvet_paw_jazz_club.blueprint.json`
- `docs/blueprints/velvet_paw_jazz_club.build_guide.md` (regenerated)
- `reports/ai/2026-07-10_velvet_paw_collision_phase1_contract_report.md`
- Recovery checkpoint files listed above
- Isolated GdUnit output under `reports/velvet_paw_collision_phase1/report_1/`

Pre-existing unrelated `reports/report_104/godot_report_log.html` modification and `reports/velvet_paw_collision_phase0/` output were left untouched.

## Contract

Added top-level `collision_contract` version 1 with:

- 64 px grid alignment and nominal wall thickness.
- 24 x 24 ISO player footprint.
- Preferred ordinary route clearance of 3 cells / 192 px.
- 4-cell / 256 px openings where required to center an opening on an existing mechanic center between grid lines.
- Closed owner-suite and basement teleport-island records.
- Safe non-solid and solid cover label sets.
- Movement-blocking collision-barrier default.
- Nine explicit opening records.

Exact opening rectangles:

| Opening | State / classification | Rect `[x, y, w, h]` | Clear width |
| --- | --- | --- | --- |
| Front entrance crowd rope | permanent blocker / crowd rope | `[1344, 2496, 192, 64]` | 192 px |
| Staff-side club entrance | fixed open / usable route | `[2880, 2496, 192, 64]` | 192 px |
| Stage-row bathroom access | fixed open / usable route | `[192, 1024, 256, 64]` | 256 px |
| Stage-row backstage hatch | dynamic / portal gated | `[896, 1024, 256, 64]` | 256 px |
| Stage-row staff gate | dynamic / gate | `[1920, 1024, 256, 64]` | 256 px |
| Bathroom-divider south end | fixed open / usable route | `[576, 832, 64, 192]` | 192 px |
| Stage-wing-divider south gate | dynamic / gate | `[2048, 832, 64, 192]` | 192 px |
| VIP-rope north end | fixed open / usable route | `[2624, 1600, 64, 192]` | 192 px |
| Server-cage south-center door | dynamic / gate | `[3840, 2112, 192, 64]` | 192 px |

The staff entrance is centered at x=2976 and includes the existing x=2944 trigger center. The front entrance is visibly open in wall segments but has a movement-blocking `collision_barrier` crowd-rope region. The street/alley floor now has west, south, east, and split north exposed-perimeter wall records while preserving the front and staff gap geometry.

Cover movement intent:

- `Bar Corner`: `blocks_movement=false`
- `Dance Floor Silhouette`: `blocks_movement=false`
- `Subwoofer Stack`: `blocks_movement=true`
- `Costume Rack`: `blocks_movement=true`
- `Alley Dumpster`: `blocks_movement=true`
- `Basement Crates`: `blocks_movement=true`
- All 10 collision-barrier regions: `blocks_movement=true`

## Data Integrity

- Regions before: 36
- Regions after: 54
- Mechanic slots before/after: 68 / 68
- Mechanic slot JSON data comparison: exact match
- Coverage: 68/68, no missing or mismatched slots
- Region kinds remain limited to `floor`, `wall`, `cover`, `collision_barrier`, and `marker`
- All nine opening rectangles are 64 px grid aligned and declare at least 192 px clear width
- Current blueprint SHA-256: `c2ac059bfd98e476f056fc3ea34250b13721497d4e1863bc81bdb3c8d206e3f9`
- Current generated guide SHA-256: `af7eb7386a46368489c0760c1f1b73f2112321b26c06c18ec3121c2e0c4bc58f`

## Validation

Gate attempt 1 passed completely; no repair and no attempt 2 were required.

1. `python src/tools/editor/level_blueprint/generate_blueprint_guide.py docs/blueprints/velvet_paw_jazz_club.blueprint.json`
Result: PASS; regenerated `docs/blueprints/velvet_paw_jazz_club.build_guide.md`.

2. `python src/tools/editor/level_blueprint/level_blueprint_validator.py`
Result: PASS; 3 specs, 55 mechanic types, 0 failures, 0 warnings.

3. PowerShell JSON integrity checks against the Phase 1 snapshot
Result: PASS; 36 -> 54 regions, 68 -> 68 slots, mechanic slot data unchanged, nine openings, validator-compatible kinds, all barriers movement-blocking.

4. `git hash-object scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
Result: PASS; `46dfb24634c626bccaa65b6f054120bc4b9cbc86`, exactly matching the Phase 0 baseline.

5. Authorized Godot 4.6.2 headless dev overlay smoke:
`Godot_v4.6.2-stable_win64.exe --headless --path . --quit-after 2 --scene res://scenes/dev/mission_authoring/VelvetPawBlueprintProofRoom.tscn`
Result: PASS, exit 0; blueprint layer and spec loaded without parse or scene-load errors.

6. Authorized Godot 4.6.2 headless production smoke:
`Godot_v4.6.2-stable_win64.exe --headless --path . --quit-after 2 --scene res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
Result: PASS, exit 0; reached `Mission started: velvet_paw_jazz_club` and `Loaded level: VelvetPawJazzClub_Editable`. Known forced-quit CanvasItem/ObjectDB leak and detached-node path noise remained.

7. Focused isolated GdUnit:
`addons/gdUnit4/runtest.cmd --godot_binary <authorized Godot> -rd reports/velvet_paw_collision_phase1 -a res://tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd -a res://tests/mission_authoring/MissionSceneResolverCatalogTest.gd`
Result: PASS, 16/16, 0 errors, 0 failures, 0 skipped, 0 flaky, 0 orphans. XML: `reports/velvet_paw_collision_phase1/report_1/results.xml`.

8. `git diff --check -- docs/blueprints/velvet_paw_jazz_club.blueprint.json docs/blueprints/velvet_paw_jazz_club.build_guide.md`
Result: PASS with only Git's existing CRLF-to-LF working-copy notice for the generated guide.

## Risks And Boundary

- Phase 1 is data-only. It does not paint or enforce runtime collision; that belongs to a later explicitly authorized phase.
- The headless dev smoke proves load/parse behavior, not editor-viewport visual quality. The split region records are directly consumed by the existing overlay and are present in the regenerated trace table.
- Dynamic openings describe intended closed/open behavior but do not alter existing mechanic runtime wiring.
- No rollback was needed. If required, restore only the two Phase 1 source files from the verified checkpoint snapshots.
- Work intentionally stayed as one narrow Phase 1 slice rather than grouped-milestone mode because the user explicitly prohibited continuing to Phase 2.

No stage, commit, push, branch change, history rewrite, or Phase 2 work occurred.
