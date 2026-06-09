# Agent Stage/Commit Continuity Rule Report

Date: 2026-06-09

## Goal

Add persistent agent instructions requiring project continuity updates after major game-development stages and after GitHub commits.

## Files Changed

- `AGENTS.md`
- `.cursor/rules/agents-always.mdc`
- `reports/ai/2026-06-09_agent_stage_commit_continuity_rule_report.md`

## What Changed

- Added a `Stage and commit continuity` section to `AGENTS.md`.
- Required status/report updates after major stage labels such as `2D`, `3I`, `3K`, or similar milestones.
- Required roadmap/blueprint updates when stage completion changes project direction, implementation status, validation status, risks, or next steps.
- Required Nowledge Mem memories or handoffs after major stage completion and after each GitHub commit.
- Added an update-loop guard: include stage-completion reports/docs before the stage-completion commit when possible; after the commit, save Nowledge Mem only unless Jake asks for more file changes.
- Mirrored the same continuity requirement in Cursor's always-applied rule file so Cursor sees the requirement explicitly.

## Validation

- `git diff --check -- AGENTS.md .cursor/rules/agents-always.mdc` completed with no whitespace errors.
- Git printed a line-ending warning for `AGENTS.md`: `CRLF will be replaced by LF the next time Git touches it`.
- No Godot runtime, GdUnit4, or scene validation was run because this was documentation/instruction-only.

## Safety Notes

- No commits, staging, pushes, branch changes, scene edits, gameplay edits, or config secrets were involved.
- Existing unrelated dirty/untracked Phase 3K work was not modified.
