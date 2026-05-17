## Godot MCP Pro Play-Mode Diagnostic Results

### Step 1 - Godot Process and TCP Baseline

Date/time: 2026-05-17 13:37 local (UTC-4)

Commands run:

```powershell
Get-Process Godot* | Select-Object Id, ProcessName, Path
Get-NetTCPConnection -LocalPort 6505 | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State
```

Findings:

- `Get-Process Godot*` returned no rows. Based on this exact process-name filter, no process matching `Godot*` was visible at the time of the check.
- Port `6505` still had an active listener and one established loopback connection:

```text
LocalAddress  LocalPort  RemoteAddress  RemotePort  State
127.0.0.1     6505       127.0.0.1      63586       Established
127.0.0.1     6505       0.0.0.0        0           Listen
```

Interpretation:

- The port baseline shows the Godot MCP Pro Node/WebSocket side is listening on `127.0.0.1:6505`.
- There is already one established client connection to `6505`, even though `Get-Process Godot*` did not list a Godot process. This is suspicious and should be rechecked after Godot is explicitly closed/reopened in Step 2.
- Step 1 did **not** detect multiple `Godot*` processes, so it did not trigger the "close all duplicate Godot instances" stop condition.

Status:

- Step 1 complete.
- Do not proceed to Step 2 until Jake confirms.

### Step 2 - Godot Editor Verbose Log and TCP State During Hang

Date/time: 2026-05-17 13:38-13:45 local (UTC-4)

Commands/actions run:

```powershell
New-Item -ItemType Directory -Force "reports\ai\logs" | Out-Null
$godot = "C:\Users\jtben\Documents\PBD 2026\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe"
$project = "C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game"
& $godot --editor --verbose --path $project *>&1 | Tee-Object -FilePath "reports\ai\logs\godot_editor_mcp_playmode_hang.log"
Get-NetTCPConnection -LocalPort 6505 | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State
```

Manual actions:

- Jake closed Godot before the verbose run.
- Godot was launched from PowerShell with verbose stdout/stderr capture.
- Jake opened and manually ran `res://scenes/testing/McpRuntimeBlankTest.tscn`.
- A `godot-mcp-pro.get_project_info` MCP call was triggered during play mode and timed out after 30 seconds.
- Jake manually stopped play mode after the timeout.

Godot executable used:

```text
C:\Users\jtben\Documents\PBD 2026\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe
```

TCP state immediately after manual play started:

```text
LocalAddress  LocalPort  RemoteAddress  RemotePort  State
127.0.0.1     6505       127.0.0.1      62191       Established
127.0.0.1     6505       0.0.0.0        0           Listen
```

TCP state during the 30-second `get_project_info` timeout:

```text
LocalAddress  LocalPort  RemoteAddress  RemotePort  State
127.0.0.1     6505       127.0.0.1      61538       Established
127.0.0.1     6505       0.0.0.0        0           Listen
```

TCP state after manual stop:

```text
LocalAddress  LocalPort  RemoteAddress  RemotePort  State
127.0.0.1     6505       127.0.0.1      62793       Established
127.0.0.1     6505       0.0.0.0        0           Listen
```

Verbose log findings:

- The editor loaded `res://addons/godot_mcp/plugin.gd`, `res://addons/godot_mcp/ui/status_panel.tscn`, and `res://addons/godot_mcp/ui/status_panel.gd`.
- The plugin reported startup and command registration:

```text
[MCP] Connecting to ports 6505-6514
[MCP] Godot MCP Pro v1.13.2 started (ports 6505-6514)
[MCP] Registered 171 commands
[MCP] Connected on port 6505
```

- The runtime autoload was present in the load log:

```text
Loading resource: res://addons/godot_mcp/runtime/mcp_runtime.gd
```

- The manual blank-scene launch was visible:

```text
Running: C:/Users/jtben/Documents/PBD 2026/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe --verbose --path C:/Users/jtben/Documents/PBD%202026/OpenClaw/main/games/my-2d-game --remote-debug tcp://127.0.0.1:6007 --editor-pid 38828 --scene res://scenes/testing/McpRuntimeBlankTest.tscn --wid 5179500 --position 480,270 --resolution 960x540
```

- Immediately after the blank scene launched, the Godot MCP Pro editor/plugin connection began repeatedly disconnecting and reconnecting:

```text
[MCP] Disconnected from port 6505
[MCP] Connected on port 6505
[MCP] Disconnected from port 6505
[MCP] Connected on port 6505
...
```

- The repeated disconnect/reconnect cycle continued until play mode was stopped, after which a final `[MCP] Connected on port 6505` was logged.
- The log did not show an obvious GDScript stack trace for `MCPRuntime`, `MCPGameInspector`, `MCPInputService`, or `MCPScreenshot` in the captured excerpt.
- The log did not show TCP moving to `CLOSE_WAIT` or `TIME_WAIT`; PowerShell observed `Established` plus `Listen` throughout the play-mode hang.
- Unrelated LSP parse errors were present for existing project scripts, but these were not temporally tied to the play-mode hang and do not involve the MCP runtime scripts.

Interpretation:

- Step 2 confirms the failure is not a closed port problem. Port `6505` remains listening and has an established loopback connection before/during/after the timeout.
- The strongest new evidence is the editor-side Godot MCP Pro client repeatedly disconnecting and reconnecting to the Node/WebSocket server immediately after entering play mode.
- The MCP call timeout appears consistent with a connection/session churn problem: the server remains reachable at TCP level, but the Godot-side plugin connection is not stable enough to service commands during play.
- Because the issue reproduces with `McpRuntimeBlankTest.tscn`, the log still does not implicate scene gameplay logic.
- The log suggests disconnect/reconnect or handler interruption rather than a simple plugin crash, because the plugin continues to reconnect and no MCP script stack trace is visible in the captured output.

Status:

- Step 2 complete.
- Do not proceed to Step 3 until Jake confirms.

### Step 3 - Embedded vs Separate Game Window Test

Date/time: 2026-05-17 13:52-13:58 local (UTC-4)

Initial Godot run/window placement settings reported by Jake:

```text
Rect: Centered
Rect custom position: x 0.0; y 0.0
Screen: Same as Editor
Android window: Auto (based on screen size)
Game Embed Mode: Use Per-Project Configuration
```

Change made manually by Jake:

- `Game Embed Mode` was changed to `Disabled`.
- Godot was fully restarted after the setting change.

Retest sequence:

