## Godot MCP Pro Runtime Timeout Diagnosis

Date/time: 2026-05-17 (local session time, UTC-4)

### Scope and safety
- Read-only diagnosis only.
- No gameplay code edits, no refactors, no git staging/commit/push.

### 1) MCP tools that responded before launch
- `project-0-my-2d-game-godot-mcp-pro:get_project_info` -> success.
- `project-0-my-2d-game-godot-mcp-pro:get_scene_tree` -> success.
- `project-0-my-2d-game-godot-mcp-pro:get_project_settings` -> success.
- `project-0-my-2d-game-godot-mcp-pro:list_scripts` -> success.
- `project-0-my-2d-game-godot-mcp-pro:get_editor_errors` -> success.
- `project-0-my-2d-game-godot-lsp-diagnostics:scan_workspace_diagnostics` -> success.
- `project-0-my-2d-game-godot-dap-debugger:godot_ping` -> success (`pong`).

### 2) Exact runtime tools available (from schemas)
- `play_scene`
  - Required args: none
  - Optional args: `mode` (`"main"`, `"current"`, or scene path)
- `stop_scene`
  - Required args: none
  - Optional args: none
- `get_output_log`
  - Required args: none
  - Optional args: `max_lines` (number), `filter` (string)
- `get_game_screenshot`
  - Required args: none
  - Optional args: `save_path` (string)
- `get_editor_screenshot` (editor capture alternative)
  - Required args: none
  - Optional args: `save_path` (string)
- `simulate_key`
  - Required args: `keycode` (string, e.g. `KEY_W`)
  - Optional args: `pressed` (bool), `duration` (number), `shift`/`ctrl`/`alt` (bool)
- `simulate_action`
  - Required args: `action` (string)
  - Optional args: `pressed` (bool), `strength` (number)

### 3) Tool/args that timed out
- Runtime sequence:
  1. `play_scene` with `{ "mode": "main" }` -> success (`playing: true`).
  2. Waited 2 seconds.
  3. `get_output_log` with `{ "max_lines": 20 }` -> **timed out after 30000ms**.
- Post-timeout health probe:
  - `get_project_info` (no args) -> **timed out after 30000ms**.

### 4) Schema mismatch findings
- Yes, one likely mismatch from earlier smoke test context: `simulate_key` requires `keycode`; calling without `keycode` will fail validation.
- In this run, the timed-out call (`get_output_log`) used valid arguments and still timed out.

### 5) Do runtime commands work before `play_scene` but fail after?
- Evidence strongly indicates **yes**:
  - Multiple editor/read-only commands worked before launch.
  - `play_scene` itself succeeded.
  - First runtime-adjacent call after launch (`get_output_log`) timed out.
  - Subsequent simple read-only probe (`get_project_info`) also timed out, suggesting a post-launch MCP responsiveness stall.

### 6) Did the game appear stuck/hung?
- Likely a **server/plugin communication stall** after entering play mode.
- Network ports remained reachable after timeout checks:
  - `6505` (MCP), `6005` (LSP), `6006` (DAP) all still `TcpTestSucceeded: True`.
- Process/listener ownership was not clearly reported via shell process snapshot, so game-window state could not be conclusively confirmed from terminal alone.

### 7) Did stop command work?
- `stop_scene` was **not executed in this pass** because sequence was halted immediately at first timeout per instruction.
- Clean stop remains unconfirmed in this run.

### 8) Most likely cause (ranked)
1. Godot MCP Pro runtime bridge stall after `play_scene` (highest likelihood).
2. Runtime API call path blocked by play-mode state transition (tool issue in plugin/runtime service).
3. Less likely: argument/schema issue for `get_output_log` (args were valid).
4. Possible contributing factor: game window/editor focus or scene startup state.

### 9) Recommended next safe fix
1. In Godot editor, stop any running scene manually (`F8` or top-right Stop button).
2. Disable then re-enable `Godot MCP Pro` plugin in Project Settings -> Plugins.
3. Restart Godot editor.
4. Restart Cursor MCP servers.
5. Re-run a minimal probe sequence:
   - `get_project_info` (must succeed)
   - `play_scene { "mode": "main" }`
   - `get_game_screenshot { "save_path": "user://mcp_probe.png" }` (avoid large base64 response path)
   - `stop_scene`
6. If it still stalls, collect Godot Output/Debugger logs immediately after `play_scene` and inspect `addons/godot_mcp` runtime service errors (no code changes yet).

### 10) Manual steps if scene is still running
1. Bring Godot to foreground.
2. Press `F8` (Stop Running Project), or click the Stop square button.
3. Confirm title bar no longer shows active run state.
4. Re-run port checks and a simple MCP read-only call.

### 11) Ready for real debugging?
- **Not ready yet** for reliable runtime debugging.
- Editor-side MCP + LSP + DAP are healthy, but runtime interaction becomes unstable right after `play_scene`.
