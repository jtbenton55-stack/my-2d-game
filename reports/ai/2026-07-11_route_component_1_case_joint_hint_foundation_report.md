# Route Component 1 Case the Joint Hint Foundation

Date: 2026-07-11
Operating mode: narrow focused slice, because the user explicitly limited ownership to the shared Case the Joint foundation files and one focused test.

## Goal

Add a minimal reusable, mission-local Case the Joint hint path without a global manager, blocking dialogue, objective mutation, scene edits, or Velvet-specific work.

## Implementation

- `MissionInteractionBridge` is now E-only. Its former `case_the_joint` action export and Q interaction branch were removed.
- A configured bridge prompt target refreshes every `0.20` seconds by default through public `refresh_nearest_prompt()`, and clears when the player has no in-range candidate.
- `Player` preserves its existing highlight pulse and queries only the first `mission_case_hint_provider` after a successful activation.
- `CaseHintDefinition` exposes `RequirementSet`, optional anchor path, maximum distance, priority, text, optional speaker, and cooldown.
- `MissionCaseHintProvider` filters definitions by requirements, anchor distance, and per-definition cooldown; selects highest priority; and resolves ties by authored array order.
- `EventBus.case_hint_requested(text, speaker)` and a three-second runtime-created HUD label provide non-blocking presentation. The Case the Joint path no longer writes `objective_updated`.

The prompt named `src/autoload/EventBus.gd`, but the project's actual EventBus autoload script is `src/utils/EventBus.gd`; that existing source-of-truth file was changed instead. No autoload registration was changed.

## Files Changed

- `src/player/Player.gd`
- `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd`
- `src/utils/EventBus.gd`
- `src/ui/HUD.gd`
- `src/missions/iso/runtime/readability/CaseHintDefinition.gd` and generated `.uid`
- `src/missions/iso/runtime/readability/MissionCaseHintProvider.gd` and generated `.uid`
- `tests/mission_authoring/CaseJointHintProviderTest.gd` and generated `.uid`
- This required AI report

No scene, Velvet controller, roadmap, blueprint, project settings, or unrelated source file was edited. Pre-existing and concurrent worktree changes were preserved.

## Validation

- Focused GdUnit `CaseJointHintProviderTest.gd`: PASS `6/6`, zero errors, failures, skips, flaky tests, or orphans. Evidence: `reports/case_joint_hint_provider/report_4/results.xml`.
- Existing GdUnit `MissionInteractionBridgeTest.gd`: PASS `14/14`, zero errors, failures, skips, flaky tests, or orphans. Evidence: `reports/case_joint_hint_bridge_regression/report_1/results.xml`.
- HUD direct headless scene smoke, `res://scenes/ui/hud.tscn`: PASS, exit `0`; changed HUD script and EventBus signal loaded.
- Headless editor import/parse scan: changed player scene/script, HUD, bridge, EventBus, test, and new readability classes loaded without a related parse error. The scan logged unrelated existing editor/tool-mode errors in Phase0J, mission-objective, challenge/disruption, image, and collision-generator paths.
- `git diff --check`: PASS; only an unrelated existing CRLF warning was printed.
- Godot MCP Pro and DAP were not needed; no unexplained failure remained. No visual screenshot or production mission placement was in scope.

Known runner noise: GdUnit printed the existing MCP port `9090` bind warning, remote debugger port-zero warning, and post-run log-copy warning involving `reports/report_106`; test exit codes and XML results were successful. The tool-pruned tracked `reports/report_86` was restored immediately.

## Risks And Rollback

- No production mission provider has been placed yet, so the generic nearby-point count remains the fallback until a mission authors definitions.
- HUD layout was validated headlessly, not visually across aspect ratios.
- Rollback is limited to the listed shared script changes and deletion of the two new readability scripts/test plus their UIDs.