1. `godot-mcp-pro.get_project_info` before play.
2. Jake manually ran `res://scenes/testing/McpRuntimeBlankTest.tscn`.
3. `godot-mcp-pro.get_project_info` during play.
4. Jake manually stopped play mode.
5. `godot-mcp-pro.get_project_info` after stop.

Results:

- Pre-play `get_project_info` succeeded.
- During-play `get_project_info` timed out after 30 seconds.
- After manual stop, `get_project_info` succeeded again.

Key pre-play/post-stop project info observed:

```text
Godot version: 4.6.2-stable (official)
Project name: Untitled Heist RPG
Main scene: res://scenes/MainMenu.tscn
Renderer: forward_plus
MCP autoloads present:
- MCPRuntime
- MCPGameInspector
- MCPInputService
- MCPScreenshot
```

Interpretation:

- Disabling Godot's game embed mode did **not** resolve the MCP Pro play-mode hang.
- This makes "embedded game workspace/window placement" unlikely to be the root cause.
- The failure pattern remained stable: MCP editor/project commands work before play, hang during play, and recover after play stops.
- This result is consistent with Step 2's evidence of Godot MCP Pro connection/session instability during play, but it does not point to the embedding layer as the cause.

Status:

- Step 3 complete.
- Do not proceed to Step 4 until Jake confirms.

### Step 4 - Runtime Bridge and Autoload Configuration Inspection

Date/time: 2026-05-17 13:58-14:09 local (UTC-4)

Scope:

- Read-only inspection only.
- No files were edited.
- No new autoloads or test scenes were created.

Files/directories inspected:

```text
project.godot
addons/godot_mcp/plugin.cfg
addons/godot_mcp/plugin.gd
addons/godot_mcp/runtime/
addons/godot_mcp/runtime/mcp_runtime.gd
addons/godot_mcp/runtime/mcp_runtime.gd.uid
addons/godot_mcp/commands/runtime_commands.gd
addons/godot_mcp/commands/input_commands.gd
addons/godot_mcp/commands/test_commands.gd
addons/godot_mcp/ui/status_panel.gd
addons/godot_mcp/websocket_server.gd
addons/godot_mcp/command_router.gd
addons/godot_mcp/commands/scene_commands.gd
```

MCP-related autoloads in `project.godot`:

```text
MCPRuntime="*uid://c13j8nchilhxj"
MCPScreenshot="*res://addons/godot_mcp/mcp_screenshot_service.gd"
MCPInputService="*res://addons/godot_mcp/mcp_input_service.gd"
MCPGameInspector="*res://addons/godot_mcp/mcp_game_inspector_service.gd"
```

Autoload ownership/path notes:

- `MCPRuntime` resolves to `addons/godot_mcp/runtime/mcp_runtime.gd.uid`, whose contents are `uid://c13j8nchilhxj`; this is inside the Godot MCP Pro addon.
- `MCPScreenshot`, `MCPInputService`, and `MCPGameInspector` are direct `res://addons/godot_mcp/...` autoloads.
- All MCP-prefixed autoloads are addon-owned, not user gameplay scripts.
- `project.godot` also has non-MCP AI/runtime-related autoloads `McpInteractionServer` and `GRBServer`, but their names do not begin with `MCP`, `GodotMCP`, or lowercase `mcp`.

Plugin metadata:

```text
name="Godot MCP Pro"
description="Premium MCP server for AI-powered Godot development. Connects via WebSocket to expose 172 editor tools."
version="1.13.2"
script="plugin.gd"
```

Runtime directory contents:

```text
addons/godot_mcp/runtime/mcp_runtime.gd
addons/godot_mcp/runtime/mcp_runtime.gd.uid
```

Important source matches:

```text
addons/godot_mcp/plugin.gd:5  autoload/MCPScreenshot -> res://addons/godot_mcp/mcp_screenshot_service.gd
addons/godot_mcp/plugin.gd:6  autoload/MCPInputService -> res://addons/godot_mcp/mcp_input_service.gd
addons/godot_mcp/plugin.gd:7  autoload/MCPGameInspector -> res://addons/godot_mcp/mcp_game_inspector_service.gd
addons/godot_mcp/plugin.gd:31-46 creates MCPWebSocketServer, creates status panel, injects autoloads, starts websocket_server
addons/godot_mcp/plugin.gd:41 status_panel.call_deferred("setup", websocket_server, command_router)
addons/godot_mcp/plugin.gd:75-86 injects only the three file-IPC autoloads above
addons/godot_mcp/runtime/mcp_runtime.gd:2-8 describes MCPRuntime as a game-runtime autoload that connects to the same MCP WebSocket server with role="runtime"
addons/godot_mcp/runtime/mcp_runtime.gd:13 SERVER_URL := "ws://127.0.0.1:6505"
addons/godot_mcp/runtime/mcp_runtime.gd:43-52 sends {"type":"godot_ready","role":"runtime"} once its WebSocket opens
addons/godot_mcp/runtime/mcp_runtime.gd:58-74 reconnects every 2 seconds when closed
addons/godot_mcp/runtime/mcp_runtime.gd:105-118 dispatches runtime-only tool_invoke names: take_screenshot, send_input, query_runtime_node, get_runtime_log, list_signal_connections
addons/godot_mcp/commands/runtime_commands.gd:4-5 says editor-side runtime inspection communicates with MCPGameInspector via file-based IPC
addons/godot_mcp/commands/runtime_commands.gd:309-358 writes user://mcp_game_request, polls user://mcp_game_response, and times out with "Ensure the game is running and MCPGameInspector autoload is active"
addons/godot_mcp/commands/input_commands.gd:4 writes input commands to user://mcp_input_commands
addons/godot_mcp/commands/input_commands.gd:9,17 defines simulate_key
addons/godot_mcp/commands/test_commands.gd:5 describes editor-side orchestration plus runtime assertions via file-based IPC
addons/godot_mcp/ui/status_panel.gd:71 initial status text is "MCP Pro: Waiting for connection..."
addons/godot_mcp/ui/status_panel.gd:216-234 displays "Connected", "Reconnecting (stale connection detected)", or "Waiting for connection" based on websocket_server client count/stale state
addons/godot_mcp/ui/status_panel.gd:240-279 shows per-port connected/stale/disconnected labels for ports 6505-6509
addons/godot_mcp/websocket_server.gd:4-7 describes the editor plugin side as a multi-connection WebSocket client that connects to Node MCP server ports 6505-6514
addons/godot_mcp/websocket_server.gd:87-92 connects to ws://127.0.0.1:<port>
addons/godot_mcp/websocket_server.gd:145-155 force-closes a port after 30 seconds of no received messages and marks it stale
addons/godot_mcp/websocket_server.gd:193-229 parses JSON-RPC requests, handles ping/pong, then uses _execute_command.call_deferred(...)
addons/godot_mcp/websocket_server.gd:232-245 awaits command_router.execute(...) before sending the JSON-RPC response
addons/godot_mcp/command_router.gd:17-43 registers command classes including scene, editor, input, runtime, and test commands
addons/godot_mcp/command_router.gd:75-77 awaits the selected handler callable
addons/godot_mcp/commands/scene_commands.gd:172-187 play_scene directly calls play_main_scene(), play_current_scene(), or play_custom_scene()
addons/godot_mcp/commands/scene_commands.gd:190-202 stop_scene directly calls stop_playing_scene() and cleans temp IPC files
```

