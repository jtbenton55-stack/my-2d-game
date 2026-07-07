# Milestone A Level Builder Parity Report

## Goal

Complete Milestone A as a grouped packet: make new playable iso missions register through one catalog entry, remove Taco-only gates from generic authoring runtime paths, expand Mission Dock placement coverage, add thin player-start/teleport/music authorables, provide proof scenes, and validate without committing.

Grouped-milestone mode stayed active. The work did not fall back to narrower slices.

## Files Inspected

- `AGENTS.md`
- `docs/Prompt_Improvement.md`
- `docs/OPENCODE_MILESTONE_A_LEVEL_BUILDER_PARITY_PROMPT.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-07-05_corner_store_cashout_fable5_audit_report.md`
- `reports/ai/2026-07-04_phase17_level_builder_readiness_report.md`
- `reports/ai/2026-07-04_second_level_readiness_selftest_report.md`
- `src/levels/IsoMissionBase.gd`
- `src/autoload/GameState.gd`
- `src/missions/MissionSceneResolver.gd`
- `addons/mission_dock/MissionDock.gd`
- Mission authoring runtime, authoring, test, scene, and validator peers under `src/missions/iso/`, `tests/mission_authoring/`, `scenes/missions/iso/authoring/`, and `src/tools/editor/`.

## Files Changed

- `src/levels/IsoMissionBase.gd`
- `src/autoload/GameState.gd`
- `src/missions/MissionSceneResolver.gd`
- `src/hideout/HideoutMissionBoardController.gd`
- `src/hideout/HideoutStationCatalog.gd`
- `addons/mission_dock/MissionDock.gd`
- `src/missions/iso/authoring/mechanics/PlayerStartMarker.gd`
- `src/missions/iso/authoring/mechanics/TeleportTargetMarker.gd`
- `src/missions/iso/authoring/mechanics/TeleportZone.gd`
- `src/missions/iso/authoring/mechanics/MusicTriggerZone.gd`
- `scenes/missions/iso/authoring/SearchZoneTemplate.tscn`
- `scenes/missions/iso/authoring/RewardNodeTemplate.tscn`
- `scenes/missions/iso/authoring/ExtractionZoneTemplate.tscn`
- `scenes/missions/iso/authoring/TriggerZoneTemplate.tscn`
- `scenes/missions/iso/authoring/SideObjectiveNodeTemplate.tscn`
- `scenes/missions/iso/authoring/InteractiveContainerTemplate.tscn`
- `scenes/missions/iso/authoring/PlayerStartMarkerTemplate.tscn`
- `scenes/missions/iso/authoring/TeleportTargetMarkerTemplate.tscn`
- `scenes/missions/iso/authoring/TeleportZoneTemplate.tscn`
- `scenes/missions/iso/authoring/MusicTriggerZoneTemplate.tscn`
- `assets/missions/milestone_a_proof_definition.tres`
- `assets/missions/milestone_a_security_smoke_definition.tres`
- `scenes/dev/mission_authoring/MilestoneAProofMission.tscn`
- `scenes/dev/mission_authoring/MilestoneASecuritySmoke.tscn`
- `tests/mission_authoring/MissionSceneResolverCatalogTest.gd`
- `tests/mission_authoring/MilestoneAAuthoringRuntimeDegateTest.gd`
- `tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`
- `src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`
- `src/tools/editor/mission_foundation_d2/phase0md2_static_validator.py`
- `src/tools/editor/d6_03_security_event_guard_patrol_authoring/phase0md6_03_static_validator.py`
- `src/tools/editor/d6_06_collectible_authoring/phase0md6_06_static_validator.py`

Generated validator/GdUnit report artifacts were also updated or created under `docs/reports/` and `reports/report_63` through `reports/report_66` by validation commands.

## A1 Audit Findings

`_setup_d6_03_authoring_security_runtime()`

- Generic authorable logic: `_find_security_authoring_root()`, `runtime_enabled`, `D6_03_MISSION_AUTHORING_BUILDER.setup`, router debug state, guard/effect author binding.
- Taco-specific literals: only the prior mission-id gate. Removed.

`_setup_d6_06_collectible_authoring_runtime()`

