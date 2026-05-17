# AI Dev Runbook

## Setup Overview

This project is configured for near-autonomous AI-assisted development with:
- Godot MCP Pro for broad Godot editor/runtime automation.
- minimal-godot-mcp for MCP-visible diagnostics via Godot LSP/DAP endpoints.
- Godot DAP MCP Server for debugger-specific MCP workflows (pending Go build in this environment).
- GdUnit4 as the intended regression test framework (manual install required).
- OpenCode for planning/review only.
- Nowledge Mem + project docs for memory and handoff continuity.

## Start Godot 4.6.2

1. Launch Godot 4.6.2 executable.
2. Open project at:
   `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game`

## Enable Godot MCP Pro Plugin In Godot

1. Open Godot project.
2. Go to **Project -> Project Settings -> Plugins**.
3. Enable **Godot MCP Pro**.
4. Restart Godot if prompted.

If the plugin is not enabled safely via file edits, use this manual flow instead of editing `project.godot` directly.

## Confirm Godot MCP Pro WebSocket Port 6505

1. Ensure plugin is enabled.
2. Start/refresh the plugin in Godot.
3. Confirm a listener on port `6505` (PowerShell):
   `Test-NetConnection -ComputerName 127.0.0.1 -Port 6505`

## Confirm Godot LSP Port 6005

1. Ensure Godot project is open.
2. Confirm listener:
   `Test-NetConnection -ComputerName 127.0.0.1 -Port 6005`

## Confirm Godot DAP Port 6006

1. Ensure Godot is running with debugger support.
2. Confirm listener:
   `Test-NetConnection -ComputerName 127.0.0.1 -Port 6006`

## Restart Cursor MCP Servers

1. Save `.cursor/mcp.json`.
2. In Cursor, restart MCP servers from the MCP panel.
3. If needed, fully restart Cursor.

## Use Godot MCP Pro (Broad Editor/Runtime Tool)

- Use `godot-mcp-pro` server for scene edits, runtime control, screenshots, and editor automation.
- Configured entrypoint:
  `addons/godot-mcp-pro/server/build/index.js`

## Use minimal-godot-mcp (Diagnostics Only)

- Use `godot-lsp-diagnostics` server for diagnostics and language/debug endpoint visibility.
- Configured through `npx`:
  `@ryanmazzolini/minimal-godot-mcp`

## Use Godot DAP MCP Server (Debugger Only)

- Intended executable path:
  `C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server\godot-dap-mcp-server.exe`
- Current environment is missing `go`, so build is pending.

## Use GdUnit4

1. Install GdUnit4 from official Godot AssetLib or official GdUnit releases.
2. Enable plugin in Godot.
3. Keep test plans in `docs/GDUNIT4_TEST_PLAN.md`.
4. Add tests under `tests/`.

## Use OpenCode For Planning/Review Only

Use OpenCode for:
- planning
- architecture review
- prompt generation
- diff review
- handoff summaries

Do not use OpenCode for direct implementation unless explicitly requested.

## Write AI Run Reports

For each AI-assisted run:
1. Capture intent and scope.
2. Record commands executed.
3. Record changed files.
4. Record verification steps and outcomes.
5. Add unresolved blockers and manual next steps.

Write reports under:
`reports/ai/`