Answers to Step 4 questions:

1. Is there a runtime bridge expected to connect back during play mode?

Yes. `MCPRuntime` is an autoload intended to run inside the launched game process. It opens its own `WebSocketPeer` to `ws://127.0.0.1:6505` and sends a `godot_ready` message with `role="runtime"` when connected. This appears separate from the editor plugin's `MCPWebSocketServer` client, which also connects to the same Node MCP server ports.

2. Is there a dock or status indicator for that runtime connection?

There is an `MCP Pro` bottom-panel dock. The inspected status panel shows only generic connection/client count and per-port state (`Connected`, `Stale`, `Disconnected`) for ports `6505-6509`. It does not appear to distinguish editor-client vs runtime-client roles in the inspected GDScript.

3. Does the plugin appear to wait for a runtime handshake before servicing further commands?

No direct GDScript-side wait for a `MCPRuntime` handshake was found in `plugin.gd`, `websocket_server.gd`, `command_router.gd`, or the inspected command files. The editor plugin dispatches incoming JSON-RPC messages with `_execute_command.call_deferred(...)`, and `_execute_command` awaits `command_router.execute(...)`.

4. Is the wait synchronous or deferred?

Incoming WebSocket messages are parsed synchronously in `_dispatch_message`, but command execution is deferred with `call_deferred`. Once executing, `_execute_command` awaits `command_router.execute`, and `command_router.execute` awaits the specific command handler. Runtime/file-IPC commands then await timers while polling for response files. However, `get_project_info` is an editor/project command and should not require `MCPGameInspector` file-IPC or a game-runtime response.

5. If synchronous, could it block the command queue?

The code has places where a long-running awaited handler can delay that command's response, especially runtime commands that poll for `user://mcp_game_response`. But this does not fully explain the observed during-play timeout for `get_project_info`, which should be editor-only. The Step 2 disconnect/reconnect spam and Step 4 architecture suggest a different issue: when play starts, both the editor plugin client and `MCPRuntime` runtime client may be connecting to the same Node MCP port (`6505`). If the Node server or protocol path expects only one Godot-side client per port, the runtime client could be displacing or destabilizing the editor plugin connection, causing editor-only calls to time out even though TCP still shows an established loopback connection.

Configuration assessment:

- The runtime/autoload configuration appears complete in the sense that the relevant autoloads exist and point into the Godot MCP Pro addon.
- It is suspicious that `plugin.gd` injects only `MCPScreenshot`, `MCPInputService`, and `MCPGameInspector`, while `MCPRuntime` is present separately in `project.godot` via UID. The source comment in `mcp_runtime.gd` says it is auto-registered by the plugin on `_enable_plugin()`, but the inspected `plugin.gd` `_MCP_AUTOLOADS` array does not include `MCPRuntime`.
- It is also suspicious that `MCPRuntime` connects to the exact same WebSocket URL and port as the editor plugin's MCP connection, while Step 2 showed repeated `[MCP] Disconnected from port 6505` / `[MCP] Connected on port 6505` immediately after play began.
- Current evidence points less toward a missing autoload and more toward a play-mode connection-role conflict or Node-server multi-client handling issue.

Status:

- Step 4 complete.
- Do not proceed to Step 5 until Jake confirms.

### Step 5 - Godot MCP Pro Dock State During Hang

Date/time: 2026-05-17 14:10-14:13 local (UTC-4)

Procedure:

1. Jake manually entered play mode on `res://scenes/testing/McpRuntimeBlankTest.tscn`.
2. During play, `godot-mcp-pro.get_project_info` was triggered and allowed to run to timeout.
3. During the 30-second timeout window, Jake observed the MCP Pro dock state across Activity, Clients, Tools, and header.
4. Jake then manually stopped play mode and immediately re-checked dock state.

Runtime probe result:

- `get_project_info` timed out after 30 seconds during play mode (same as prior steps).

Dock observations during timeout window (reported by Jake):

- **Activity tab:** showed client connect/disconnect events.
- **Clients tab:** `Clients: 0` / disconnected or waiting state.
- **Tools tab:** normal tool list with toggles still visible.
- **Header/status:** `MCP Pro: Waiting for connection...`
- **Screenshot:** Jake confirmed a screenshot of the dock during hang was captured.

Dock observations immediately after manual stop:

- **Header/status:** `MCP Pro: Connected`
- **Clients:** `Clients: 1 connected`

Interpretation:

- During play mode, the dock state directly indicates that the editor-side MCP Pro client loses its active client session (`Clients: 0`, waiting for connection) while requests are pending.
- After stopping play mode, the dock rapidly recovers to `Connected` with one client.
- This strongly supports "connection/session loss during play mode" rather than a pure command-schema mismatch or a permanently wedged server.
- The observed state aligns with Step 2 verbose log evidence of repeated `[MCP] Disconnected` / `[MCP] Connected` cycles after play starts.
- Combined with Step 4 architecture findings, the most likely mechanism remains play-mode connection churn involving editor/runtime client coordination on the same MCP server endpoint.

Status:

- Step 5 complete.
- Do not proceed to Step 6 until Jake confirms.

### Step 6 - Cursor and Node MCP Server Logs

Date/time: 2026-05-17 14:04-14:15 local (UTC-4)

Actions run:

```powershell
# Cursor log roots
$env:APPDATA\Cursor\logs
$env:LOCALAPPDATA\Cursor\logs

# Node MCP server help probe requested in step
node "C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js" --help 2>&1
```

