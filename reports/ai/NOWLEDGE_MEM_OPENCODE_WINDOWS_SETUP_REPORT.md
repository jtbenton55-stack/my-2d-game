# NOWLEDGE_MEM_OPENCODE_WINDOWS_SETUP_REPORT

## 1) Date/time

- Date: 2026-05-17
- Local time window: ~17:20-17:40 (UTC-4)

## 2) Branch

- `c2a-full-character-animation-20260509-172230`

## 3) Git status before/after

### Before this setup work

```text
A  .gitattributes
M  .gitignore
?? scenes/testing/
?? scripts/ai/
?? src/autoload/GameState.gd.bisect.bak
?? src/autoload/GameState_McpBisectShim.gd
?? src/autoload/GameState_McpBisectShim.gd.uid
?? src/autoload/GameState_McpBisectStub.gd
?? src/autoload/GameState_McpBisectStub.gd.uid
?? tests/
```

### After this setup work

```text
A  .gitattributes
M  .gitignore
 M AGENTS.md
?? docs/NOWLEDGE_MEM_SETUP.md
?? docs/OPENCODE_PLANNING_PROMPT.md
?? scenes/testing/
?? scripts/ai/
?? src/autoload/GameState.gd.bisect.bak
?? src/autoload/GameState_McpBisectShim.gd
?? src/autoload/GameState_McpBisectShim.gd.uid
?? src/autoload/GameState_McpBisectStub.gd
?? src/autoload/GameState_McpBisectStub.gd.uid
?? tests/
```

## 4) PHASE 1 audit results

### Working directory + project file

- Current directory confirmed:
  `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game`
- `project.godot` exists: `True`

### Windows command availability

- `node --version` -> `v22.22.0`
- `npm --version` -> `9.8.1`
- `npx --version` -> `9.8.1`
- `nmem status` -> failed (`nmem` not recognized)
- `opencode --version` (before install) -> failed (`opencode` not recognized)
- `where.exe nmem` -> not found
- `where.exe opencode` (before install) -> not found

### Required interpretation from audit

- npm/node are available, so OpenCode installation could proceed.
- `nmem` is missing in PATH. Per requested policy, no random package installs were performed.
- Action required by user for nmem:
  - enable/install Nowledge Mem CLI from Nowledge Mem desktop app, or
  - run `pip install nmem-cli`

## 5) OpenCode install/verify (Windows only)

- Install command run:
  `npm install -g opencode-ai`
- Result: success (`added 3 packages in 7s`)

Post-install verification:

- `opencode --version` -> `1.15.4`
- `where.exe opencode` ->
  - `C:\Users\jtben\AppData\Roaming\npm\opencode`
  - `C:\Users\jtben\AppData\Roaming\npm\opencode.cmd`

## 6) OpenCode plugin install (`opencode-nowledge-mem`)

Precondition requested by user was:

- `nmem status` works, and
- `opencode --version` works

Result:

- `opencode` works
- `nmem` does not work (`CommandNotFoundException`)

Therefore plugin install was **not attempted** because prerequisites were not met.

Likely cause:

- Nowledge Mem CLI (`nmem`) not installed or not exposed to PATH in this Windows session.

## 7) PHASE 3 (Nowledge Mem CLI tests/memory seed)

Could not execute due to missing `nmem` command:

- `nmem status` -> command not found
- `nmem m search "Godot AI tooling architecture"` -> command not found

Memory search/add operations were skipped until `nmem` is available.

## 8) Docs created/updated

Created:

- `docs/NOWLEDGE_MEM_SETUP.md`
- `docs/OPENCODE_PLANNING_PROMPT.md`

Updated:

- `AGENTS.md` (added short "Nowledge Mem / OpenCode roles" section; no content removed)

## 9) PHASE 6 validation results

Executed:

- `nmem status` -> failed (`nmem` not recognized)
- `opencode --version` -> `1.15.4`
- `nmem m search "Godot AI tooling architecture"` -> failed (`nmem` not recognized)

Manual plugin validation step ("What was I working on recently?") is pending until:

1. `nmem` works, and
2. `opencode plugin opencode-nowledge-mem -g` succeeds.

## 10) Errors and exact fixes

### Error A: `nmem` command missing

Observed:

```text
nmem : The term 'nmem' is not recognized as the name of a cmdlet...
FullyQualifiedErrorId : CommandNotFoundException
```

Fix:

- Install/enable Nowledge Mem CLI from Nowledge Mem desktop app, or
- `pip install nmem-cli`
- Then restart terminal/Cursor and re-run `nmem status`.

### Error B: `opencode` initially missing

Observed:

```text
opencode : The term 'opencode' is not recognized as the name of a cmdlet...
FullyQualifiedErrorId : CommandNotFoundException
```

Fix performed:

- `npm install -g opencode-ai`
- Verified with `opencode --version` and `where.exe opencode`.

## 11) Manual next steps

1. Enable/install `nmem` on Windows (`Nowledge Mem app CLI` or `pip install nmem-cli`).
2. Reopen terminal and confirm:
   - `nmem status`
   - `where.exe nmem`
3. Install plugin (now that both commands should work):
   - `opencode plugin opencode-nowledge-mem -g`
4. Run memory seed/search commands from requested PHASE 3.
5. In OpenCode, ask:
   - "What was I working on recently?"
   Expected: context comes from Nowledge Mem working memory/search.

## 12) Scope guard confirmation

- No gameplay code was modified.
- No commit/push/stage/branch/history operations were performed in this setup phase.
- No Godot MCP Pro / minimal-godot-mcp / Godot DAP MCP / SiliconFlow Cursor MCP entries were modified.
- Setup was Windows-only (no WSL used).
