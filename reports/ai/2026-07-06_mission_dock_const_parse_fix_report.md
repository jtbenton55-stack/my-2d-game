# Mission Dock Const Parse Fix Report

## Goal

Restore the Mission Dock editor plugin after Godot 4.6.2 failed to parse `MissionDock.gd` with `Assigned value for constant "NODE2D_MECHANIC_TYPES" isn't a constant expression.`

## Files Inspected

- `addons/mission_dock/MissionDock.gd`
- `addons/mission_dock/MissionDockPlugin.gd`
- `addons/mission_dock/plugin.cfg`
- `project.godot`
- `docs/Prompt_Improvement.md`
- `docs/OPENCODE_MILESTONE_A_LEVEL_BUILDER_PARITY_PROMPT.md`
- `reports/ai/2026-07-06_milestone_a_level_builder_parity_report.md`

## Files Changed

- `addons/mission_dock/MissionDock.gd`
- `reports/ai/2026-07-06_mission_dock_const_parse_fix_report.md`

## Fix

Godot rejected this constant because it concatenated arrays from other constants:

`const NODE2D_MECHANIC_TYPES: Array[String] = ["PresentationSequencePlayer"] + SECURITY_AUTHOR_TYPES + COLLECTIBLE_AUTHOR_TYPES`

Replaced `NODE2D_MECHANIC_TYPES` and `MARKER_MECHANIC_TYPES` with explicit array literals. This preserves the same type membership and avoids any runtime/editor behavior change.

## Validation

- `python src\tools\editor\phase2k_mission_dock\phase2k_mission_dock_static_validator.py` PASS.
- `git diff --check -- "addons/mission_dock/MissionDock.gd"` PASS.
- `Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit` PASS; no Mission Dock parse error observed.
- Filtered editor-mode plugin parse check PASS: `Godot_v4.6.2-stable_win64_console.exe --headless --editor --path . --quit` reported `Loading resource: res://addons/mission_dock/MissionDockPlugin.gd`, `Unloading addon: res://addons/mission_dock/plugin.cfg`, `EXIT=0`, with no Mission Dock parse/compile errors.

## Known Noise

- Godot MCP websocket `404 expected 101` messages are unrelated to this Mission Dock parse failure.
- Existing editor/headless noise remains around tile/image imports, placeholder tool-mode calls, MCP socket binding, and forced editor shutdown cleanup.

## Next Manual Step

Restart Godot, confirm **Mission Dock** appears in the right dock tabs, open `MilestoneAProofMission.tscn`, switch to **Mission Assist Browser**, set Severity to `Info` or `All`, and press **Refresh Scene Audit**. The mission registration row should now be visible.