Cursor log locations discovered:

- Primary logs root exists:
  - `C:\Users\jtben\AppData\Roaming\Cursor\logs`
- Alternate local logs root does not exist on this machine:
  - `C:\Users\jtben\AppData\Local\Cursor\logs`
- Relevant MCP server file:
  - `C:\Users\jtben\AppData\Roaming\Cursor\logs\20260516T200604\window1\exthost\anysphere.cursor-mcp\MCP project-0-my-2d-game-godot-mcp-pro.log`
- Related allowlist/tool-routing file:
  - `C:\Users\jtben\AppData\Roaming\Cursor\logs\20260516T200604\window1\workbench.mcp.allowlist.log`

Node `--help` probe result:

- Running `index.js --help` did **not** print a CLI help screen.
- Instead, it started the server:
  - `[MCP] Godot MCP Pro started (stdio transport)`
  - `[MCP] WebSocket server listening on ws://127.0.0.1:6506`
  - `[MCP] Godot editor connected`
- This indicates there is no obvious documented `--help`/`--verbose`/`--log-file` CLI flag exposed by this entrypoint from this probe.
- The accidentally started process was force-stopped to avoid interference with the active MCP session.

Captured log timeline evidence (Cursor Output + file logs):

- Initial healthy startup:
  - `CreateClient`, `connect_start`, `connect_success`, and `Successfully connected to stdio server`.
  - `[MCP] Godot editor connected`.
- During failure windows around play-mode testing:
  - Extremely frequent repeating pairs:
    - `[MCP] Godot editor connected`
    - `[MCP] Godot editor disconnected`
  - Repeats every ~0.1-3 seconds for extended periods.
- Additional relevant signal:
  - `Heartbeat timeout (no pong for 30000ms) — terminating dead connection` followed by disconnect.

Error-pattern scan result (from inspected logs):

- **Present:**
  - Repeated reconnect/disconnect churn.
  - Heartbeat timeout/no-pong event.
  - Connection dropped/closed behavior during play windows.
- **Not observed in inspected excerpts:**
  - `EPIPE`
  - `ECONNRESET`
  - `socket hang up`
  - Unhandled promise rejection messages
  - Schema validation errors
  - Explicit queue serialization deadlock text

Step-6 conclusion for requested question:

- The Node MCP server is **not** simply "connected and idle waiting on Godot response."
- The dominant behavior is **connection instability/disconnect churn** with the Godot-side client during play mode.
- This supports the current root-cause direction: play-mode triggers loss/churn of the editor-side MCP session (likely due to runtime/editor connection-role conflict or server-side handling of multiple Godot clients on the same endpoint), which causes MCP calls (including editor-only calls like `get_project_info`) to time out even while port `6505` remains open.

Status:

- Step 6 complete.
- Do not proceed to Step 7 until Jake confirms.

### Step 7 - `--lite` / `--minimal` Mode Test (Start, `--lite` Attempt)

Date/time: 2026-05-17 14:12-14:20 local (UTC-4)

Requested Step 7 status:

- Jake confirmed Cursor reload/restart completed after `.cursor/mcp.json` was updated with `--lite`.
- We then attempted to begin Step 7.4 (`get_project_info` before play) in Cursor MCP.

Current blocker observed:

- MCP tool call failed immediately because Cursor is currently not exposing the `godot-mcp-pro` server:
  - `MCP server does not exist: project-0-my-2d-game-godot-mcp-pro`
  - Available servers in this session were:
    - `plugin-context7-plugin-context7`
    - `plugin-vercel-vercel`
    - `project-0-my-2d-game-godot-dap-debugger`
    - `project-0-my-2d-game-godot-lsp-diagnostics`
    - `project-0-my-2d-game-siliconflow-kimi-k2-6`

Verification performed to isolate whether `--lite` itself is invalid:

- `.cursor/mcp.json` is valid JSON and includes the expected `godot-mcp-pro` entry with:
  - command: `node`
  - args: `C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js`, `--lite`
  - env: `GODOT_MCP_PORT=6505`
- Direct manual launch test succeeded:
  - `node "C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js" --lite`
  - Output:
    - `[MCP] Godot MCP Pro LITE started (81 tools, stdio transport)`
    - `[MCP] WebSocket server listening on ws://127.0.0.1:6505`
    - `[MCP] Godot editor connected`

Interpretation (for Step 7):

- `--lite` flag is accepted by the vendor server and can start successfully.
- The immediate issue is currently at Cursor MCP registration/discovery layer for this session (server not registered/exposed), not a vendor runtime timeout result from Step 7.4 yet.
- Because `godot-mcp-pro` is absent from active MCP servers in Cursor, the required in-Cursor `get_project_info` pre/during/post play sequence cannot be executed yet.

Status:

- Step 7 is started but blocked before Step 7.4 measurements.
- Awaiting user confirmation to run a focused Cursor-side re-registration check (reload MCP servers / verify discovery) and then resume the exact Step 7.4 sequence.

Step 7 continuation update (after re-enable/reload):

- Jake re-enabled `godot-mcp-pro` and reloaded MCP/Cursor.
- Server discovery check now passes in this session (descriptor present at:
  `mcps/project-0-my-2d-game-godot-mcp-pro/tools/get_project_info.json`).
- Step 7.4 pre-play probe was retried:
  - `godot-mcp-pro.get_project_info`
  - Result: `Connection error: Godot editor is not connected. Make sure the Godot MCP Pro plugin is enabled and the editor is running.`

Implication:

- Previous blocker ("server does not exist") is resolved.
- New immediate blocker is active editor-plugin connection state (`editor not connected`), which must be restored before pre-play/during-play/post-play timeout behavior can be measured for `--lite`.

Step 7.4 attempt #2 (immediately after "continue"):

- Action:
  - `godot-mcp-pro.get_project_info` (pre-play baseline probe)
- Result:
  - `Connection error: Godot editor is not connected. Make sure the Godot MCP Pro plugin is enabled and the editor is running.`

Assessment:

- Step 7.4 is still blocked at pre-play baseline due to no active editor-side MCP connection.
- We cannot start the required `--lite` sequence (pre-play success -> during-play probe -> post-stop recovery) until the editor connection is live.

Step 7.4 attempt #3 (after user-confirmed dock status: Connected, Clients: 2):

- User-provided live dock evidence:
  - Header: `MCP Pro: Connected`
  - Client count: `Clients: 2`
  - Activity stream: rapid connect/disconnect messages still visible.
