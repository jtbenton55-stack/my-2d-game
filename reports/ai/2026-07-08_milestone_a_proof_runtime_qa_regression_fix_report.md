# Milestone A Proof Runtime QA Regression Fix

Date: 2026-07-08
Agent: OpenCode

## Scope

Followed up on Jake's manual QA report after the previous Milestone A proof runtime bootstrap fix. This stayed in narrow QA regression-fix mode, not grouped-milestone mode, because the work was limited to regressions in `MilestoneAProofMission.tscn` and shared mechanic/runtime paths that the proof scene now exercises.

## Reported Regressions

- Some mechanic markers disappeared after runtime bootstrap was enabled for the proof scene.
- The authored poop bag could be picked up, but HUD/dev counts stayed at 0.
- Security beam/camera guard spawning worked, but hiding did not protect the player from spawned guards.
- A lower/bottom-left proof teleporter that worked previously no longer worked reliably.

## Changes

- Added debug-build runtime visuals for `MechanicAreaBase` nodes so proof/dev mechanic areas remain readable in play mode, not only in editor `_draw()` previews.
- Changed authored poop bag pickup handling in `IsoMissionBase.gd` so authored poop bags update `GameState.add_poop_bag()` and the `poop_bags_collected` attempt counter immediately when collected, while still keeping authored collectible persistence/menu commit separate.
- Added `mission_hidden` state to `HideSpotNode.gd`; entering a hide spot adds the actor to `mission_hidden`, exiting removes it.
- Updated `Player.gd` so `mission_hidden` prevents damage while the player is hidden.
- Updated `EnemyBase.gd` and `Guard.gd` so hidden targets are not seen, chased, or attacked, including authored `attack_player` guard behavior.
- Made Milestone A proof teleport zones reusable with `one_shot = false` so QA can re-test teleports without a prior activation blocking the route.
- Hardened `TeleportZone.gd` path reporting for off-tree tests/tooling to avoid false `get_path()` errors.
- Extended `MilestoneAThinAuthorablesTest.gd` with regressions for proof teleporter reuse after `route_open`, authored poop bag canonical counts, hide-state protection, and GameState snapshot restoration.

## Validation

- `git diff --check` on targeted files: PASS
- `python "src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py"`: PASS
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`: PASS, 12 tests, 0 errors, 0 failures, report `reports/report_77/results.xml`
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MilestoneAAuthoringRuntimeDegateTest.gd`: PASS, 2 tests, 0 errors, 0 failures, report `reports/report_78/results.xml`
- `& $env:GODOT_BIN --headless --path . --quit-after 1 res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: PASS (`SMOKE_PASS`)

## Known Noise / Risks

- Headless proof-scene smoke still logs the existing shutdown leaked/orphan node warnings; this pass did not investigate those leaks.
- GdUnit still logs the existing remote debugger `127.0.0.1:0` warning.
- Manual QA is still needed to confirm the visual/feel side: markers are readable enough in the live viewport, the top-right HUD increments when pressing E on the authored poop bag, hide spots feel fair against newly spawned guards, and the lower/bottom-left teleporter works through normal player input.
