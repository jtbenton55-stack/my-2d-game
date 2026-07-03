# Phase 15 Reactive NPC / Social Consequence Report

Date: 2026-06-23

## Summary

Implemented Phase 15A-15I as a bounded, reusable reactive NPC/social consequence layer. The implementation stayed in grouped-milestone mode: signal data, attention budgeting, fallback reaction rules, brain/result adapters, authoring nodes, Mission Dock integration, facts/effects/results, templates, proof scene, tests, validator, and roadmap/blueprint updates were handled together.

Production adoption is intentionally gated. No Taco/story mission reactive NPC placement was added, and the runtime has no direct LimboAI dependency. Future LimboAI usage must remain adapter-gated through project-owned glue.

## Files Changed

- Added `src/missions/iso/ai/SocialSignalEvent.gd`.
- Added `src/missions/iso/ai/NpcAttentionBudget.gd`.
- Added `src/missions/iso/ai/SocialReactionRuleSet.gd`.
- Added `src/missions/iso/ai/ReactiveNpcFallbackDriver.gd`.
- Added `src/missions/iso/ai/ReactiveNpcBrainAdapter.gd`.
- Added `src/missions/iso/ai/ReactiveNpcResultAdapter.gd`.
- Added `src/missions/iso/authoring/mechanics/InvestigationPointNode.gd`.
- Added `src/missions/iso/authoring/mechanics/RoutineOverrideNode.gd`.
- Added `src/missions/iso/dev/Phase15ReactiveNpcProofHarness.gd`.
- Added `scenes/dev/mission_authoring/Phase15ReactiveNpcProofRoom.tscn`.
- Added `scenes/missions/iso/authoring/InvestigationPointNodeTemplate.tscn`.
- Added `scenes/missions/iso/authoring/RoutineOverrideNodeTemplate.tscn`.
- Added `tests/mission_authoring/Phase15ReactiveNpcTest.gd`.
- Added `src/tools/editor/phase15_reactive_npc/phase15_reactive_npc_validator.py`.
- Added generated validation output under `docs/reports/phase15_reactive_npc/`.
- Updated `src/missions/iso/authoring/core/MissionEffect.gd` with reactive NPC signal/evaluation/result-tag effects.
- Updated `src/missions/iso/authoring/core/MissionEffectApplier.gd` to route reactive NPC effects through the adapter.
- Updated `src/missions/iso/authoring/core/MissionFactBridge.gd` with reactive signal, reaction, authority-report, and result-tag facts.
- Updated `src/autoload/GameState.gd` to reset reactive adapter state and annotate mission results.
- Updated `src/ui/MissionResult.gd` to display reactive NPC consequence summaries.
- Updated `addons/mission_dock/MissionDock.gd` with Phase 15 node registration, defaults, and audit coverage.
- Updated `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`.
- Updated `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`.
- Updated `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`.

## Validation

- `python src/tools/editor/phase15_reactive_npc/phase15_reactive_npc_validator.py`: PASS, 36 checks.
- Focused GdUnit `tests/mission_authoring/Phase15ReactiveNpcTest.gd`: PASS, 6/6.
- Full GdUnit `tests/mission_authoring`: PASS, 271/271.
- Headless proof-room smoke `res://scenes/dev/mission_authoring/Phase15ReactiveNpcProofRoom.tscn`: PASS by process exit code `0`.
- `git diff --check`: PASS.

## Runtime Notes

- The headless proof-room smoke instantiated the Phase 15 proof scene and relevant resources successfully.
- Godot logged a pre-existing global MCP interaction-server port-bind error on `9090` during headless startup. The process still exited with code `0`; no Phase 15 scene/script load failure was observed.

## Risks / Follow-Ups

- Production adoption remains gated until Jake explicitly requests placement and manually validates the affected production mission flow.
- Reactive NPC behavior is intentionally bounded to authored signals, rule/fallback reactions, mission-local facts/effects, and result summaries. It is not a global NPC simulation, faction system, gossip network, or combat AI rewrite.
- LimboAI remains optional and absent-safe. Do not add direct LimboAI calls from mission mechanics, effects, or production scene scripts; use an injected adapter only when project-owned glue exists.
- The worktree contains unrelated pre-existing report deletions and Phase 10/hideout changes that were not part of Phase 15 and were left untouched.