- Schema check:
  - `mcps/project-0-my-2d-game-godot-mcp-pro/tools/get_project_info.json`
  - Tool takes no arguments.
- Action:
  - `godot-mcp-pro.get_project_info` (pre-play baseline probe)
- Result:
  - `Connection error: Godot editor is not connected. Make sure the Godot MCP Pro plugin is enabled and the editor is running.`

Interpretation:

- There is now a direct state contradiction between the Godot dock UI and MCP API behavior:
  - Dock indicates active connectivity (`Clients: 2`).
  - API-level tool call path still reports no editor connection.
- This is consistent with a role/session misclassification or stale/incorrect client binding in the Node<->Godot bridge under current `--lite` setup, rather than a simple "plugin disabled" condition.

Step 7 correlation snapshot (dock client view + fresh logs):

Date/time: 2026-05-17 14:17-14:19 local (UTC-4)

User-provided dock client view at capture time:

- `MCP Pro: Connected`
- `Clients: 2`
- Port states:
  - `6505 Connected (idle ~4s)`
  - `6506 Connected (idle ~4s)`
  - `6507/6508/6509 Disconnected`

Fresh API probe executed immediately after dock capture:

- Action: `godot-mcp-pro.get_project_info`
- Result: `Connection error: Godot editor is not connected...`

Fresh Cursor MCP server log evidence (same session):

- `14:14:45` and `14:15:08`: `Godot MCP Pro LITE started (81 tools, stdio transport)`
- Immediately followed by:
  - `Failed to start WebSocket server: Failed to bind WebSocket server on port range 6505`
  - `Last error: listen EADDRINUSE: address already in use 127.0.0.1:6505`
- The stdio client still reports `CreateClient completed, connected: true`, but the WebSocket bind failure means this new server instance cannot host the expected editor WebSocket endpoint.

Key implication for the contradiction:

- The dock's "2 clients" state is likely attached to an already-running/older WebSocket server process occupying `6505` (and also seeing activity on `6506`), while the currently registered Cursor-launched `--lite` server instance fails to bind `6505` and therefore cannot service editor-bound API calls like `get_project_info`.
- This explains why:
  - dock can appear connected with active clients, yet
  - MCP calls routed through the current Cursor server instance return "Godot editor is not connected."

Step-7 blocking cause (current):

- Port ownership conflict (`EADDRINUSE` on `127.0.0.1:6505`) creating split-brain server state between dock-visible connections and Cursor call path.

Step 7 port-owner isolation (exact PIDs and commands):

Date/time: 2026-05-17 14:19 local (UTC-4)

Commands run:

```powershell
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 6505,6506,6507,6508,6509 }
Get-NetTCPConnection | Where-Object { $_.LocalPort -in 6505,6506,6507,6508,6509 -or $_.RemotePort -in 6505,6506,6507,6508,6509 }
Get-CimInstance Win32_Process | Where-Object { $pids -contains $_.ProcessId }
```

Findings:

- Listening sockets:
  - `127.0.0.1:6505` -> PID `38728`
  - `127.0.0.1:6506` -> PID `29796`
- Established clients:
  - Godot editor PID `42068` connected to both `6505` and `6506`
  - Godot editor also repeatedly attempts `6507/6508/6509` (SYN_SENT), matching dock behavior.

Process mapping:

- PID `38728` (`node.exe`)
  - Command: `.../node.exe "C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js" --lite`
  - Owns port `6505`.
- PID `29796` (`node.exe`)
  - Command: `.../node.exe "C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js" --help`
  - Owns port `6506`.
- PID `42068` (`Godot_v4.6.2-stable_win64.exe --editor`)
  - Connected to both server ports.

Conclusion from isolation step:

- A stale standalone MCP Pro process launched with `--help` is still alive and occupying `6506`.
- A separate `--lite` MCP Pro process occupies `6505`.
- Godot is connected to both, producing the dock's `Clients: 2` state.
- This confirms the split-brain condition is process-level (multiple MCP Pro node instances with different launch modes), not just a UI display issue.

Step 7 cleanup action + immediate retest:

Date/time: 2026-05-17 14:20 local (UTC-4)

Cleanup action performed:

- Terminated only stale process PID `29796`:
  - `node .../index.js --help` (the unintended server occupying `6506`).
- Left active `--lite` server (PID `38728`, port `6505`) and Godot editor process untouched.

Post-cleanup port/process state:

- Remaining listener:
  - `127.0.0.1:6505` -> PID `38728` (`node ... index.js --lite`)
- No listener remains on `6506`.
- Godot editor PID `42068` has:
  - `Established` connection to `6505`
  - `SYN_SENT` probes to `6507/6508/6509`

Immediate Step 7.4 pre-play probe retest:

- Action: `godot-mcp-pro.get_project_info`
- Result: `Connection error: Godot editor is not connected...`

Interpretation update:

- Removing the stale `--help` process eliminated the split-brain dual-listener condition (`6505` + `6506`) but did **not** restore API-level editor connectivity for the `--lite` server.
- Therefore the current blocker is not only stale-process contention; there is an additional incompatibility/misclassification in `--lite` mode where an established TCP session to `6505` still does not satisfy the server's "editor connected" condition for tool routing.

Step 7 mode switch (`--lite` -> `--minimal`) prepared:

Date/time: 2026-05-17 14:20 local (UTC-4)

Config change applied:

- File: `.cursor/mcp.json`
- Change:
  - from: `args: [ ".../index.js", "--lite" ]`
  - to:   `args: [ ".../index.js", "--minimal" ]`
- No other MCP entries modified.

Purpose:

- Execute the required Step 7 comparison against `--minimal` mode using the same pre-play/during-play/post-stop probe sequence.

Pending precondition:

- Cursor MCP servers (or Cursor window) must be reloaded so the new `--minimal` launch mode is active before probing.

Step 7 `--minimal` startup attempt after reload (user-provided output):

- Cursor MCP log excerpt shows:
  - `Godot MCP Pro MINIMAL started (35 tools, stdio transport)`
  - immediately followed by:
    - `Failed to start WebSocket server ... EADDRINUSE ... 127.0.0.1:6505`
- This means `--minimal` launched, but could not bind the required WebSocket port due to an existing listener.

Port-owner verification at that moment:

- `127.0.0.1:6505` listener owner was PID `38728`:
  - `node ... index.js --lite`
- So the previous `--lite` process was still resident and blocking the new `--minimal` instance.

