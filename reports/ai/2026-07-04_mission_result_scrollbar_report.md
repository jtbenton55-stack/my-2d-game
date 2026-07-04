# 2026-07-04 - Mission Result Scrollbar

## Goal

Add a scrollbar to the mission result screen so long Taco/Phase 17 result summaries can be inspected during manual QA, including the expected garage-route label line.

## Files Changed

- `scenes/ui/MissionResult.tscn`
- `src/ui/MissionResult.gd`
- `reports/ai/2026-07-04_mission_result_scrollbar_report.md`

## Implementation Notes

- Wrapped the existing `ResultLabel` in `Panel/ScrollContainer`.
- Disabled horizontal scrolling and kept the existing label wrapping/alignment.
- Updated `MissionResult.gd` to use the new label path.
- Reset the result scroll position to the top each time result text is rendered.
- Did not change mission result payload generation, route-label text, completion flow, return-to-hideout behavior, Taco scene data, Phase0J/Phase0K scripts, or gameplay interactions.

## Validation

- PASS: `git diff --check`.
- PASS with known startup noise: Godot project load via `Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit`.
- PASS with known startup noise: direct scene smoke for `res://scenes/ui/MissionResult.tscn` via `--headless --path . --scene res://scenes/ui/MissionResult.tscn --quit-after 1`.
- NOT RUN: focused GdUnit Phase 17 suite. The available addon CI runner script at `res://addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd` does not inherit `SceneTree`/`MainLoop` when invoked with `-s`, so the CLI command is not usable from this checkout path. Direct scene smoke covered the node-path/layout change.

## Known Noise

- Godot controller mapping warnings for `misc2`.
- MissionResult theme UID warning falls back to the text path for `res://assets/themes/main_menu_theme.tres`; this existed in the scene load path and did not block loading.
- MCP interaction server startup/shutdown messages.

## Manual QA Step

Re-run the Taco mission result check. On the result screen, use the mouse wheel or visible scrollbar inside the purple result panel to scroll down to `Encounter Challenge:` and confirm the expected `- Route: ...` line.
