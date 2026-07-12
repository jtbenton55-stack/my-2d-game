# Velvet Paw Collision Phase 6 Retry Runtime QA Report

Date: 2026-07-11
Branch: `cursor/cloud-agent-1783263024581-8hmhm`
Commit baseline: `61827fbb2ffc27717e319df2b26ba4319c24c1b1`
Gate attempts used: 1 of 2
Result: PASS; controller fix and Phase 6 QA retained

## Scope And Outcome

Executed only the freshly authorized Phase 6 retry. Corrected the confirmed return-teleport path depth in the Velvet Paw mission-local controller, restored and completed the runtime QA suite, and retained a clean-exit production harness.

No Phase 7, roadmap, implementation blueprint, production scene, collision generator, teleport script, camera script, Taco production file, shared TileSet, project setting, autoload, commit, push, stage, branch, or history operation was changed.

Final changed or added files:

- `src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd`
- `tests/mission_authoring/VelvetPawJazzClubRuntimeQATest.gd`
- `reports/velvet_paw_collision_phase6_retry/production_scene_clean_exit_harness.gd`
- `reports/ai/2026-07-11_velvet_paw_collision_phase6_retry_runtime_qa_report.md`

## Checkpoint

Created and verified before edits:

`reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_06_retry_pre_return_fix/`

| Snapshot | SHA-256 |
| --- | --- |
| `VelvetPawJazzClub_Editable.tscn` | `8711593e9f448845dc2960ff0edb78afa27a4c972100ab1677aedd7e328b3e91` |
| `VelvetPawJazzClubMissionController.gd` | `f5cf9e9e5d40506fd25d53b1e9e97123599360a192bf7c0b69ed3a0c4e78381b` |

`planned_qa_files.txt` records the two planned QA files and report. No existing test file was modified.

## Production Fix

Changed exactly one controller constant:

```gdscript
const RETURN_TELEPORT_PATH := NodePath("../../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02")
```

The controller is at `GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController`. The target is at `GameplayRoot/MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02`, so the controller must ascend from itself to `RuntimeHelpers`, then to `GameplayRoot`, before descending into `MissionMechanics`.

No scene override was added. The controller diff is one addition and one removal. Its final SHA-256 is `f660847759102cf97dbec99ba6e64bc732c9938cfd1f71b1ed3756e74a4423bf`.

Same-depth path audit:

- This controller has no other exported NodePath or controller-local path constant.
- Repository search found no other `../MissionMechanics` constant in the Velvet controller.
- The detached regression resolves the corrected path directly from the in-scene controller to the exact return zone.

## Return Regressions

All three focused return tests passed:

1. Detached structure: controller `return_teleport_path` equals `../../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02` and resolves to the exact scene node while detached.
2. Negative in-tree path: a valid player actor without the shard is rejected by the return teleport; `returned_upstairs_with_shard`, hostile state, return objective completion, and defeat-owner activation all remain false.
3. Positive in-tree path: after setting the legitimate server-vault predecessor and collecting the real shard pickup through `collect()`, the return teleport succeeds and moves the player to `(1024,1120)`; `returned_upstairs_with_shard` and `GameState.velvet_paw_club_hostile` become true; `return_upstairs` completes and `defeat_owner` becomes active.

Both in-tree regression cases used physics/process teardown waits and explicit orphan comparisons. Orphan growth was zero.

## Three Runtime Cycles

Three complete instantiate/start/physics-flush/free cycles passed in one test:

| Cycle | Gameplay floor | Gameplay collision union | Proxy shapes | Dynamic shapes enabled | Generated roots | Route roots | Orphan growth |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 9,996 | 1,996 | 1,420 | 6 | 1 | 1 | 0 |
| 2 | 9,996 | 1,996 | 1,420 | 6 | 1 | 1 | 0 |
| 3 | 9,996 | 1,996 | 1,420 | 6 | 1 | 1 | 0 |

Each cycle also proved:

- Five blocker bodies and six initially enabled shapes.
- No duplicate `GeneratedRuntimeCollision` or `RouteBlockers` roots.
- Identical floor, wall, cover, collision-barrier, and marker source signatures across cycles.
- Fresh badge inventory, hostile state, staff-gate flag, and escape-hatch flag.
- Zero new orphan IDs after complete teardown.

## Critical Route

The complete route passed using a controlled actor in the legitimate `player` group, existing mechanic methods, and only authored predecessor facts/items/objectives:

