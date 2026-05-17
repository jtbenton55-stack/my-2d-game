# Godot AI Tooling Smoke Test Report

## Date/Time
- 2026-05-17 11:04 (local)

## Branch
- c2a-full-character-animation-20260509-172230

## 1) Git Status
- git status --short returned a non-clean working tree with prior setup-related changes already present.

## 2) Port Checks
- 6505 (Godot MCP Pro): TcpTestSucceeded = True
- 6005 (Godot LSP): TcpTestSucceeded = True
- 6006 (Godot DAP): TcpTestSucceeded = True

## 3) godot-mcp-pro Read-Only Check
- Tool used: get_project_info
- Result: successful
- Key returned info:
  - Godot version: 4.6.2-stable
  - Project: Untitled Heist RPG
  - Main scene: es://scenes/MainMenu.tscn
  - Autoloads include MCP entries (MCPScreenshot, MCPInputService, MCPGameInspector).

## 4) godot-lsp-diagnostics Check
- Tool used: scan_workspace_diagnostics
- Result: successful
- Summary:
  - Files scanned: 58
  - Files with issues: 3
  - Returned mostly warnings, plus some editor/LSP parse/type issues listed by the tool output.

## 5) godot-dap-debugger Availability
- Tool used: godot_ping
- Result: successful (Echo: pong)
- Status: debugger MCP server appears available/responding.

## 6) Godot MCP Pro Dock "Clients: 1"
- Direct dock text readback is not exposed as a dedicated no-arg MCP tool in this environment.
- Practical status inference: because port 6505 is open and godot-mcp-pro tool calls succeeded, the MCP Pro bridge appears connected/healthy.

## Notes
- A test call to execute_editor_script without parameters failed with validation error (code argument required). This does not indicate MCP outage; it indicates missing required arguments.
