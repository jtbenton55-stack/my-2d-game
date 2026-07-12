# Velvet Paw Collision Phase 4 Dynamic Blockers Report

Date: 2026-07-11
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 2 of 2
Result: PASS; Phase 4 applied

## Scope

Executed only Phase 4 dynamic route blockers. Added mission-local static collision shapes and wired them to the five existing Velvet Paw mechanics through their existing exported collision arrays. No shared mechanic script, roadmap, implementation blueprint, Phase 5 system, `project.godot`, autoload, commit, push, branch, or history operation was changed.

## Checkpoint

Created and verified before edits:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_04_pre_dynamic_blockers/`

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` | 277,754 | `3505da8385648c4bc02f6c51b4f6336c5b1515153265a467bc51fa0ed74a0ea2` |
| `docs/blueprints/velvet_paw_jazz_club.blueprint.json` | 39,392 | `c2ac059bfd98e476f056fc3ea34250b13721497d4e1863bc81bdb3c8d206e3f9` |
| `docs/blueprints/velvet_paw_jazz_club.build_guide.md` | 38,473 | `af7eb7386a46368489c0760c1f1b73f2112321b26c06c18ec3121c2e0c4bc58f` |
| `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` | 18,263 | `582021d1221aaa4cfcfe33d3d2bb84b19048ff04fbb4779c687c9a05a79a0f5a` |

The recorded pre-Phase-4 production Git blob was `7ea65f62045208be4c9b9911fdcd439735bc7e52`. All four checkpoint snapshots were re-hashed after the gate and remained exact.

## Blueprint Contract

Added `collision_contract.dynamic_blockers` with five blocker IDs, exact mechanic slots, and six rectangle shapes:

| Blocker | Mechanic slot | Shape | Center | Size |
| --- | --- | --- | --- | --- |
| `StaffGateBlocker` | `staff_gate` | `StageRowShape` | `[2048, 1056]` | `[256, 64]` |
| `StaffGateBlocker` | `staff_gate` | `StageWingShape` | `[2080, 928]` | `[64, 192]` |
| `BackstageHatchBlocker` | `backstage_hatch` | `HatchShape` | `[1024, 1056]` | `[256, 64]` |
| `ServerVaultBlocker` | `server_vault` | `VaultShape` | `[3936, 2144]` | `[192, 64]` |
| `OwnerStairsBlocker` | `owner_stairs` | `PortalPadShape` | `[3008, 1152]` | `[192, 64]` |
| `EscapeHatchBlocker` | `escape_route` | `HatchLidShape` | `[4224, 2688]` | `[96, 128]` |

The escape record states that extraction requirements remain authoritative and that the blocker is the closed hatch interaction, not an opening into void.

The guide generator was run. Its output does not render `collision_contract`, so the guide remained byte-identical at SHA-256 `af7eb7386a46368489c0760c1f1b73f2112321b26c06c18ec3121c2e0c4bc58f`.

## Production Scene

Added `GameplayRoot/RouteBlockers`, five `StaticBody2D` children, and six `CollisionShape2D` children. Every body uses `collision_layer = 4` and `collision_mask = 0`; every shape starts enabled.

Exact shape paths:

- `GameplayRoot/RouteBlockers/StaffGateBlocker/StageRowShape`
- `GameplayRoot/RouteBlockers/StaffGateBlocker/StageWingShape`
- `GameplayRoot/RouteBlockers/BackstageHatchBlocker/HatchShape`
- `GameplayRoot/RouteBlockers/ServerVaultBlocker/VaultShape`
- `GameplayRoot/RouteBlockers/OwnerStairsBlocker/PortalPadShape`
- `GameplayRoot/RouteBlockers/EscapeHatchBlocker/HatchLidShape`

Exact mechanic wiring, relative from each mechanic under `GameplayRoot/MissionMechanics`:

- Staff `collisions_to_disable_on_unlock`: `../../RouteBlockers/StaffGateBlocker/StageRowShape`, `../../RouteBlockers/StaffGateBlocker/StageWingShape`
- Backstage `collisions_to_disable`: `../../RouteBlockers/BackstageHatchBlocker/HatchShape`
- Server `collisions_to_disable_on_unlock`: `../../RouteBlockers/ServerVaultBlocker/VaultShape`
- Owner `collisions_to_disable_on_unlock`: `../../RouteBlockers/OwnerStairsBlocker/PortalPadShape`
- Escape `collisions_to_disable`: `../../RouteBlockers/EscapeHatchBlocker/HatchLidShape`

The six paths resolve both while the scene is detached and after it enters the tree. Existing `LockedInteractionNode` and `RouteUnlockNode` behavior disables the configured shapes only after requirements succeed. No shared script change was necessary.

## Structural Integrity

Scene comparison against the Phase 4 checkpoint passed the whitelist:

