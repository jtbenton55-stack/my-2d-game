# Cursor / Nowledge / Godot Tooling Instruction Cleanup Report

**Date:** 2026-06-13
**Status:** Repo-side instruction cleanup complete; global/account Cursor files not inspected or modified.

## Goal

Reduce conflicting agent guidance in this repo and make Cursor see the same Nowledge Mem and Godot MCP validation expectations as `AGENTS.md`.

## Changes

- Updated `.cursor/rules/agents-always.mdc` so Cursor receives the Nowledge Mem HTTP API fallback directly from its always-applied repo rule.
- Added explicit Cursor-side Godot validation guidance: use `godot-mcp-pro` for broad editor/runtime control, `godot-lsp-diagnostics` for diagnostics only, and `godot-dap-debugger` for debugger work only.
- Updated `docs/NOWLEDGE_MEM_SETUP.md` to stop treating `nmem` as the required automation path and document the HTTP API workaround.
- Updated `docs/AI_TOOLING_SETUP_STATUS.md` to replace stale `nmem` setup instructions with direct HTTP API validation and endpoints.
- Updated `docs/OPENCODE_PLANNING_PROMPT.md` with the same `nmem CLI not found` fallback rule.

## Decision

The repo root `AGENTS.md` should remain the project source of truth. Cursor's `.cursor/rules/agents-always.mdc` should remain a short always-applied shim that points Cursor to `AGENTS.md` and includes only critical operational fallbacks that Cursor must see immediately.

Duplicate full `AGENTS.md`-style instructions in Cursor account/global/workspace settings should be removed or disabled by Jake outside this repo. This OpenCode session did not inspect or modify those files because the authorized workspace is limited to this repo and approved tool folders.

## Nowledge Mem Rule

If wrapper tools fail with `nmem CLI not found`, do not retry `nmem`. Use `http://127.0.0.1:14242` directly:

- `POST /memories/search`
- `POST /memories`
- `PATCH /memories/{memory_id}`

Use PowerShell `Invoke-RestMethod` and patch an existing related memory if the memory limit blocks new memory creation.

## Validation

- Pending final `git diff --check` after this report is added.
- No scene, resource, plugin runtime, or production gameplay files were intentionally edited by this cleanup.

## Remaining Risks

- Cursor must reload rules/MCP servers to pick up `.cursor/rules/agents-always.mdc` changes.
- Godot MCP Pro runtime validation still depends on Godot being open, the plugin being enabled, one clean MCP Pro server/editor attachment, and the previously diagnosed server-side connection handling fix being active in the tools folder.
- Any duplicate Cursor account/global instruction files outside this repo may still conflict until Jake removes or disables them.
