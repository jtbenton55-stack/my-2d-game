# Nowledge Mem + OpenCode Setup (Windows)

This project uses Windows-native tooling for memory and planning support.

## Required Runtime

1. The Nowledge Mem desktop app must be running on Windows.
2. Use a private/local search index model by default for this project.
3. `nmem status` works in Windows PowerShell/Cursor terminal.
4. OpenCode is installed on Windows for this project, not WSL.

Verified preferred `nmem` path (first on PATH):

`C:\Users\jtben\AppData\Local\Nowledge Mem\cli\nmem.cmd`

## OpenCode Plugin

- Install command:
  `opencode plugin opencode-nowledge-mem -g`
- Current status:
  plugin installed successfully (global scope).
- Validation command:
  `nmem status`

## Open OpenCode from Cursor terminal

```powershell
cd "C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game"
opencode
```

## Role Boundaries

1. OpenCode is planning/review-only.
2. Cursor remains the implementation/debugging agent.
3. Nowledge Mem is for decisions, handoffs, debugging findings, and project memory.
4. Do not save random noise.
5. Do not use Nowledge Mem as a replacement for `AGENTS.md` or repo docs.
6. Coordination happens through `AGENTS.md`, `reports/ai`, Nowledge Mem, and copied prompts.

## What to Save in Nowledge Mem

Save concise, high-value memories for:

- architecture decisions
- debugging root causes
- final fixes
- current branch/project status
- prompt handoffs
- must-not-forget constraints

## WSL Note

WSL OpenCode is not the default for this project because Godot, Cursor, and Nowledge Mem are running on Windows.
