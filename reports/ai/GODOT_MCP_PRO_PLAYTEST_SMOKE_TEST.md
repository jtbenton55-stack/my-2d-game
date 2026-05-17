# GODOT MCP Pro Playtest Smoke Test

## Date/Time
- 2026-05-17 11:39 (local)

## 1) Git status
- `git status --short` returned a non-clean working tree with existing prior setup changes.

## 2) Launch result
- Attempted launch via Godot MCP Pro `play_scene`.
- Result: **success** response from MCP:
  - `{"mode":"main","playing":true}`
- Interpretation: game/main scene launch request was accepted.

## 3) Console output/errors
- Initial `get_output_log` call succeeded right after launch with:
  - count: 1
  - lines: [""]
- Subsequent `get_output_log` calls timed out.

## 4) Screenshot capture result
- `get_game_screenshot` attempted multiple times.
- Result: **timed out** (30s timeout each attempt).
- No screenshot artifact was returned by MCP in this run.

## 5) Input simulation result
- Intended tiny input check: one short movement key press.
- `simulate_key` call failed validation because required `keycode` argument was not accepted through the available MCP call interface in this session.
- Result: **not executed**.

## 6) Stop scene / clean shutdown result
- `stop_scene` attempted multiple times.
- Result: **timed out**.
- Clean stop via MCP could not be confirmed in this run.

## 7) Connectivity snapshot during failures
- `Test-NetConnection` still showed:
  - 6505: True
  - 6005: True
  - 6006: True
- MCP calls nevertheless timed out after launch for runtime operations.

## 8) Risks before real debugging
- Runtime MCP operations are currently unstable/intermittent (timeouts after successful launch).
- Screenshot + stop controls are not reliable in this state.
- Do not rely on this setup yet for long debugging sessions until runtime MCP responsiveness is stable.
- Recommended before real debugging:
  1. Restart Godot editor.
  2. Restart Cursor MCP servers.
  3. Re-run a minimal runtime check (`play_scene` -> `get_game_screenshot` -> `stop_scene`).
  4. If timeouts persist, inspect Godot Output panel for MCP/WebSocket/runtime plugin errors.
