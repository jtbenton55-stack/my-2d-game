# Hideout DialogueBox Deferred Smoke Fix Report

Date: 2026-06-23

## Summary

Fixed the recurring HideoutHub headless smoke blocker where `HideoutManager._ensure_dialogue_box()` could add `DialogueBox` to the scene root while the scene was still setting up children.

The fix is intentionally narrow: `HideoutManager._ready()` now relies on the existing deferred `_ensure_dialogue_box()` call instead of calling it immediately and then again deferred.

## Files Changed

- `src/hideout/HideoutManager.gd`
- `reports/ai/2026-06-23_hideout_dialogue_box_deferred_smoke_fix_report.md`

## Validation

- `git diff --check -- "src/hideout/HideoutManager.gd"`: PASS.
- `python src/tools/editor/phase10_hideout_rewards/phase10_hideout_rewards_validator.py`: PASS.
- Focused GdUnit `res://tests/mission_authoring/Phase10HideoutRewardAdapterTest.gd`: PASS, 6/6.
- Headless HideoutHub smoke `res://scenes/hideout/HideoutHub.tscn`: process exit `0`; previous `_ensure_dialogue_box()` / `add_child` timing error did not reappear.

## Remaining Runtime Noise

- Headless smoke still logs pre-existing unrelated tile atlas/image errors.
- MCP interaction server still logs the known port `9090` bind error when another process owns the port.

## Worktree Notes

- `src/hideout/HideoutManager.gd` already had Phase 10 hideout reward shortcut changes before this fix. This pass only removed the immediate `_ensure_dialogue_box()` call in `_ready()`.
- Focused GdUnit generated untracked `reports/report_70/`.
- Existing unrelated dirty files, report deletions, generated reports, and Phase 15 work were left untouched.

## Grouped-Milestone Mode

This was a narrow debug follow-up, not a new grouped milestone. It supports Phase 10 Hideout QA by clearing the previously reported HideoutHub headless dialogue-box timing blocker.
