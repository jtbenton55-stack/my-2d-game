# OpenCode/Cursor Implementation Role Update Report

**Date:** 2026-06-14
**Status:** Complete; validation passed for touched operating docs
**Branch:** `new-feature-roadmap-branch`

## Goal

Update repo-local operating instructions so OpenCode and Cursor are both implementation/debugging agents, while preserving `AGENTS.md` as the highest-priority repo-local source of truth and making `docs/Prompt_Improvement.md` mandatory supplemental context for non-trivial implementation/debugging work.

## Files Changed

- `AGENTS.md`
- `.cursor/rules/agents-always.mdc`
- `docs/Prompt_Improvement.md`
- `docs/NOWLEDGE_MEM_SETUP.md`
- `docs/OPENCODE_PLANNING_PROMPT.md`
- `reports/ai/2026-06-14_opencode_cursor_implementation_role_update_report.md`

## What Changed

- `AGENTS.md` now names both Cursor Ultra Auto and OpenCode as implementation/debugging agents.
- `AGENTS.md` now states that `docs/Prompt_Improvement.md` is mandatory supplemental operating context for Cursor and OpenCode implementation/debugging work.
- `AGENTS.md` explicitly keeps itself above `docs/Prompt_Improvement.md` when the two conflict.
- Cross-agent continuity was strengthened: both tools should search Nowledge Mem, inspect recent `reports/ai/` handoffs before work, and save/update handoffs after implementation/debugging sessions.
- Cursor's always-applied rule now reflects that OpenCode is no longer planning-only and that both systems coordinate through `AGENTS.md`, `docs/Prompt_Improvement.md`, `reports/ai/`, and Nowledge Mem.
- `docs/Prompt_Improvement.md` now covers Cursor or OpenCode implementation/debugging prompts and non-trivial OpenCode implementation/debugging sessions, not only Cursor prompts.
- `docs/NOWLEDGE_MEM_SETUP.md` now describes OpenCode and Cursor as implementation/debugging agents with strict handoff requirements.
- `docs/OPENCODE_PLANNING_PROMPT.md` was rewritten in place as current OpenCode work guidance while preserving the path for compatibility.

## What Was Intentionally Not Changed

- No Phase 2K Mission Dock implementation files were edited.
- No staged GdUnit generated artifacts were edited, unstaged, or committed.
- No QA-modified scene files were edited or reverted.
- No Parmida character animation JSON churn was edited or reverted.
- Historical reports that mention old planning-only roles were not rewritten because they are records of past state.

## Validation

- `git diff --check -- AGENTS.md .cursor/rules/agents-always.mdc docs/Prompt_Improvement.md docs/NOWLEDGE_MEM_SETUP.md docs/OPENCODE_PLANNING_PROMPT.md reports/ai/2026-06-14_opencode_cursor_implementation_role_update_report.md` completed with no whitespace errors.
- Git printed existing line-ending warnings for `AGENTS.md` and `docs/NOWLEDGE_MEM_SETUP.md` (`CRLF will be replaced by LF the next time Git touches it`).
- No Godot runtime validation required; this change is documentation/rule-only.
- No GdUnit4 rerun required; no game/runtime code changed.

## Risks / Follow-Ups

- Some old historical reports still mention OpenCode as planning/review-only; this is expected history, not current policy.
- Future prompts should include the exact `AGENTS.md` source-of-truth instruction now recorded in `docs/Prompt_Improvement.md`.
- Before committing later, review the broader dirty worktree carefully so these operating-doc changes are not mixed with unrelated Phase 2K QA scene changes, staged generated reports, or Parmida JSON churn unless Jake explicitly asks.
