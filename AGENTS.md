# AGENTS.md

You are working in Jake's Godot 4.6.2 project.

Authorized workspace:
C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game

Do not access, modify, delete, rename, move, print, or expose files outside this repo except approved tool folders:
C:\Users\jtben\Documents\PBD 2026\tools

Do not commit, push, stage, change branches, rewrite history, or modify unrelated files unless Jake explicitly asks.

Tool roles:
- Cursor Ultra Auto is an implementation/debugging agent.
- OpenCode is an implementation/debugging agent.
- Godot MCP Pro is the only broad Godot editor/runtime-control MCP.
- minimal-godot-mcp is diagnostics-only.
- Godot DAP MCP Server is debugger-only.
- GdUnit4 is the regression test framework.
- Nowledge Mem and project docs preserve decisions and handoffs.

Mandatory operating context:
- `AGENTS.md` is the highest-priority repo-local source of truth for workflow, scope, permissions, validation, reporting, and handoff requirements.
- `docs/Prompt_Improvement.md` is mandatory supplemental operating context for Cursor and OpenCode implementation/debugging work.
- If `docs/Prompt_Improvement.md` conflicts with `AGENTS.md`, follow `AGENTS.md` and report the conflict.
- Before non-trivial implementation/debugging work, read `AGENTS.md`, relevant sections of `docs/Prompt_Improvement.md`, current roadmap/blueprint docs, recent `reports\ai\` handoffs, and relevant Nowledge Mem memories.

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

Stage and commit continuity:
- After completing each major game-development stage or phase, such as 2D, 3I, 3K, or similar milestone labels, create or update a status/report file under reports\ai\ or docs\reports\ as appropriate.
- After completing each major game-development stage or phase, update the relevant roadmap and blueprint docs, especially docs\PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md and docs\PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md when the stage changes project direction, implementation status, validation status, risks, or next steps.
- After completing each major game-development stage or phase, save an appropriate Nowledge Mem memory or handoff with the stage label, evidence, files changed, validation results, risks, and recommended next steps.
- After each GitHub commit, save an appropriate Nowledge Mem memory or handoff with the branch, commit hash, commit message, summary of changes, validation evidence, and remaining risks or follow-ups.
- Avoid update loops: include required status/report, roadmap, and blueprint updates before making a stage-completion commit when possible; after the commit, only save the Nowledge Mem entry unless Jake asks for additional file changes.

AI Working Loop:
For non-trivial work:
1. Inspect the existing code and docs before deciding.
2. Make the smallest correct reversible change.
3. Avoid rewrites, broad refactors, and unrelated cleanup.
4. Preserve existing scene paths, node names, exported properties, signals, resources, and saved data unless the task explicitly requires changing them.
5. Validate with the narrowest meaningful checks first.
6. Report what changed, what was tested, and what remains risky.

Accelerated grouped-milestone mode:
- Jake wants faster implementation of the plug-and-play game-system roadmap without cutting roadmap/blueprint objectives.
- Default to larger grouped implementation packets when the requested systems naturally share contracts, files, validation, or authoring flow. This is the preferred "bigger swing" mode unless Jake asks for a narrow fix or the work proves too buggy.
- If a broad grouped packet becomes unstable, fall back to 2-3 tightly related phase slices per prompt until the system stabilizes.
- Use the Phase 6C/6D-lite/6E-lite style as the model: multiple related slices in one milestone, clear phase labels, direct implementation, tests, docs/report, and scene/dev proof where feasible.
- Preserve the architecture while moving faster: prefer adapters and mission-local systems first; allow new managers only when a system clearly needs authoritative state across multiple mechanics, missions, or result screens.
- Inventory, paper trail, and mission rating/result systems may justify dedicated state systems. Suspicion/alert work should extend or wrap `MissionAlertController` before introducing a new global suspicion manager.
- Treat a system as complete only when the milestone accounts for runtime code, Resource/data classes, tests, dev or production scene proof, template scenes where useful, static validators where useful, docs/report, Mission Dock/authoring integration when relevant, and debug/readability support.
- High-risk implementation is acceptable only with guardrails: no broad rewrites, no duplicate managers without justification, no unrelated cleanup, tests for each new fact/effect/mechanic path, scene/headless smoke when feasible, and clear rollback boundaries.
- For bigger swings, require automated tests plus at least one Godot scene/headless smoke when feasible. For production Taco changes, provide a manual QA checklist and prefer Jake's manual confirmation before a grouped milestone commit.
- Commit after grouped milestones when Jake asks. Save or update Nowledge Mem handoffs after each phase packet inside the grouped milestone, including files changed, validation, risks, and next steps.
- Before final response on every non-trivial implementation/debugging prompt, review this section along with roadmap/blueprint status and report whether the work stayed in grouped-milestone mode or fell back to narrower slices.

Engineering Style:
- Prefer simple code over clever code.
- Prefer one clear function over new abstractions unless reuse is obvious.
- Do not add compatibility layers unless there is a concrete need such as shipped data, persisted files, or external consumers.
- Do not mock important gameplay/editor behavior if it can be tested directly.
- Follow existing project patterns instead of inventing new architecture.

Nowledge Mem / cross-agent continuity:
- Cursor and OpenCode should run on Windows for this Godot project.
- Before implementation/debugging work, search Nowledge Mem for the active phase/subsystem and inspect recent `reports\ai\` handoffs so each system can verify exactly what the other did last.
- After implementation/debugging sessions, save or update a concise Nowledge Mem handoff with exact files changed, validation run, risks, and next steps.
- If new memory creation is blocked by a memory limit, update an existing related memory rather than skipping the handoff.
- If Nowledge Mem wrapper tools fail with `nmem CLI not found`, do not retry `nmem`; use the local HTTP API directly at `http://127.0.0.1:14242` (`POST /memories/search`, `POST /memories`, or `PATCH /memories/{memory_id}`) via PowerShell `Invoke-RestMethod`.
- Use `reports\ai\` plus Nowledge Mem so Cursor and OpenCode can verify exactly what the other changed, tested, deferred, or left risky.
