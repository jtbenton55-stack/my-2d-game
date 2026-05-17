## Godot MCP Pro Runtime Recovery Sequence Report

Date/time: 2026-05-17 (UTC-4)

Branch: `c2a-full-character-animation-20260509-172230`

### 1) Baseline health
- `git status --short`: dirty working tree (pre-existing setup changes).
- `.cursor/mcp.json`: valid JSON.
- Ports healthy at baseline:
  - `6505` open
  - `6005` open
  - `6006` open
- Baseline MCP checks:
  - `godot-mcp-pro:get_project_info` -> success
  - `godot-lsp-diagnostics:scan_workspace_diagnostics` -> success
  - `godot-dap-debugger:godot_ping` -> success (`pong`)

### 2) Godot MCP Pro version
- Plugin version from `addons/godot_mcp/plugin.cfg`: **1.13.2**
- Server package version from `tools/godot-mcp-pro/server/package.json`: **1.13.2**

### 3) Godot version
- From `get_project_info`: **4.6.2-stable (official)**.

### 4) Cursor MCP config for godot-mcp-pro
- Command: `node`
- Entrypoint: `C:/Users/jtben/Documents/PBD 2026/tools/godot-mcp-pro/server/build/index.js`
- Env: `GODOT_MCP_PORT=6505`

### 5) Mode active (full/lite/minimal)
- Active mode appears **full/default**:
  - No `--minimal`, `--lite`, or `--3d` args present in `.cursor/mcp.json`.
  - `build/index.js` supports these flags but none are currently used.

### 6) Sequence A result
Steps executed:
1. Stop play mode (already stopped).
2. Godot open + MCP Pro dock visible.
3. `get_project_info` before play -> **success**.
4. Manual run of `scenes/testing/McpRuntimeBlankTest.tscn`.
5. `get_project_info` while running -> **timeout (30s)**.
6. Manual stop.
7. `get_project_info` after stop -> **success**.

Result: **failed during play**, recovers after stop.

### 7) Sequence B result
Steps executed:
1. Manual disable plugin.
2. Manual re-enable plugin.
3. Wait for MCP Pro dock status.
4. `get_project_info` before play -> **success**.
5. Manual run blank scene.
6. `get_project_info` while running -> **timeout (30s)**.
7. Manual stop.
8. `get_project_info` after stop -> **success**.

Result: plugin toggle **did not** restore in-play responsiveness.

### 8) Sequence C result
Steps executed:
1. Manual Cursor window reload / MCP server restart.
2. Reconnect check:
   - ports `6505/6005/6006` open
   - `get_project_info`, diagnostics, and dap ping all healthy pre-play
3. Manual run blank scene (user also observed dock message: “waiting to connect”).
4. In-play `get_project_info` probe -> **timeout (30s)**.
5. Port `6505` still open while timed out.
6. Manual stop.
7. `get_project_info` after stop -> **success**.

Result: Cursor/MCP restart **did not** restore in-play responsiveness.

### 9) Any sequence that allowed get_project_info during play mode?
- **No**. A, B, and C all timed out during play mode.

### 10) Responsiveness after stopping play mode
- **Yes**. In every sequence, responsiveness returned after manual stop.

### 11) Independent of scene content?
- **Yes** based on this recovery run and prior isolation:
  - Failure reproduces on minimal blank scene, not just main scene.

### 12) Mode-test safety (Phase 4)
- Server supports launch flags:
  - `--minimal`
  - `--lite`
  - `--3d` (variant mode)
- No safe evidence yet that mode switch will fix the bridge issue; however, testing `--lite` or `--minimal` is a reasonable next configuration experiment because it reduces registered tool surface and runtime command path complexity.
- No config change was applied in this run.

### 13) Recommended next action
1. **Primary**: open a plugin author support ticket (high confidence reproducible bug).
2. **Secondary config test** (with your approval): temporary `--lite` then `--minimal` mode tests in `.cursor/mcp.json`, each with the same one-call in-play probe.
3. **Validation control**: reproduce once in a fresh clean blank Godot project to separate project-specific plugin interaction from general plugin regression.

### 14) Support-ready bug summary (paste this)
Godot MCP Pro runtime reliability issue on Godot 4.6.2-stable with MCP Pro 1.13.2.

Environment:
- MCP server launched via Cursor stdio using `node build/index.js` (default/full mode), `GODOT_MCP_PORT=6505`.
- Port 6505 remains open throughout failures.
- LSP (6005) and DAP (6006) remain healthy.

Repro:
1. Confirm `get_project_info` works while not playing.
2. Run any scene (reproduces on minimal blank scene, not just project main).
3. Call `get_project_info` during play.
4. Call times out at 30s.
5. Stop scene manually in Godot.
6. `get_project_info` works again immediately.

Observed:
- Same timeout behavior after plugin disable/re-enable and after Cursor/MCP restart.
- MCP Pro dock can show “waiting to connect” during in-play failure.
- Issue appears tied to play-mode bridge lifecycle, not scene content.
