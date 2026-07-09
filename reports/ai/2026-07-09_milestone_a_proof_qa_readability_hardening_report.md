# Milestone A Proof QA Readability Hardening

Date: 2026-07-09
Agent: OpenCode

## Scope

Followed up on Jake's manual QA findings for `scenes/dev/mission_authoring/MilestoneAProofMission.tscn`. This stayed in grouped QA-hardening mode: the changes improve observability across the already-authored mechanic chains without adding new global managers or rewriting the proof scene.

## Files Changed

- `src/levels/IsoMissionBase.gd`
- `src/missions/clues/MissionClueBridge.gd`
- `src/missions/ui/MissionPauseDataProvider.gd`
- `src/ui/test_ui/pause_menu.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `src/player/DogCompanion.gd`
- `src/missions/iso/authoring/mechanics/MusicTriggerZone.gd`
- `tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`
- `reports/ai/2026-07-09_milestone_a_proof_qa_readability_hardening_report.md`

## Changes

- Added `IsoMissionBase.get_authored_collectible_attempt_snapshot()` so pause/debug UI can show attempt-only authored collectibles and clues before mission completion.
- Updated `MissionClueBridge` to include `GameState.evidence_clues` in clue snapshots, not only `sterling_clues`.
- Updated `MissionPauseDataProvider.get_clue_snapshot()` to merge persisted clue records with attempt-only authored clue pickups, preventing duplicate clue ids.
- Added `MissionPauseDataProvider.get_inventory_snapshot()` and a new pause-menu `Inventory` panel for mission inventory items.
- Expanded F10 `IsoMissionDebugPanel` with live lines for found clues, mission flags, social stealth, encounter meters/routes/tags, paper trail, reactive NPC, music trigger state, and existing mission inventory/noise state.
- Added successful Bentley bark feedback for keybound bark/fallback bark commands.
- Added `MusicTriggerZone` runtime debug summary, group registration, local AudioStreamPlayer fade-in/fade-out behavior, and restore result tracking.
- Added focused regressions for attempt-visible authored clues and pause inventory snapshots.

## Validation

- `git diff --check` on touched files: PASS.
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`: PASS, 14/14, report `reports/report_80/results.xml`.
- `$env:GODOT_BIN --headless --path . --quit-after 1 res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: PASS, scene loaded and mission started.

## Known Noise / Risks

- Headless/GdUnit still logs the existing MCP port `9090` bind warning when another runtime owns that port.
- Headless proof-scene smoke still logs the previously documented shutdown CanvasItem/ObjectDB leak warnings.
- F10 now exposes live state, but exact manual readability still needs Jake's in-editor/playtest confirmation.
- `AudioManager.play_music()` still records cue keys only; real audible music for `MusicTriggerZone` still depends on local `audio_stream` playback or a future AudioManager expansion.

## Manual QA Checklist

- Pick up an authored clue and open Pause -> Clues; the clue should appear before completing the mission.
- Pick up the inventory-chain item and open Pause -> Inventory; the item/count/category should appear.
- Press F10 and verify flags, clues, mission inventory, social, encounter, paper/reactive, noise, and music lines update while testing locations 1-8.
- Press Bentley key commands `1/2/3/4/F`; bark should now show text feedback like the other commands.
- Enter and leave the music area; F10 should show trigger result/restore result, and local audio streams should fade when configured with `fade_time`.

## Grouped-Milestone Mode

This stayed in grouped QA-hardening mode. It did not fall back to narrower slices because the changes were small adapter/UI/debug extensions over existing systems and passed the focused proof test plus scene smoke.
