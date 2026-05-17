## Godot MCP Pro Runtime Root Cause and Fix Plan

Date/time: 2026-05-17 12:xx PM (UTC-4)

Branch: `c2a-full-character-animation-20260509-172230`

### 1) Git status before/after
- **Before**: dirty working tree (existing `.cursor`, addon, docs, reports, scene backup moves).
- **After**: same dirty tree plus one new diagnostic scene:
  - `scenes/testing/McpRuntimeBlankTest.tscn`
  - this report file.

### 2) Baseline MCP health
- `.cursor/mcp.json` is valid JSON.
- MCP entries present: `godot-mcp-pro`, `godot-lsp-diagnostics`, `godot-dap-debugger`, `siliconflow-kimi-k2-6`.
- Ports reachable at baseline:
  - `6505` (MCP): open
  - `6005` (LSP): open
  - `6006` (DAP): open
- Pre-play tool checks:
  - `godot-mcp-pro:get_project_info` -> success
  - `minimal-godot-mcp:scan_workspace_diagnostics` -> success
  - `godot-dap-debugger:godot_ping` -> success

### 3) Runtime/autoload configuration findings
- Godot MCP Pro plugin is configured and active:
  - `addons/godot_mcp/plugin.gd` starts WebSocket client and command router.
  - It injects MCP autoloads (`MCPScreenshot`, `MCPInputService`, `MCPGameInspector`) on plugin startup.
- `project.godot` autoload section currently includes:
  - `MCPRuntime` -> `res://addons/godot_mcp/runtime/mcp_runtime.gd`
  - `MCPGameInspector`, `MCPInputService`, `MCPScreenshot` (file-IPC services)
  - plus unrelated runtime bridge autoloads (`GRBServer`, `McpInteractionServer`).
- Runtime/autoload wiring appears **present**, not missing.

### 4) Exact tool schemas discovered
- `play_scene`: optional `mode` (`main`, `current`, or scene path)
- `stop_scene`: no args
- `get_output_log`: optional `max_lines`, `filter`
- `get_editor_screenshot`: optional `save_path`
- `get_game_screenshot`: optional `save_path` (requires playing scene)
- `simulate_key`: required `keycode`; optional `pressed`, `duration`, modifiers
- `simulate_action`: required `action`; optional `pressed`, `strength`

### 5) Test matrix results

#### Test A — Manual Play, then MCP read
- Manual run of blank scene requested and confirmed running.
- While manually running, `get_project_info` timed out (30s).
- Result: manual play alone is sufficient to trigger MCP unresponsiveness.

#### Test B — MCP `play_scene` main
- `play_scene { "mode": "main" }` -> success.
- After 2s, `get_project_info` -> timeout (30s).
- `stop_scene` also timed out afterward.
- Result: MCP-triggered play wedges post-play requests.

#### Test C — MCP `play_scene` minimal blank scene
- Created `scenes/testing/McpRuntimeBlankTest.tscn` (minimal Control + Label).
- `play_scene { "mode": "res://scenes/testing/McpRuntimeBlankTest.tscn" }` -> success.
- After 2s, `get_project_info` -> timeout (30s).
- Result: minimal scene does **not** avoid timeout.

#### Test D — Manual blank scene play
- Manual blank-scene run confirmed.
- `get_project_info` during run -> timeout (30s).
- After manual stop, `get_project_info` works again.
- Result: entering play mode (manual or MCP) causes same failure pattern.

### 6) Does main scene specifically cause timeout?
- **No**. The timeout reproduces with a minimal blank scene, both manual and MCP start.
- This points to a play-mode/bridge lifecycle issue, not gameplay scene complexity.

### 7) Cursor/Node MCP logs and error signals found
- Node side (`tools/godot-mcp-pro/server/build/godot-connection.js`) has hard command timeout at `30000ms`.
- Godot plugin websocket layer (`addons/godot_mcp/websocket_server.gd`) has inactivity watchdog `30s`, force reconnect on silence.
- Observed many `TIME_WAIT` connections on `6505` after failures, consistent with repeated request timeout/reconnect churn.
- No clear stacktrace from `get_editor_errors`; only Vulkan loader warning (non-blocking noise).
- Cursor-exposed MCP log stream was not directly available beyond tool timeout surfaces.

### 8) Most likely root cause
- **Primary finding**: entering play mode causes the Godot MCP Pro editor-side message loop to stop servicing subsequent MCP requests until play is stopped manually.
- Because this reproduces on blank scene and manual play, likely causes are:
  1. Play-mode state transition in MCP Pro plugin/websocket handling (editor thread not servicing command dispatch while playing), or
  2. Bridge heartbeat/request lifecycle conflict causing dead connection state during play.
- Less likely causes:
  - schema mismatch (calls used valid args),
  - main-scene-specific script load,
  - missing runtime autoload (autoloads are present).

### 9) Fixes attempted
- Added isolated minimal test scene: `scenes/testing/McpRuntimeBlankTest.tscn`.
- Reproduced issue across manual + MCP play paths.
- No proprietary plugin source edits were made.
- No gameplay code changes were made.

### 10) Safe fix status
- No clearly safe config-only fix has been proven to resolve the wedge in-session.
- `GODOT_MCP_PORT` is already correctly set (`6505`) and reachable.

### 11) Recommended next safe fix
1. Keep `scenes/testing/McpRuntimeBlankTest.tscn` as a reproducibility harness.
2. In Godot, use MCP Pro dock Activity + Clients tabs while running blank scene and record whether command events appear after play starts.
3. Restart sequence:
   - Stop scene
   - Disable/Enable Godot MCP Pro plugin
   - Restart Godot editor
   - Restart Cursor MCP servers
4. Re-run only:
   - `get_project_info`
   - `play_scene` blank
   - `get_project_info`
   - `stop_scene`
5. If still reproducible, provide this exact repro to Godot MCP Pro support (high confidence bug report: “play mode blocks even editor-only tools until manual stop”).

### 12) Ready for real playtesting?
- **Not ready** for reliable runtime/play-mode MCP automation yet.
- Editor-mode MCP + LSP + DAP checks are healthy; play-mode bridge reliability is not.

### 13) Remaining questions for Jake / Godot MCP Pro support
- Is this known for Godot `4.6.2` with MCP Pro `1.13.2`?
- Are there required plugin settings to keep editor command routing active during play mode?
- Is there a recommended increased command timeout or alternate runtime transport path for play-mode calls?
- Is coexistence with `godot-runtime-bridge` plugin officially supported in same project session?
