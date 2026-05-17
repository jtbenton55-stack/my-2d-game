# DAP MCP Setup Report

## 1) Date/Time
- 2026-05-16 18:09 (local)

## 2) Current Branch
- c2a-full-character-animation-20260509-172230

## 3) Git Status Before/After
- Before (start of this continuation):
  - existing in-progress tooling/setup changes already present in working tree.
- After:
  -  M .cursor/mcp.json
  -  M .vscode/settings.json
  -  M addons/godot-mcp-pro/server/package-lock.json
  -  M addons/godot_mcp/plugin.cfg
  -  M addons/godot_mcp/plugin.gd
  -  M addons/godot_mcp/plugin.gd.uid
  -  M project.godot
  - ?? AGENTS.md
  - ?? addons/gdUnit4/
  - ?? addons/godot-mcp-pro/server/node_modules/
  - ?? addons/godot_mcp/command_router.gd
  - ?? addons/godot_mcp/command_router.gd.uid
  - ?? addons/godot_mcp/commands/
  - ?? addons/godot_mcp/mcp_game_inspector_service.gd
  - ?? addons/godot_mcp/mcp_game_inspector_service.gd.uid
  - ?? addons/godot_mcp/mcp_input_service.gd
  - ?? addons/godot_mcp/mcp_input_service.gd.uid
  - ?? addons/godot_mcp/mcp_screenshot_service.gd
  - ?? addons/godot_mcp/mcp_screenshot_service.gd.uid
  - ?? addons/godot_mcp/skills.es.md
  - ?? addons/godot_mcp/skills.hi.md
  - ?? addons/godot_mcp/skills.ja.md
  - ?? addons/godot_mcp/skills.md
  - ?? addons/godot_mcp/skills.pt-br.md
  - ?? addons/godot_mcp/skills.ru.md
  - ?? addons/godot_mcp/skills.zh.md
  - ?? addons/godot_mcp/ui/
  - ?? addons/godot_mcp/utils/node_utils.gd
  - ?? addons/godot_mcp/utils/node_utils.gd.uid
  - ?? addons/godot_mcp/utils/property_parser.gd
  - ?? addons/godot_mcp/utils/property_parser.gd.uid
  - ?? addons/godot_mcp/websocket_server.gd
  - ?? addons/godot_mcp/websocket_server.gd.uid
  - ?? docs/AI_DEV_RUNBOOK.md
  - ?? docs/AI_TOOLING_SETUP_STATUS.md
  - ?? docs/GDUNIT4_TEST_PLAN.md
  - ?? docs/PLAYTEST_CHECKLIST.md
  - ?? opencode.json
  - ?? reports/
  - ?? scripts/ai/
  - ?? tests/

## 4) Go Version and Path
- go version: go version go1.26.3 windows/amd64
- where.exe go: NOT_FOUND_IN_PATH
- Explicit executable used: C:\Program Files\Go\bin\go.exe

## 5) DAP MCP Repo State
- Repository path: C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server
- Repo action: already present, status clean, git pull run
- Pull result: Already up to date.

## 6) Exact Build Command Used
- "C:\Program Files\Go\bin\go.exe" build -o godot-dap-mcp-server.exe cmd/godot-dap-mcp-server/main.go

## 7) Executable Created
- Yes
- C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server\godot-dap-mcp-server.exe

## 8) .cursor\mcp.json Updated
- Yes
- Backup created:
  - eports\ai\setup-backups\20260516-180655\.cursor\mcp.json
- Added MCP server entry:
  - godot-dap-debugger

## 9) Current MCP Entries in .cursor\mcp.json
- godot-mcp-pro
- godot-lsp-diagnostics
- siliconflow-kimi-k2-6
- godot-dap-debugger

## 10) Port Check Results
- 6505: CLOSED
- 6005: OPEN
- 6006: OPEN

Interpretation:
- 6505 closed likely means Godot MCP Pro plugin/service still needs enable/restart in Godot.
- 6005 and 6006 open indicate Godot LSP and DAP services are reachable.

## 11) Errors
- go is still not discoverable via PATH in this shell (go and where.exe go fail), despite installed executable being present and functional at explicit path.
- No build errors once explicit Go path was used.

## 12) Remaining Manual Steps
1. Add C:\Program Files\Go\bin to system/user PATH so go resolves normally.
2. In Godot, verify **Godot MCP Pro** plugin is enabled and restart Godot if needed.
3. Restart Cursor MCP servers so new godot-dap-debugger entry is loaded.
4. Re-check port 6505 after Godot plugin restart.