- Additions only; zero removed or rewritten baseline lines.
- Six new `RectangleShape2D` subresources.
- One `Node2D`, five `StaticBody2D`, and six `CollisionShape2D` nodes.
- Five existing mechanic property additions for collision wiring.
- Four pre-existing `tile_map_data` lines before/after: 4 / 4, exact string equality.
- Permanent counts unchanged: floor 9,996; wall 1,420; collision barrier 446; solid cover 132; marker 0.
- Permanent blocking union unchanged at 1,996 cells; source signatures remain unchanged before and after forward synchronization.
- Blueprint mechanic slots before/after: 68 / 68, exact JSON data equality.
- No production `PackedScene.pack` or editor scene save was used.

Final hashes:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| Production scene | 280,880 | `5512dfbb3856e505cff6f61b5d68acec9707a80cb317f137b4279854c99ef440` |
| Blueprint | 40,842 | `6b71ea41d5768c78f10ceedb279e2695d36f950132987765dbc9d6a5a3fff982` |
| Generated guide | 38,473 | `af7eb7386a46368489c0760c1f1b73f2112321b26c06c18ec3121c2e0c4bc58f` |
| Velvet production test | 25,575 | `1332a1ecf103c8e67c1745ef5583d04cfb31f59c482786d932146dd0f4b70b1d` |

Final production scene Git blob: `0e0707a6e88c682c400c5c6c884af26cc9127cf2`.

## Tests

Focused Phase 4 additions to `VelvetPawJazzClubProductionSkeletonTest.gd` prove:

- Exact blueprint blocker IDs, mechanic slots, shape IDs, centers, sizes, and escape note.
- Exact scene hierarchy, body layer/mask, shape center/size, and initial enabled state.
- All six configured paths resolve detached and in-tree.
- Failed requirements leave all blockers enabled.
- Successful unlock disables only the intended shape or pair and sets the existing mission flag.
- Unrelated blockers remain enabled.
- Repeated unlock returns `already_unlocked` and is safe.
- A fresh scene restores all blockers enabled.
- Basement and suite teleports remain requirement-gated.
- Extraction remains flag/objective-gated.
- Permanent tile counts/signatures, 68/68 blueprint coverage, and Phase 3A lifecycle behavior remain intact.

Combined isolated GdUnit suites:

- `TileDataPromotionHelperTest.gd`
- `LevelBlueprintLayoutPainterTest.gd`
- `VelvetPawJazzClubProductionSkeletonTest.gd`
- `MissionSceneResolverCatalogTest.gd`
- `IsoMissionBaseLifecycleTest.gd`
- `MilestoneAAuthoringRuntimeDegateTest.gd`
- `MilestoneAThinAuthorablesTest.gd`
- `PhaseD501AttemptResetContractTest.gd`

Attempt 1: FAIL, 59 cases reached, 0 errors, 5 assertion failures, 0 orphans. The only failure was int-versus-float comparison in the new JSON geometry assertion; Godot JSON numbers are floats. Evidence: `reports/velvet_paw_collision_phase4/report_1/results.xml`.

Allowed narrow repair: changed only the new test's expected JSON numbers from ints to floats. No scene, blueprint, guide, or production script changed.

Attempt 2: PASS, 70/70 across 8/8 suites, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans. Velvet suite: 18/18. Evidence: `reports/velvet_paw_collision_phase4/report_2/results.xml`.

The initial batch invocation pointed at the containing Godot directory rather than its executable and started no Godot process or test case; it was corrected before Attempt 1 and did not consume a gate attempt.

## Other Validation

- Guide regeneration: PASS; output hash unchanged.
- Blueprint validator: PASS; 3 specs, 55 mechanic types, 0 failures, 0 warnings.
- Velvet scene load/smoke: reached `Mission started: velvet_paw_jazz_club` and `Loaded level: VelvetPawJazzClub_Editable`.
- Taco smoke: reached `Mission started: taco_bell_drop` and `Loaded level: TacoBellIso_Editable`; pre-existing invalid-UID text-path fallback warning only.
- The two smokes were launched concurrently. Velvet logged an MCP port 9090 bind conflict because Taco acquired the optional debug port first; mission scene loading and gameplay initialization still completed.
- Structural diff whitelist: PASS.
- Checkpoint verification: PASS, 4/4 snapshots.
- `git diff --check`: PASS except the pre-existing generated-guide CRLF warning.
- Godot DAP was not needed because no unexplained runtime failure remained.

## Boundary And Rollback

Work stayed in one narrow Phase 4 slice rather than grouped-milestone mode because the user explicitly prohibited Phase 5. Phase 3B tile payloads remain byte-identical. No roadmap was edited.

Rollback is the verified `phase_04_pre_dynamic_blockers` snapshots for the four checkpointed files. No rollback was needed. No commit, push, stage, branch change, or history operation occurred.
