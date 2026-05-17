# AGENTS.md

You are working in Jake's Godot 4.6.2 project.

Authorized workspace:
C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game

Do not access, modify, delete, rename, move, print, or expose files outside this repo except approved tool folders:
C:\Users\jtben\Documents\PBD 2026\tools

Do not commit, push, stage, change branches, rewrite history, or modify unrelated files unless Jake explicitly asks.

Tool roles:
- Cursor Ultra Auto is the implementation/debugging agent.
- Godot MCP Pro is the only broad Godot editor/runtime-control MCP.
- minimal-godot-mcp is diagnostics-only.
- Godot DAP MCP Server is debugger-only.
- GdUnit4 is the regression test framework.
- OpenCode is planning/review-only.
- Nowledge Mem and project docs preserve decisions and handoffs.

Before changing code:
1. Check git status.
2. Identify files likely to change.
3. Make a short plan.
4. Prefer small reversible edits.
5. Run relevant checks.

After changing code:
1. Run available static/script checks.
2. Run GdUnit4 tests if available.
3. Run the relevant Godot scene if possible.
4. Use MCP tools for screenshots, input, runtime inspection, and debugger inspection where available.
5. Write a report under reports\ai\.
