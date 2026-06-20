# Phase 4E-4G-Lite Security Readability Report

**Date:** 2026-06-17
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; automated validation passed; manual Taco QA passed 2026-06-20

## Goal

Continue Phase 4 in grouped-milestone mode with a lite, reversible packet: make camera sweeps more inspectable, add a reusable hide/safe spot mechanic through the existing alert controller, and prove one production Taco security event can drive a normal `EffectSet` without Taco script hardcoding.

## Files Changed

- `src/missions/iso/runtime/MissionSecurityCamera.gd`
- `src/missions/iso/runtime/MissionQAChecklistPanel.gd`
- `src/missions/iso/authoring/SecurityCameraAuthor.gd`
- `src/missions/iso/authoring/mechanics/HideSpotNode.gd`
- `scenes/missions/iso/authoring/HideSpotNodeTemplate.tscn`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `tests/mission_authoring/SecurityReadabilityLiteTest.gd`
- `src/tools/editor/phase4e_4g_security_readability/phase4e_4g_security_readability_validator.py`
- `docs/reports/phase4e_4g_security_readability/phase4e_4g_security_readability_validator_run.json`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/SECURITY_AUTHORABLES_GUIDE.md`
- `reports/ai/2026-06-17_phase4e_4g_security_readability_lite_report.md`

## Implementation Summary

- Phase 4E-lite: `MissionSecurityCamera` exposes `get_sweep_debug_state()`, `get_sweep_loop_seconds()`, and `get_sweep_readability_line()`. `SecurityCameraAuthor` exports `sweep_readability_label` and includes it in runtime config.
- Phase 4F-lite: added `HideSpotNode`, a reusable `MechanicAreaBase` node that reduces detection via `MissionAlertController.set_detection_modifier()` and optionally decays exposure when entered. Exiting resets the modifier.
- Phase 4G-lite: added Taco `Phase4G_CameraAlarmEffectSet_Author`, which listens to the existing `test_camera_alarm` event and sets `phase4g_camera_alarm_seen` through `SecurityEffectSetAuthor` and `EffectSet`.
- Follow-up validation fixes: corrected a bad indent in `MissionSecurityCamera.apply_authoring_config()` and made `SecurityCameraAuthor.build_runtime_config()` avoid `get_path()` when the author node is not inside a scene tree.
- Manual QA readability follow-up: added `MissionQAChecklistPanel` and wired it to F12 from `IsoMissionDebugPanel`. The panel has a dropdown for Overview, Phase 4E, Phase 4G, Phase 4F, and Taco Security Regression, with exact paths, next actions, live PASS/WAIT checks, and Phase 4G teleport/reset buttons. F12 intentionally avoids Godot Editor's F8 stop-running shortcut.
- 2026-06-19 QA panel compile follow-up: changed the Phase 4G mission flag key to a literal GDScript constant and made `IsoMissionDebugPanel` instantiate the QA panel through the existing preload without statically depending on the new `class_name`, so both focused tests and production Taco scene load parse the panel reliably.
- 2026-06-20 manual QA crash follow-up: Jake confirmed pressing F8 closed the Godot playtest window. Root cause was a hotkey conflict with Godot Editor's built-in Stop Running Project shortcut, not the QA checklist logic. The QA Review toggle is now F12 and the focused test suite asserts it does not use `KEY_F8`.

## Protected Scope

- No new global suspicion manager or alert autoload was added.
- No camera detection thresholds, guard spawn behavior, or existing Taco script logic was changed.
- The Taco production addition is one authoring node plus local scene Resource data; it uses the existing event-router/effect bridge.

## Validation

- PASS: `python src/tools/editor/phase4e_4g_security_readability/phase4e_4g_security_readability_validator.py`
- PASS: direct Godot parse check for `res://src/missions/iso/runtime/MissionSecurityCamera.gd`
- PASS: focused GdUnit `res://tests/mission_authoring/SecurityReadabilityLiteTest.gd` (`4/4`)
- PASS: focused GdUnit `res://tests/mission_authoring/SecurityReadabilityLiteTest.gd` after QA panel follow-up (`6/6`), including Phase 4G PASS/WAIT QA model rendering checks.
- PASS: focused GdUnit `res://tests/mission_authoring/SecurityReadabilityLiteTest.gd` after F12 hotkey conflict fix (`7/7`), including the regression check that QA Review uses `KEY_F12` and not `KEY_F8`.
- PASS: full GdUnit `res://tests/mission_authoring` (`182/182`)
- PASS with shutdown warnings: headless Taco scene load smoke via `Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"`. The scene loaded, mission startup completed, and Phase0J/authoring/security resources loaded. The 2026-06-19 rerun confirmed no `IsoMissionDebugPanel` / `MissionQAChecklistPanel` parse errors remain. Godot still emits the known shutdown leak/get_path warnings on exit; the relevant in-editor manual QA passed on 2026-06-20.
- PASS: `git diff --check` for Phase 4E-4G QA panel follow-up files.
- PASS: manual in-editor Taco QA by Jake on 2026-06-20. Initial Phase 4G checklist showed WAIT states before entering the camera cone; after standing in the cone, every live check switched to PASS. Screenshot evidence showed camera alarm fired, router handled the alarm, guard listener reacted, EffectSet applied `effectset_phase4g_camera_alarm_seen` with `applied 1 failed 0`, and `Flag set: yes`.

## Manual QA Checklist Before Milestone Commit

Completed by Jake on 2026-06-20.

1. Launch Taco production scene.
2. Press F12 and select `Phase 4G - Camera Alarm EffectSet`.
3. Use the panel's paths/PASS-WAIT checklist and optional Teleport button to enter the authored camera cone.
4. Confirm the checklist reaches PASS for runtime camera, alarm fired, router handled, guard listener reacted, EffectSet applied, and `mission_flag:taco_bell_drop:phase4g_camera_alarm_seen` set.
5. Press F10/F9 only if raw diagnostic fallback is needed.
6. Confirm no new red errors appear in Godot output.

## Risks / Follow-Ups

- Production Taco manual QA passed on 2026-06-20; continue to recheck this flow after future security or debug-HUD changes.
- Hide spots are mechanically testable but have no final art, animation, or tutorial prompt pass.
- Camera sweep readability is debug/author-facing only; no new player-facing HUD was added.