- Initial staff entrance clear; front crowd rope blocked.
- Staff gate rejected before badge; real badge collection succeeded; both staff shapes disabled after physics flush; unrelated blockers remained closed.
- Backstage hatch rejected before setlist; authored clue facts enabled the real terminal hack; hatch opened and disabled only its blocker.
- Basement teleport requirement and target resolved; player arrived at `(3616,2944)` with a clear 24x24 query.
- Server vault rejected before power; Yordano briefing enabled the real power circuit; vault opened and disabled only its blocker.
- Real shard and basement keycard pickups succeeded.
- Owner stairs remained physically blocked before return.
- Return teleport succeeded to `(1024,1120)` and synchronously set returned/hostile state.
- Owner stairs then opened; the valid south route became clear after physics flush.
- Suite teleport succeeded to `(3616,1216)` with a clear 24x24 query.
- Escape hatch rejected before owner/briefcase and remained physically blocked.
- Real owner challenge and briefcase collection succeeded; escape hatch opened and became physically clear.
- All six dynamic shapes were disabled at route completion.
- `can_extract()` returned `ok=true`, `code=can_extract` after all required objectives.

Every gate was physically blocked before its predecessor and clear after its existing method plus physics/process flush. Every unrelated dynamic blocker remained enabled until its phase.

## World QA

Spawn and target results:

- Runtime/default spawn and authored start marker both resolve to `(256,2880)`.
- Spawn passed a 24x24 collision query.
- Basement target `(3616,2944)` passed a 24x24 query.
- Return target `(1024,1120)` passed after legitimate hatch unlock and physics flush.
- Suite target `(3616,1216)` passed a 24x24 query.

Camera results after runtime synchronization:

- Street point `(256,2880)` is inside the camera limits.
- Club point `(2048,1536)` is inside the camera limits.
- Owner-suite point `(3616,1216)` is inside the camera limits.
- Basement point `(3616,2944)` is inside the camera limits.
- Runtime `AuthoringBlueprintLayer` is absent; the overlay legend is not treated as a gameplay camera requirement.

Patrol results with 24x24 layer-4 collision queries:

- Route 1 waypoint `(640,1472)`: clear.
- Route 1 waypoint `(1088,1664)`: clear.
- Route 1 waypoint `(768,1792)`: clear.
- Route 2 waypoint `(1984,2112)`: clear.
- Route 2 waypoint `(2432,1920)`: clear.
- Route 2 waypoint `(2496,2240)`: clear.

Runtime ArtRoot had zero `CollisionObject2D` descendants and all ArtRoot TileMapLayers remained empty. Pause/restart was not exercised because it is not relevant to the corrected mission-local return signal path.

## Gate Attempt 1

Combined isolated GdUnit:

- PASS `86/86` across `10/10` suites.
- Prior baseline: `80/80` passed.
- New Phase 6 retry suite: `6/6` passed.
- `0` errors, failures, flaky, skipped, orphans.
- Exit code `0`.
- Evidence: `reports/velvet_paw_collision_phase6_retry/attempt_1/report_1/results.xml`.

No repair and no attempt 2 were needed.

Other gates:

- Blueprint validator: PASS, 3 specs, 55 mechanic types, no failures or warnings.
- Clean-exit production harness: PASS; loaded production, verified 1,420 proxy shapes, queue-freed the mission, awaited teardown, printed `clean_quit=1`, and exited 0 without `--quit-after`.
- Velvet production smoke: PASS; reached `Mission started: velvet_paw_jazz_club` and `Loaded level: VelvetPawJazzClub_Editable`, exit 0.
- Taco production smoke: PASS; reached `Mission started: taco_bell_drop` and `Loaded level: TacoBellIso_Editable`; Taco generated 2,380 wall polygons, exit 0.
- No runtime error, parse error, orphan/leak report, or change-attributable warning appeared in the retained smoke/harness logs.
- Standalone CLI runs printed platform controller-mapping `misc2` notices; these are engine/platform input-map notices unrelated to the Phase 6 changes.
- Godot harness script parse check: PASS.
- Structural check: four persisted `tile_map_data` payloads, one generated collision root, one route root, six route-blocker shape nodes.
- Scene bytes equal the retry checkpoint exactly.
- Scene SHA-256 remains `8711593e9f448845dc2960ff0edb78afa27a4c972100ab1677aedd7e328b3e91`.
- Scene Git blob remains `2912248da577f51fceea9f4e69dbde55f3f1ece4`.
- Global `git diff --check`: exit 0 with only the known generated-guide CRLF notice.
- Controller and new QA test whitespace checks: clean.

## Tooling And Boundary

Godot MCP Pro was not exposed in this OpenCode toolset. No screenshot, editor interaction, or input automation is claimed. Evidence came from Godot 4.6.2 CLI, GdUnit4, direct in-tree physics-space queries, exact hashes/bytes, structural text checks, and self-terminating runtime harnesses.

Godot DAP was not needed because no unexplained failure remained after the known path correction.

Work stayed in the explicitly requested narrow Phase 6 retry slice rather than grouped-milestone mode. Phase 7 was not started. No roadmap, commit, push, stage, branch, or history operation occurred.

## Risks

- Automated headless physics and state checks do not replace a human visual playthrough.
- The controller fix is mission-local and deliberately does not alter generic teleport behavior.
- The runtime wall proxy still creates 1,420 polygons; performance risk is unchanged from the passing Phase 5 retry.
- Platform controller-mapping notices remain external CLI noise.
