# Cursor AGENTS Rule Report

Date: 2026-05-30

## Goal

Add a project-level Cursor rule requiring Cursor to follow `AGENTS.md` before every repo response, prompt, edit, tool call, or implementation step.

## Files Changed

- `.cursor/rules/agents-always.mdc`
- `reports/ai/2026-05-30_cursor_agents_rule_report.md`

## Safety Boundaries

- No gameplay, scene, asset, autoload, or runtime files changed.
- Existing `.cursor/rules/kimi-review.mdc` was preserved unchanged.
- Existing `AGENTS.md` OpenCode role line remains intact.

## Validation

- Verified existing `.cursor/rules/` format uses `.mdc` frontmatter.
- Added the new rule with `alwaysApply: true`.

## Remaining Risk

Cursor must load workspace rules for enforcement. This rule is now present in the repo, but Cursor's behavior still depends on Cursor respecting project rules in the active workspace.
