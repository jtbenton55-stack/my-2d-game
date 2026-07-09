# Milestone A Proof Runtime QA Follow-Up

Date: 2026-07-08
Agent: OpenCode

## Scope

Followed up on Jake's manual QA notes for `MilestoneAProofMission.tscn` after bridge/spawn fixes. This stayed in narrow QA-fix mode, not grouped-milestone mode, because the work was limited to making the existing scene-authored proof mission boot its already-authored runtime systems and validating the specific broken interactions.

## Root Cause

`MilestoneAProofMission.tscn` uses a `mission_definition` but has `auto_generate_from_definition = false`. `IsoMissionBase._ready()` only called runtime setup and camera bound generation from the generated-definition path, so scene-authored proof content could load without bootstrapping security, collectible/runtime helpers, and expanded camera bounds.

## Changes

- Updated `src/levels/IsoMissionBase.gd` so scene-authored missions with a definition and `auto_generate_from_definition = false` still synchronize authored gameplay layers, set up runtime systems, apply D5 security beam runtime support, and recompute camera bounds.
- Added camera bound helpers in `IsoMissionBase.gd` so bounds can include authored tile layers and authored Node2D descendants such as teleport targets, preventing lower-map teleports from clamping the camera to the old static range.
- Hardened tile-bound helpers in `IsoMissionBase.gd` against missing tile sets.
- Updated `scenes/dev/mission_authoring/MilestoneAProofMission.tscn` so security authoring is runtime-enabled, the proof security camera sweeps, and the inventory chain is self-contained for inventory pickup -> object swap -> bug plant -> dead drop retrieval.
- Updated `src/missions/iso/authoring/SecurityAuthoringRoot.gd` to use `str(...)` instead of direct `String(...)` conversion for StringName/runtime values that can error under Godot 4.6.
- Extended `tests/mission_authoring/MilestoneAThinAuthorablesTest.gd` with regression coverage for proof-scene security runtime flags, camera sweep authoring, camera bounds covering authored teleport targets, and the self-contained inventory chain.

## Validation

- `git diff --check -- "src/levels/IsoMissionBase.gd" "src/missions/iso/authoring/SecurityAuthoringRoot.gd" "scenes/dev/mission_authoring/MilestoneAProofMission.tscn" "tests/mission_authoring/MilestoneAThinAuthorablesTest.gd"`: PASS
- `python "src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py"`: PASS
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`: PASS, 9 tests, 0 failures, report `reports/report_74/results.xml`
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MilestoneAAuthoringRuntimeDegateTest.gd`: PASS, 2 tests, 0 failures, report `reports/report_75/results.xml`
- `& $env:GODOT_BIN --headless --path . --quit-after 1 res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: PASS (`SMOKE_PASS`)

## Known Noise / Risks

- Headless/GdUnit runs still log the existing MCP port `9090` bind failure when another runtime owns that port.
- The proof-scene headless smoke exits 0 but still logs existing leaked/orphan node warnings on shutdown; this pass did not investigate those leaks.
- Manual gameplay confirmation is still recommended for the security beam alarm, sweeping camera alarm, camera following after teleport, collectible visibility, and the full interaction chain because automated tests validate authoring/runtime setup contracts rather than full player-input QA.
