# AI Tooling Setup Report

## 1) Date/Time
- 2026-05-16 17:40 (local)

## 2) Current Branch
- c2a-full-character-animation-20260509-172230

## 3) Git Status Before/After
- Before (audit snapshot): clean (`git status --short` returned no entries).
- After: modified/created setup files only for tooling, docs, scripts, and Godot MCP Pro normalization.

## 4) Required PATH Checks
- node: available (`v22.22.0` from shell probe)
- npm: available (`9.8.1`)
- npx: available (`9.8.1`)
- git: available (`2.53.0.windows.2`)
- go: missing from PATH

## 5) Optional PATH Checks
- opencode: missing from PATH
- nmem: missing from PATH
- godot: missing from PATH
- cursor: available (`3.4.20`)

## 6) Godot MCP Pro Detection Results
- Addon path found:
  - `addons/godot-mcp-pro/addons/godot_mcp/`
- Server path found:
  - `addons/godot-mcp-pro/server/`
- Server package detected:
  - `addons/godot-mcp-pro/server/package.json`
- Build result:
  - `npm install` and `npm run build` completed
  - Entrypoint confirmed: `addons/godot-mcp-pro/server/build/index.js`
- Configured MCP entry: yes (`godot-mcp-pro` in `.cursor/mcp.json`)

## 7) minimal-godot-mcp Configuration Result
- Configured in `.cursor/mcp.json` as:
  - server name: `godot-lsp-diagnostics`
  - command: `npx`
  - args: `-y @ryanmazzolini/minimal-godot-mcp`
  - env: `GODOT_WORKSPACE_PATH`, `GODOT_LSP_PORT=6005`, `GODOT_DAP_PORT=6006`, `GODOT_DAP_BUFFER_SIZE=1000`

## 8) Godot DAP MCP Server Clone/Build Result
- Official repo cloned to:
  - `C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server`
- Build status:
  - skipped due to missing Go in PATH
- Executable status:
  - `godot-dap-mcp-server.exe` not present
- `godot-dap-debugger` MCP entry in `.cursor/mcp.json`:
  - omitted for now because executable is missing

## 9) GdUnit4 Install Result
- Existing folders checked:
  - `addons/gdUnit4`: missing
  - `addons/gdUnit4Net`: missing
- Automatic install not performed (no official asset fetch done automatically).
- Manual TODO provided in `docs/AI_TOOLING_SETUP_STATUS.md` and runbook.

## 10) OpenCode / Nowledge Mem Result
- `opencode` missing from PATH
- `nmem` missing from PATH
- Plugin install command not executed due to missing commands
- `opencode.json` created for planning/review-only policy
- Manual TODO added in `docs/AI_TOOLING_SETUP_STATUS.md`

## 11) Files Created/Modified
- Modified:
  - `.cursor/mcp.json`
  - `.vscode/settings.json`
  - `addons/godot-mcp-pro/server/package-lock.json`
  - `addons/godot_mcp/plugin.cfg`
  - `addons/godot_mcp/plugin.gd`
  - `addons/godot_mcp/plugin.gd.uid`
- Added:
  - `AGENTS.md`
  - `docs/AI_DEV_RUNBOOK.md`
  - `docs/PLAYTEST_CHECKLIST.md`
  - `docs/GDUNIT4_TEST_PLAN.md`
  - `docs/AI_TOOLING_SETUP_STATUS.md`
  - `opencode.json`
  - `tests/README.md`
  - `scripts/ai/README.md`
  - `scripts/ai/check_ai_tooling.ps1`
  - backup tree under `reports/ai/setup-backups/20260516-173823/`
  - copied Godot MCP Pro addon files into `addons/godot_mcp/` (original paid package retained)

## 12) Commands Run (Key)
- Audit:
  - `git status --short`
  - `git branch --show-current`
  - `where.exe <cmd>` / `<cmd> --version` for required/optional toolchain
- Discovery:
  - glob/file searches for Godot MCP Pro addon/server artifacts
- Backups/directories:
  - timestamped copy for existing setup files
  - ensured directory structure
- Godot MCP Pro:
  - copied paid plugin into normalized `addons/godot_mcp`
  - `npm install`
  - `npm run build`
- DAP MCP:
  - `git clone https://github.com/TransitionMatrix/godot-dap-mcp-server.git ...`
- Validation:
  - JSON parsing checks
  - `powershell -ExecutionPolicy Bypass -File scripts/ai/check_ai_tooling.ps1`
  - `Test-NetConnection` probes for ports 6505/6005/6006

## 13) Errors Encountered
- `go` command not found (blocked DAP server build)
- `opencode` command not found
- `nmem` command not found
- `godot` command not found from PATH (manual Godot launch path may still work)
- First plugin copy created nested `addons/godot_mcp/godot_mcp`; corrected by flattening and removing only accidental nested folder

## 14) Manual Steps Remaining (Godot/Cursor)
1. Open Godot project.
2. Enable **Godot MCP Pro** plugin in Project Settings -> Plugins.
3. Install Go and add to PATH.
4. Build DAP server:
   - `cd "C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server"`
   - `go build -o godot-dap-mcp-server.exe cmd/godot-dap-mcp-server/main.go`
5. Add `godot-dap-debugger` MCP entry after exe exists.
6. Install GdUnit4 from official source and enable plugin.
7. Install/configure OpenCode + Nowledge Mem once `opencode` and `nmem` are on PATH.
8. Restart Cursor MCP servers.

## 15) Final Readiness Status
- **Partially ready**
- Reasons:
  - Core MCP stack is partially configured and validated (`godot-mcp-pro` + `godot-lsp-diagnostics`)
  - Paid Godot MCP Pro addon/server detected and built successfully
  - DAP MCP debugger server blocked by missing Go
  - GdUnit4 not yet installed
  - OpenCode/Nowledge CLI tools missing from PATH
  - Godot MCP Pro WebSocket port 6505 not open during this run (plugin likely not enabled/running yet)