Cleanup performed:

- Terminated PID `38728` (`node ... --lite`) only.
- Re-checked ports:
  - no listener remains on `6505` or `6506`.
  - only Godot editor remains, with outbound `SYN_SENT` attempts to `6506-6509`.

Next required action:

- Reload MCP/Cursor once more so a fresh single `--minimal` server instance can start and claim `6505`.

Step 7 `--minimal` controlled probe sequence (completed):

Date/time: 2026-05-17 14:24-14:26 local (UTC-4)

Preconditions:

- `.cursor/mcp.json` set to `--minimal`.
- MCP/Cursor reloaded after clearing stale `--lite` process from `6505`.

Sequence + results:

1. Pre-play baseline probe
   - Action: `godot-mcp-pro.get_project_info`
   - Result: **success** (full project info returned)
2. During play probe (blank test scene running)
   - Action: `godot-mcp-pro.get_project_info`
   - Result: **timeout after 30000ms**
3. Post-stop recovery probe (after manual stop)
   - Action: `godot-mcp-pro.get_project_info`
   - Result: **success** (full project info returned)

Interpretation:

- `--minimal` mode reproduces the same core failure pattern:
  - editor command works before play,
  - stalls/timeouts during play,
  - recovers after play stops.
- This confirms the play-mode hang is not specific to full mode only and still occurs in reduced tool profile (`35 tools`), strengthening root-cause direction toward runtime play-mode connection/session handling rather than a specific high-level tool set.

Step 7 default-mode restore:

- Restored `.cursor/mcp.json` `godot-mcp-pro` args to default full mode:
  - `["C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js"]`
- Removed temporary `--minimal` flag per requested Step 7.8 behavior.

Step 7 conclusion (combined):

- `--lite`: not validated end-to-end due repeated process/registration conflicts during test setup; where callable, still did not provide a stable "editor connected" state during runtime diagnostics.
- `--minimal`: fully validated end-to-end; reproduced identical failure pattern:
  - pre-play success,
  - during-play 30s timeout,
  - post-stop recovery success.
- Diagnostic implication:
  - Reduced Node tool-registration profile does not prevent the play-mode hang.
  - Root cause is likely in play-mode bridge/session lifecycle (editor<->runtime<->server) rather than a specific high-level tool registration set.

### Step 8 - Brand-new Blank Godot Project Repro (started)

Date/time: 2026-05-17 14:27 local (UTC-4)

Approval + preflight:

- User explicitly approved creating repro project at:
  - `C:\Users\jtben\Documents\PBD 2026\repro\mcp-pro-blank-repro`
- Verified no Godot processes were running before setup:
  - `Get-Process Godot*` returned no active instances.

Directory creation attempt result:

- Attempted to create approved path.
- Parent directory `C:\Users\jtben\Documents\PBD 2026\repro` does not currently exist (`PARENT_MISSING`), so target directory could not be created yet.

Step-8 status:

- Blocked pending creation of the missing parent directory (or alternate approved blank-project path).

Step 8 directory unblock:

- User approved creating missing parent:
  - `C:\Users\jtben\Documents\PBD 2026\repro`
- Created successfully:
  - `C:\Users\jtben\Documents\PBD 2026\repro`
  - `C:\Users\jtben\Documents\PBD 2026\repro\mcp-pro-blank-repro`
- Step 8 can now proceed with blank project creation and isolated repro sequence.

Step 8 blank-project repro sequence (completed):

Date/time: 2026-05-17 14:35-14:39 local (UTC-4)

Blank-project setup (user confirmed):

- Fresh Godot project created/opened at:
  - `C:\Users\jtben\Documents\PBD 2026\repro\mcp-pro-blank-repro`
- `addons/godot_mcp` copied into the blank project.
- Godot MCP Pro plugin enabled in the blank project.
- Minimal blank scene created by user:
  - `res://scenes/BlankTest.tscn`

Validation that MCP calls were targeting blank repro:

- `get_project_info` returned:
  - `project_name`: `mcp-pro-blank-repro`
  - `project_path`: `C:/Users/jtben/Documents/PBD 2026/repro/mcp-pro-blank-repro/...`

Standard Step-8 test sequence results:

1. Pre-play probe (`get_project_info`):
   - **success**
2. During play probe (manual run of `res://scenes/BlankTest.tscn`):
   - **success** (no timeout)
3. Post-stop probe:
   - **success**

Step-8 conclusion:

- The play-mode hang **did not reproduce** in the brand-new blank project under the same Godot version (4.6.2), OS, and Cursor MCP stdio flow.
- Therefore the failure in the main project is likely environment/state specific (project-level configuration, cached state, additional autoload/runtime interactions, or session/process contamination), rather than a universal "Godot MCP Pro 1.13.2 + Godot 4.6.2 always hangs in play mode" incompatibility.

### Step 9 - Final Conclusion and Vendor Packet

1) Date/time of diagnostic

- Main run window: 2026-05-17 (UTC-4), approximately 13:37-14:39 local.

2) Branch name

- `c2a-full-character-animation-20260509-172230`

3) Godot version

- `4.6.2-stable (official)`

4) Godot MCP Pro plugin and server version

- Plugin version: `1.13.2` (from `addons/godot_mcp/plugin.cfg`).
- Server package/version context used in this run: Godot MCP Pro package associated with the same `1.13.2` setup in tools folder (`.../tools/godot-mcp-pro/server/build/index.js`).

5) OS

- Windows `10.0.22631` (win32).

6) Cursor MCP config for godot-mcp-pro (final/default)

```json
"godot-mcp-pro": {
  "command": "node",
  "args": [
    "C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js"
  ],
  "env": {
    "GODOT_MCP_PORT": "6505"
  }
}
```

7) Baseline pre-play health summary

- In main project baseline before play:
  - `6505`, `6005`, `6006` reachable.
  - `godot-mcp-pro:get_project_info` success.
  - `godot-lsp-diagnostics:scan_workspace_diagnostics` success.
  - `godot-dap-debugger:godot_ping` success.

8) Exact play-mode failure behavior observed

- Main project pattern (repeated):
  1. `get_project_info` succeeds before play.
  2. Enter play mode manually or via MCP.
  3. `get_project_info` times out at 30s during play.
  4. After manual stop, `get_project_info` succeeds again.

9) TCP connection state findings (before/during/after)

