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

AI Working Loop:
For non-trivial work:
1. Inspect the existing code and docs before deciding.
2. Make the smallest correct reversible change.
3. Avoid rewrites, broad refactors, and unrelated cleanup.
4. Preserve existing scene paths, node names, exported properties, signals, resources, and saved data unless the task explicitly requires changing them.
5. Validate with the narrowest meaningful checks first.
6. Report what changed, what was tested, and what remains risky.

Engineering Style:
- Prefer simple code over clever code.
- Prefer one clear function over new abstractions unless reuse is obvious.
- Do not add compatibility layers unless there is a concrete need such as shipped data, persisted files, or external consumers.
- Do not mock important gameplay/editor behavior if it can be tested directly.
- Follow existing project patterns instead of inventing new architecture.

Nowledge Mem / OpenCode roles:
- OpenCode is planning/review-only unless Jake explicitly asks otherwise.
- OpenCode should run on Windows for this Godot project.
- Before major planning, OpenCode should read Nowledge Working Memory and search for relevant memories.
- After major planning/debugging sessions, save a concise handoff to Nowledge Mem.
- Cursor remains the implementation/debugging agent.