- Generic authorable logic: `SecurityAuthoringRoot` collectible authors, runtime-enabled root, `D6_06_COLLECTIBLE_BUILDER.setup`, `d6_06_authoring_root_found` state.
- Taco-specific literals: only the prior mission-id gate. Removed while preserving `false` reporting when no root exists.

`_ensure_d5_attempt_security_beam_runtime()`

- Generic authorable logic: arms existing alarm zones and can invoke authored AMBUSH beam setup when an enabled `SecurityBeamAuthor` exists.
- Taco-specific literals: stale temp-beam cleanup, deferred signal disconnect, canonical fallback AMBUSH repair. Kept Taco-only.

`_setup_fix7_ambush_beam_runtime()`

- Generic authorable logic: hand-placed `SecurityBeamAuthor` path through `find_enabled_beam_author(&"AMBUSH_security_beam")`, author config, runtime alarm area, visual, and D6-03 setup.
- Taco-specific literals: hardcoded fallback rebuild, Taco AMBUSH anchor lookup, hallway/choke geometry. Kept Taco-only.

Other `taco_bell_drop` occurrences were classified as Phase0J/0K/story, layout profile, or explicit Louis-exit fallback design-review logic and left untouched.

## Implementation Choices

- Kept changes minimal and scene-content-driven: generic runtime now keys off authoring roots/authors, not mission ids.
- Added optional `playable_iso_scene` to `GameState.mission_catalog` for Taco, Corner Store, and the dev-only proof mission.
- Preserved `MissionSceneResolver` public API while making playable resolution catalog-driven.
- Added Mission Dock placement entries, parent routing, ID auto-suggest, sticky mouse placement, and Mission Registration audit row.
- Added thin authorables only where requested: `PlayerStartMarker`, `TeleportTargetMarker`, `TeleportZone`, and `MusicTriggerZone`.
- Removed two unused hideout scene constants after the D2 validator exposed they were stale and resolver-routed code was already in use.

## Systems Preserved

- Taco Phase0J/Phase0K bag, code, Louis, story, and fallback systems remain Taco-gated.
- `scene_path` catalog values were not repurposed; `playable_iso_scene` is additive.
- No new autoloads, global managers, or alternate mission manifest system were added.
- Corner Store was only load-smoked; no repair or QA work was performed.
- No commit, staging, branch change, or history operation was performed.

## Validation

Baseline before edits:

- `git status --short --branch`: branch `cursor/cloud-agent-1783263024581-8hmhm...origin/cursor/cloud-agent-1783263024581-8hmhm`; untracked `docs/OPENCODE_MILESTONE_A_LEVEL_BUILDER_PARITY_PROMPT.md`.
- Phase 2K validator: PASS.
- Full `tests/mission_authoring/`: PASS `318/318`.

Post-implementation GdUnit:

- Focused new tests: PASS `11/11`.
- Full `tests/mission_authoring/`: PASS `329/329`, `44/44` suites, `0` errors, `0` failures, report `reports/report_66/results.xml`.

Static validators:

- `src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`: PASS.
- `src/tools/editor/mission_foundation_d2/phase0md2_static_validator.py`: PASS.
- `src/tools/editor/taco_bell_d5_00_runtime_truth/phase0md5_00_static_validator.py`: PASS.
- `src/tools/editor/corner_store_cashout_production_skeleton/corner_store_cashout_production_skeleton_validator.py`: PASS, `79` checks.
- `src/tools/editor/d6_03_security_event_guard_patrol_authoring/phase0md6_03_static_validator.py`: PASS.
- `src/tools/editor/d6_06_collectible_authoring/phase0md6_06_static_validator.py`: PASS.
- `src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py`: PASS with warning `SecurityAuthoringRoot runtime_enabled not explicit in scene text`.
- `src/tools/editor/phase17_level_builder_readiness/phase17_level_builder_readiness_validator.py`: PASS, `53` checks.
- `src/tools/editor/phase3k_scene_asset_browser/phase3k_scene_asset_browser_static_validator.py`: PASS.
- `src/tools/editor/d6_07_broader_interactable_authoring/phase0md6_07_static_validator.py`: PASS.
- `src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py`: PASS.