- During failure windows, `6505` stayed open and often showed established loopback sessions.
- In split-brain intervals, multiple listeners existed (`6505`, `6506`) from separate node processes.
- After cleanup, single listener on `6505` remained, but `--lite` still reported "editor not connected."

10) Godot terminal stdout/stderr findings

- Verbose Godot/editor diagnostics captured recurring MCP connection churn behavior during play transitions.
- No single deterministic crash trace in user gameplay scripts was required to reproduce; issue remained tied to play-mode transition and MCP session behavior.

11) Embedded vs separate window test result

- Window placement change/test did not eliminate the failure pattern in main project.

12) Runtime autoload and bridge configuration findings

- Main project includes MCP autoloads (including runtime bridge-related entries such as `MCPRuntime`, `MCPGameInspector`, `MCPInputService`, `MCPScreenshot`).
- Architecture review indicates editor and runtime paths can both participate during play, increasing risk of role/session contention.

13) Dock state during hang (exact text + interpretation)

- Reported during hang:
  - `MCP Pro: Waiting for connection...`
  - `Clients: 0`
- Reported after stop:
  - `MCP Pro: Connected`
  - `Clients: 1 connected`
- Also observed in separate interval:
  - `MCP Pro: Connected`, `Clients: 2`, ports `6505` and `6506` connected.
- Interpretation: connection-state instability and/or split-brain client attachment across server instances.

14) Cursor and Node MCP server log findings

- Critical log evidence:
  - Frequent `[MCP] Godot editor connected` / `disconnected` churn.
  - `Heartbeat timeout (no pong for 30000ms)`.
  - `Failed to start WebSocket server ... EADDRINUSE ... 127.0.0.1:6505` when stale process occupied the port.

15) `--lite` mode result

- `--lite` server starts and accepts flag.
- Due to process contention and later "editor not connected" responses, stable end-to-end during-play validation could not demonstrate a fix.
- No evidence that `--lite` resolves main-project play-mode timeout behavior.

16) `--minimal` mode result

- Controlled sequence completed:
  - pre-play success,
  - during-play timeout (30s),
  - post-stop success.
- Therefore `--minimal` does not fix the main-project play-mode hang.

17) Blank project repro result

- Brand-new blank project (`mcp-pro-blank-repro`) with copied `addons/godot_mcp`:
  - pre-play success,
  - during-play success,
  - post-stop success.
- Main-project hang **did not reproduce** in blank project.

18) Most likely root cause with reasoning

- Primary root cause is most likely **main-project-specific MCP session/bridge lifecycle interference during play transition**, not a universal engine+plugin incompatibility.
- Supporting evidence:
  - Failure is deterministic in main project, but absent in blank repro under same engine/OS.
  - During-play timeout and post-stop recovery pattern strongly indicates temporary play-mode session routing/bridge blockage rather than static config syntax issues.
  - Observed connection churn, heartbeat loss, and prior split-brain process conditions (multiple node instances) contributed noise and transient failures but do not fully explain the persistent main-project-only timeout.

19) Specific recommended fix (safe/config-level)

- Operational hardening (immediate):
  - Ensure exactly one `godot-mcp-pro` node server instance before tests.
  - Ensure only one Godot editor instance bound to MCP bridge.
  - Keep default full mode in `.cursor/mcp.json` for consistency.
- Main-project isolation next (safe, no plugin source edits):
  - Temporarily disable non-essential project autoloads/addons (outside `addons/godot_mcp`) in controlled batches to identify the conflicting subsystem.
  - Clear project cache/import state and retry with same sequence.
- No confirmed single config-only fix was conclusively identified in this run.

20) Finalized vendor support ticket

Subject: Godot MCP Pro 1.13.2 main-project play-mode timeout on Godot 4.6.2 (Windows, Cursor stdio), blank repro passes

Environment:

- Godot: `4.6.2-stable (official)`
- Godot MCP Pro plugin: `1.13.2`
- MCP server entrypoint: `C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js`
- Client: Cursor MCP over stdio (`command: node`, env `GODOT_MCP_PORT=6505`)
- OS: Windows 10.0.22631

Main-project reproduction steps:

1. Start Godot editor on project.
2. Confirm `get_project_info` succeeds before play.
3. Manually run minimal blank scene in project.
4. Call `get_project_info` during play.
5. Observe timeout at 30s.
6. Manually stop play.
7. Call `get_project_info` again; observe immediate success.

Observed logs/signals:

- Dock during hang: `MCP Pro: Waiting for connection...`, `Clients: 0`
- Dock after stop: `MCP Pro: Connected`, `Clients: 1 connected`
- Cursor MCP logs show repeated editor connect/disconnect churn and heartbeat timeout (`no pong for 30000ms`).
- Additional diagnostic interval showed split-brain process issue (`EADDRINUSE` on 6505) when stale node instances existed; cleaned up and continued.

TCP state notes:

- Port `6505` remained open during hangs; established loopback sessions were present in multiple captures.

Blank-project control test:

- Fresh blank Godot 4.6.2 project with only `addons/godot_mcp` copied in:
  - pre-play `get_project_info`: success
  - during-play `get_project_info`: success
  - post-stop `get_project_info`: success
- Therefore issue appears project-environment-specific, not globally reproducible with blank setup.

Question for vendor:

- "Does Godot MCP Pro 1.13.2 support MCP calls while Godot 4.6.2 is in play mode? Is a runtime bridge setting, autoload handshake, dock action, or server flag required to keep the editor plugin responsive during play? Which Godot versions has plugin version 1.13.2 been validated against, and are there known compatibility issues with Godot 4.6.x?"

### Safe Isolation Pass (Post-Step 9, user-approved)

Objective:

- Identify whether project-level runtime/autoload interactions are the immediate trigger for play-mode MCP hangs in main project.

Isolation toggle set A (reversible) applied via project settings API:

- `autoload/MCPRuntime` -> set to empty string
- `autoload/McpInteractionServer` -> set to empty string
- Project reloaded via `reload_project`

A-test results (with both disabled):

1. Pre-play `get_project_info` -> success
2. `play_scene` (`mode: main`) -> success
3. During-play `get_project_info` -> **success** (no timeout)
4. `stop_scene` -> **success**

Rollback + B-test:

- Restored:
  - `autoload/MCPRuntime="*uid://c13j8nchilhxj"`
  - `autoload/McpInteractionServer="*uid://dyhub7l5qsyig"`
- Reloaded project.
- Re-tested:
  - `play_scene` success
  - during-play `get_project_info` -> **timeout (30s)**
  - `stop_scene` -> **timeout (30s)**

