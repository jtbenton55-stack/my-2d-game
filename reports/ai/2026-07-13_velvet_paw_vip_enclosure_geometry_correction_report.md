# Velvet Paw VIP Enclosure Geometry Correction

Date: 2026-07-13
Mode: Narrow corrective slice inside the active Velvet Paw grouped milestone
Status: Checkpoint validation passed; later saved-scene drift reopened the right-rail mismatch

## Goal

Replace the obsolete long VIP north rail with the requested 384 x 384 protocol enclosure, make the protocol area fill that square, retain the lower-left prerequisite-controlled gate as the only opening, and orient the VIP camera left with a 180-degree sweep.

## Baseline And Safety

- Branch: `cursor/cloud-agent-1783263024581-8hmhm`.
- The worktree was already heavily modified, including all target scene, blueprint, and test files.
- Existing Component 2 progression, camera countdown, controller, guard, protocol collision-state, phone, and gate changes were preserved.
- No controller/runtime manager, autoload, project setting, TileMap paint, route-blocker body count, or git history was changed.
- No commit, stage, push, branch change, reset, or history operation was performed.

## Changes

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
  - Kept `VipProtocolGateBlocker/GateShape` at `(2624,1696)`, size `(64,192)`.
  - Reused the existing fixed `VipNorthRailBlocker` body to preserve the scene path and nine-body route-blocker contract.
  - Replaced `RailShape` with fixed top, right, bottom, and upper-left shapes around bounds `x=2624..3008`, `y=1408..1792`.
  - Moved the protocol zone to `(2816,1600)` and enlarged both its authored and collision shape sizes to `(384,384)`.
  - Preserved protocol `collision_layer`, disabled startup state, requirements, and controller-owned availability behavior.
  - Kept the VIP camera at `(2624,1600)`, changed direction from `90` to `180` degrees, and changed its sweep arc from `110` to `180` degrees.
- `docs/blueprints/velvet_paw_jazz_club.blueprint.json`
  - Added a fixed-blocker contract for the four enclosure rails.
  - Updated protocol position/size and camera orientation notes.
  - Corrected the stale painted-wall label without changing persisted layout paint.
- `docs/blueprints/velvet_paw_jazz_club.build_guide.md`
  - Regenerated deterministically from the updated blueprint.
- `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd`
  - Updated exact scene geometry and added exact fixed-blocker blueprint assertions.
- `tests/mission_authoring/VelvetPawRouteComponent2Test.gd`
  - Updated protocol, enclosure, and camera authoring assertions.
- `tests/mission_authoring/VelvetPawJazzClubPhysicsTest.gd`
  - Proves the old long rail is absent, all four new fixed boundaries block, the closed gate blocks, the opened gate clears in both directions, and fixed boundaries remain closed after gate opening.

## Validation

- Level blueprint validator: PASS for 3 specs and 55 mechanic types; zero failures or warnings.
- Focused GdUnit run 1: PASS, 34/34 across production skeleton, Component 2, and physical collision suites; zero errors, failures, flaky cases, skips, or orphans.
- XML evidence: `reports/velvet_vip_enclosure_correction/report_1/results.xml`.
- Focused GdUnit run 2: PASS, 24/24 across runtime QA and camera policy suites; zero errors, failures, flaky cases, skips, or orphans.
- XML evidence: `reports/velvet_vip_enclosure_correction/report_2/results.xml`.
- Combined focused result: 58/58 across 5/5 suites.
- Production scene smoke: PASS for 120 headless frames; mission, cameras, guards, and runtime helpers loaded without script or scene errors.
- `git diff --check`: PASS for implementation files, with only the existing generated build-guide CRLF normalization warning.
- Godot LSP was not separately available; all changed GDScript test files parsed and executed in GdUnit.
- Godot DAP was not needed because no unexplained runtime failure or stack trace occurred.
- Godot MCP Pro was not available in this OpenCode session, so editor screenshot and input inspection were not performed.
- Kimi K2.6 was not available or needed for this bounded scene-contract correction.

## Remaining Manual QA

- Open the production scene and confirm the four fixed rails, lower-left gate, full-square protocol overlay, and camera cone align visually with the intended purple guide square.
- Walk the gate and all four fixed edges with a controller to confirm collision feel.
- Confirm the camera's left-facing 180-degree sweep has the intended presentation and does not expose unintended neighboring routes.

## Continuity

This stayed a narrow corrective slice rather than expanding the grouped milestone. The task changed one production geometry contract and its direct automated proof; no broader Component 2 architecture or roadmap direction changed.

## Later Pre-commit Finding

A subsequent combined gate found that the saved production scene no longer matches this checkpoint's right-rail contract. `RightRailShape` is now at `(2992,1600)`, size `(32,384)`, instead of `(3008,1600)`, size `(64,384)`. This produces four assertions across `VelvetPawRouteComponent2Test` and `VelvetPawJazzClubProductionSkeletonTest`; the other 79/81 combined cases pass. The checkpoint evidence above remains accurate for its run, but current Component 2 status requires retesting and rail reconciliation.