Not counted as a Milestone A failure:

- `src/tools/editor/taco_bell_redesign_d4/phase0md4_static_validator.py` failed its scope guard because the current worktree intentionally contains non-D4 changes. This validator is a D4 pass guard, not a behavioral regression check for this packet.

Headless scene smokes using `Godot_v4.6.2-stable_win64_console.exe --quiet --headless --quit-after 1`:

- `res://scenes/MainMenu.tscn`: `SMOKE_PASS`.
- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`: `SMOKE_PASS`.
- `res://scenes/missions_iso/CornerStoreCashout_Editable.tscn`: `SMOKE_PASS`.
- `res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: `SMOKE_PASS`.
- `res://scenes/dev/mission_authoring/MilestoneASecuritySmoke.tscn`: `SMOKE_PASS`.

LSP/MCP/DAP status:

- Godot-specific LSP diagnostics tool was not available in this OpenCode toolset. GdUnit and headless Godot scene loads compiled/loaded the modified and created scripts.
- Godot MCP Pro editor/runtime tools and screenshot tools were not available in this OpenCode toolset. Editor dock smoke and screenshot evidence are therefore blocked here; manual steps are provided below.
- DAP was not needed because tests and smokes did not expose a debugger-only failure.
- Kimi K2.6 advisory MCP was not available in this OpenCode toolset.

Known validation noise:

- Forced `--quit-after` scene smokes emit shutdown leak/orphan messages from Godot after successful exit. The exit-code marker was still `SMOKE_PASS`.
- Corner Store load emits pre-existing TileSet/empty-image warnings. Corner Store was intentionally not repaired or QA'd per scope.

## Rollback Plan

- A1 runtime de-gating: revert only `src/levels/IsoMissionBase.gd` changes and `MilestoneAAuthoringRuntimeDegateTest.gd`.
- A2 catalog resolver: revert `GameState.gd`, `MissionSceneResolver.gd`, the hideout unused-constant cleanup if desired, and `MissionSceneResolverCatalogTest.gd`.
- A3 dock palette/thin authorables/templates: revert Mission Dock changes, new authorable scripts, template scenes, and `MilestoneAThinAuthorablesTest.gd`.
- A4 placement QoL: revert the Mission Dock ID-suggestion/sticky-placement sections.
- A5 proof/validation: remove the two Milestone A dev scenes/resources and this report; generated `reports/report_*` outputs can be discarded.

## Known Limitations

- Editor dock smoke still needs Jake or an agent with Godot MCP Pro editor control to confirm UI placement, sticky arming, and the Assist Browser row in the live editor.
- Non-Taco security smoke was validated by headless load and GdUnit runtime assertions; interactive beam/camera trip screenshots were not possible without editor/runtime MCP control.
- `reports/report_43` through `reports/report_46` showed generated report deletion noise in the existing worktree; they were not restored or modified intentionally.

## Recommended Next Step

Jake should run the manual Milestone A proof session below. If it passes, proceed to Milestone B authoring slices: editor gizmos, prompt unification, graph audit rules, and fact/ID pickers.

## Manual QA Checklist

Milestone A manual session (~30–45 min):
1. Open MilestoneAProofMission in the editor. Assist Browser "Mission registration" row is green.
2. Paint a floor, walls, and a collision barrier with the Mission Paint Dock.
3. From the Mission Dock place: PlayerStartMarker, ExtractionZone, one SearchZone -> RewardNode -> RouteUnlockNode chain, a SchemeCardTriggerNode, a HideSpotNode, a TeleportZone + target, a MusicTriggerZone, one collectible author, and (security) one camera, one beam, one guard spawn + patrol route. Confirm sticky placement and auto-suggested mechanic_ids.
4. Audit tab shows no CHANGE_ME ids and no parenting errors.
5. Press play from the mission board/dev launch. Verify: spawn at marker; music changes in zone; beam/camera trip raises alert; guard patrols the route; collectible collects; teleport moves the player; extraction completes the mission and returns to hideout.
6. Launch Taco and play the canonical route for 5 minutes. Nothing regressed.