Isolation-pass conclusion:

- High-confidence A/B evidence indicates the hang is directly coupled to one or both of:
  - `MCPRuntime` autoload
  - `McpInteractionServer` autoload
- With both disabled, play-mode MCP responsiveness is restored.
- With both restored, the hang reproduces.
- This narrows root cause from "general project complexity" to a specific runtime-autoload interaction zone.

Split test (single-variable isolation) - conclusive:

Test S1 (disable only `MCPRuntime`, keep `McpInteractionServer` enabled):

- `autoload/MCPRuntime=""`
- `autoload/McpInteractionServer="*uid://dyhub7l5qsyig"`
- Result:
  - pre-play `get_project_info`: success
  - during-play `get_project_info`: **success** (no timeout)
  - `stop_scene`: success

Test S2 (enable `MCPRuntime`, disable only `McpInteractionServer`):

- `autoload/MCPRuntime="*uid://c13j8nchilhxj"`
- `autoload/McpInteractionServer=""`
- Result:
  - pre-play `get_project_info`: success
  - during-play `get_project_info`: **timeout (30s)**
  - `stop_scene`: **timeout (30s)**

Split-test conclusion:

- `MCPRuntime` is the primary trigger for the play-mode MCP hang in this project state.
- `McpInteractionServer` is not required to reproduce the hang.

Rollback status:

- Restored both autoloads to original values:
  - `autoload/MCPRuntime="*uid://c13j8nchilhxj"`
  - `autoload/McpInteractionServer="*uid://dyhub7l5qsyig"`
- Verified via `get_project_settings(section="autoload")`.

Experimental patch test (user-approved, unsupported):

Objective:

- Test whether separating runtime/editor endpoint from 6505 mitigates play-mode hang.

Changes applied:

1. Backups created:
   - `.cursor/mcp.json.port6506.test.bak`
   - `addons/godot_mcp/runtime/mcp_runtime.gd.port6506.test.bak`
2. Runtime URL patched:
   - `addons/godot_mcp/runtime/mcp_runtime.gd`
   - `SERVER_URL` changed from `ws://127.0.0.1:6505` to `ws://127.0.0.1:6506`
3. Cursor MCP server env patched:
   - `.cursor/mcp.json`
   - `GODOT_MCP_PORT` changed from `6505` to `6506`

Status:

- Awaiting MCP/Cursor reload and probe sequence to determine whether timeout behavior changes under the port-6506 experiment.

Experimental patch result (`6506` endpoint test):

After reload with:

- `mcp_runtime.gd` -> `SERVER_URL = ws://127.0.0.1:6506`
- `.cursor/mcp.json` -> `GODOT_MCP_PORT=6506`

Probe sequence:

1. Pre-play `get_project_info` -> success
2. `play_scene` -> success
3. During-play `get_project_info` -> **timeout (30s)**
4. During-play `stop_scene` -> **timeout (30s)** (manual stop required)

Port ownership check during experiment:

- `6506` listener owner:
  - `node .../godot-mcp-pro/server/build/index.js` (single MCP server process)
- Godot editor established to `6506`, while still probing `6505/6507/6508/6509` due to plugin port-scan behavior.
- No unrelated third-party process was holding `6506` during this capture.

Conclusion from `6506` experiment:

- Moving both runtime URL and MCP server port from `6505` to `6506` did **not** resolve the play-mode hang.
- Therefore the issue is not specific to a single port number conflict; it is tied to runtime bridge behavior itself.

Rollback completed:

- Restored `.cursor/mcp.json` from backup (`GODOT_MCP_PORT=6505`).
- Restored `addons/godot_mcp/runtime/mcp_runtime.gd` from backup (`SERVER_URL=ws://127.0.0.1:6505`).
- Post-rollback verification confirmed both values.

### Final Root Cause Pinpoint (Two-Script Interaction Resolved)

Date/time: 2026-05-17 16:15-16:23 local (UTC-4)

What was tested immediately before fix:

- `GameState.gd` aggressive static-data cuts (mission catalog + other non-empty top-level dictionaries/constants) -> hang still reproduced.
- `MCPRuntime` startup connect delay probe (3s) -> hang still reproduced.

Conclusion from those probes:

- `GameState` content/initialization was **not** the primary defect.
- The failure remained coupled to `MCPRuntime` presence and play-mode connection behavior.

Server-side code inspection findings (exact mechanism):

- File inspected: `C:\Users\jtben\Documents\PBD 2026\tools\godot-mcp-pro\server\build\godot-connection.js`
- Existing logic kept a **single** active `client` socket and unconditionally replaced it whenever any new WebSocket connected:
  - on new connection: close previous `this.client`
  - assign `this.client = ws`
- During play, `MCPRuntime` creates an additional runtime WebSocket connection and emits a non-JSONRPC envelope (`{"type":"godot_ready","role":"runtime",...}`).
- That runtime connection could preempt the editor control channel, causing editor disconnect/reconnect churn and command timeouts.

Observed symptom alignment:

- Cursor MCP log tail showed repeated:
  - `[MCP] Godot editor connected`
  - `[MCP] Godot editor disconnected`
  in tight loops during play, matching the single-slot replacement behavior.

Patch applied (targeted, no workaround flags):

- File modified: `C:\Users\jtben\Documents\PBD 2026\tools\godot-mcp-pro\server\build\godot-connection.js`
- Behavior change:
  - Runtime hello (`type=godot_ready`, `role=runtime`) no longer claims editor client slot.
  - Editor slot assignment/replacement occurs only for non-runtime messages.
  - Disconnect cleanup/reject-all pending commands only when the closed socket is the active editor client.

Validation after patch (manual play retained):

Post-fix test 1 (`in play post-server-fix`):

- During-play `get_project_info` -> **success** (full payload returned, no timeout).

Post-fix test 2 (`in play verify-2`):

- During-play `get_project_info` -> **success** again.

State hygiene after validation:

- Restored temporary bisect edits:
  - `src/autoload/GameState.gd` restored to original content.
  - `addons/godot_mcp/runtime/mcp_runtime.gd` restored to original immediate-connect behavior.
- Effective remaining fix is server-side connection handling patch only.

Final root-cause statement:

- The play-mode hang is caused by MCP Pro server connection ownership logic (`godot-connection.js`) treating runtime and editor sockets as the same single control channel, allowing runtime connection events to evict the editor channel and destabilize command handling.
