## Godot MCP Pro Play-Mode Bisection Results

Date/time: 2026-05-17 15:17 local (UTC-4)

Methodology:

- Reversible `project.godot` bisection only.
- No edits under `res://addons/godot_mcp/`.
- No gameplay script edits.
- Backup first, restore at end of each action unless explicitly requested otherwise.
- Standard probe sequence for each iteration:
  1. pre-play `get_project_info`
  2. manual play start (`res://scenes/testing/McpRuntimeBlankTest.tscn`)
  3. during-play `get_project_info`
  4. manual stop
  5. post-stop `get_project_info`

## Action 1 - Preflight and Baseline Start

Backup:

- Created: `project.godot.bisect.bak`

Process checks:

- `Get-Process Godot*` returned:
  - Godot editor process (`Godot_v4.6.2-stable_win64.exe`)
  - `godot-dap-mcp-server.exe` (matches `Godot*` pattern by name but is not a Godot editor instance)
- `Get-CimInstance Win32_Process` filter for `*godot-mcp-pro*` node command line returned no active dedicated `godot-mcp-pro` node process at preflight moment.

Current blocker:

- MCP tool calls failed with:
  - `MCP server does not exist: project-0-my-2d-game-godot-mcp-pro`
- Available servers currently:
  - `project-0-my-2d-game-godot-dap-debugger`
  - `project-0-my-2d-game-godot-lsp-diagnostics`
  - `project-0-my-2d-game-siliconflow-kimi-k2-6`
  - plugin servers (`context7`, `vercel`)

Action 1 status:

- Cannot run baseline probe sequence until `godot-mcp-pro` MCP server is visible again in Cursor.
- No bisection edits were applied to `project.godot` yet.

Action 1 continuation - baseline reproduced with full current state:

Autoload categorization from live project settings:

- MCP autoloads (untouched for bisection toggles except `MCPRuntime` always kept enabled during this phase):
  - `autoload/MCPGameInspector`
  - `autoload/MCPInputService`
  - `autoload/MCPScreenshot`
  - `autoload/MCPRuntime`
- Suspect autoloads to bisect:
  - `autoload/GameState`
  - `autoload/SaveManager`
  - `autoload/AudioManager`
  - `autoload/SceneManager`
  - `autoload/DialogueManager`
  - `autoload/QuestManager`
  - `autoload/CardManager`
  - `autoload/CardEffects`
  - `autoload/EventBus`
  - `autoload/CollectibleManager`
  - `autoload/GRBServer`
  - `autoload/McpInteractionServer`

Baseline standard probe sequence (no bisection edits yet):

1. Pre-play `get_project_info`:
   - success
2. Manual play start (`res://scenes/testing/McpRuntimeBlankTest.tscn`):
   - user confirmed in-play
3. During-play `get_project_info`:
   - **timeout after 30000ms**
4. Manual stop:
   - user confirmed stopped
5. Post-stop `get_project_info`:
   - success

Action 1 baseline conclusion:

- Hang is confirmed in the current full main-project state.
- Bisection can proceed.

Action 1 - Iteration A1 (disable first half of suspects)

Approved disabled autoloads:

- `autoload/GameState=""`
- `autoload/SaveManager=""`
- `autoload/AudioManager=""`
- `autoload/SceneManager=""`
- `autoload/DialogueManager=""`
- `autoload/QuestManager=""`

Kept enabled for this iteration:

- `autoload/CardManager`
- `autoload/CardEffects`
- `autoload/EventBus`
- `autoload/CollectibleManager`
- `autoload/GRBServer`
- `autoload/McpInteractionServer`
- all MCP autoloads including `MCPRuntime`

Probe sequence result:

1. Pre-play `get_project_info` -> success
2. Manual play start (user confirmed)
3. During-play `get_project_info` -> **success** (no timeout)
4. Manual stop (user confirmed)
5. Post-stop `get_project_info` -> success

Iteration A1 conclusion:

- Hang disappeared when first-half suspects were disabled.
- Co-trigger is inside this disabled half:
  - `GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `DialogueManager`, or `QuestManager`.

Action 1 - Iteration A2 (re-enable subset: GameState/SaveManager/AudioManager)

A2 state:

- Enabled:
  - `autoload/GameState="*res://src/autoload/GameState.gd"`
  - `autoload/SaveManager="*res://src/autoload/SaveManager.gd"`
  - `autoload/AudioManager="*res://src/autoload/AudioManager.gd"`
- Kept disabled:
  - `autoload/SceneManager=""`
  - `autoload/DialogueManager=""`
  - `autoload/QuestManager=""`
- MCP autoloads unchanged (including `MCPRuntime` enabled).

Probe sequence result:

1. Pre-play `get_project_info` -> success
2. Manual play start (user confirmed)
3. During-play `get_project_info` -> **timeout after 30000ms**
4. Manual stop (user confirmed)
5. Post-stop `get_project_info` -> success

Iteration A2 conclusion:

- Hang is present in A2.
- Co-trigger narrows to:
  - `GameState` OR `SaveManager` OR `AudioManager`

Action 1 - Iteration A3 (disable AudioManager; keep GameState+SaveManager)

A3 state:

- Enabled:
  - `autoload/GameState="*res://src/autoload/GameState.gd"`
  - `autoload/SaveManager="*res://src/autoload/SaveManager.gd"`
- Disabled:
  - `autoload/AudioManager=""`
  - `autoload/SceneManager=""`
  - `autoload/DialogueManager=""`
  - `autoload/QuestManager=""`
- MCP autoloads unchanged (including `MCPRuntime` enabled).

Probe sequence result:

1. Pre-play `get_project_info` -> success
2. Manual play start (user confirmed)
3. During-play `get_project_info` -> **timeout after 30000ms**
4. Manual stop (user confirmed)
5. Post-stop `get_project_info` -> success

Iteration A3 conclusion:

- Hang persists with `AudioManager` disabled.
- `AudioManager` is not required as co-trigger.
- Co-trigger narrows to:
  - `GameState` OR `SaveManager`

Action 1 - Iteration A4 (keep GameState enabled, disable SaveManager)

A4 state:

- Enabled:
  - `autoload/GameState="*res://src/autoload/GameState.gd"`
- Disabled:
  - `autoload/SaveManager=""`
  - `autoload/AudioManager=""`
  - `autoload/SceneManager=""`
  - `autoload/DialogueManager=""`
  - `autoload/QuestManager=""`
- MCP autoloads unchanged (including `MCPRuntime` enabled).

Probe sequence result:

1. Pre-play `get_project_info` -> success
2. Manual play start (user confirmed)
3. During-play `get_project_info` -> **timeout after 30000ms**
4. Manual stop (user confirmed)
5. Post-stop `get_project_info` -> success

Iteration A4 conclusion:

- Hang persists with `GameState` enabled and `SaveManager` disabled.
- `GameState` is sufficient (in this reduced set) to co-trigger the hang with `MCPRuntime`.

Action 1 - Iteration A5 (disable GameState, enable SaveManager)

A5 state:

- Enabled:
  - `autoload/SaveManager="*res://src/autoload/SaveManager.gd"`
- Disabled:
  - `autoload/GameState=""`
  - `autoload/AudioManager=""`
  - `autoload/SceneManager=""`
  - `autoload/DialogueManager=""`
  - `autoload/QuestManager=""`
- MCP autoloads unchanged (including `MCPRuntime` enabled).

Probe sequence result:

1. Pre-play `get_project_info` -> success
2. Manual play start (user confirmed)
3. During-play `get_project_info` -> **success** (no timeout)
4. Manual stop (user confirmed)
5. Post-stop `get_project_info` -> success

Iteration A5 conclusion:

- With `GameState` disabled, hang does not reproduce in this reduced set.
- `SaveManager` alone is not sufficient as co-trigger.

## Action 1 Final Result

Identified co-trigger autoload:

- `GameState` (when combined with `MCPRuntime`).

Evidence summary:

- `MCPRuntime` is required trigger (from earlier split tests).
- In current autoload bisection:
  - `GameState` enabled + `MCPRuntime` enabled -> hang reproduced (A4).
  - `GameState` disabled + `MCPRuntime` enabled + `SaveManager` enabled -> hang did not reproduce (A5).

Therefore, current minimal co-trigger in main project context is:

- `MCPRuntime` + `GameState`

## GameState Internal Bisection

Preconditions for internal cuts:

- Autoload set pinned to reproducing subset:
  - enabled: `GameState`, `MCPRuntime` (+ MCP plugin autoloads, Card/EventBus/Collectible/GRB/McpInteractionServer)
  - disabled: `SaveManager`, `AudioManager`, `SceneManager`, `DialogueManager`, `QuestManager`
- `GameState.gd` backup created:
  - `src/autoload/GameState.gd.bisect.bak`

G0 cut - `_ready()` no-op:

- Edited `GameState._ready()` to:
  - `pass`
- This removes:
  - `reset_for_new_game(false)`
  - `EventBus.debug("GameState ready")`

G0 probe result:

1. Pre-play `get_project_info` -> success
2. Manual play start (user confirmed: "in play G0")
3. During-play `get_project_info` -> **timeout after 30000ms**
4. Manual stop (user confirmed: "stopped G0")

G0 conclusion:

- `_ready()` startup lines are not the primary trigger.
- Trigger likely occurs from other GameState behavior or interactions that remain active when script is loaded.

G1 cut (GameState autoload swapped to stub script) - invalid due script-API break:

- Temporary autoload target:
  - `autoload/GameState="*res://src/autoload/GameState_McpBisectStub.gd"`
- During-play probe succeeded, but this cut produced dependent compile/runtime errors (e.g., `CollectibleManager.gd` expecting `GameState.normalize_polaroid_id` and related members).
- Therefore G1 result is treated as **non-comparable** for root-cause isolation.

Follow-up clean check (real `GameState.gd` restored, reduced autoload set retained):

- `autoload/GameState` restored to real script.
- Quick MCP-driven probe (`play_scene` main -> during-play `get_project_info`) returned success in that specific run.
- This conflicts with earlier manual `McpRuntimeBlankTest.tscn` timeout results under nearby configs and indicates scene/timing sensitivity remains.
- Next step required: rerun the standard manual `McpRuntimeBlankTest.tscn` sequence under the current exact autoload state to keep comparisons valid.

Strict rerun (manual `McpRuntimeBlankTest.tscn`, fixed reduced autoload config):

Config locked:

- `GameState` enabled (real script)
- `MCPRuntime` enabled
- Disabled: `SaveManager`, `AudioManager`, `SceneManager`, `DialogueManager`, `QuestManager`

Run strict-1:

1. Pre-play `get_project_info` -> success
2. Manual play start (`McpRuntimeBlankTest.tscn`) -> user confirmed
3. During-play `get_project_info` -> **timeout (30s)**
4. Manual stop -> user confirmed
5. Post-stop `get_project_info` -> success

Run strict-2 (same config, repeat):

1. Manual play start (`McpRuntimeBlankTest.tscn`) -> user confirmed
2. During-play `get_project_info` -> **timeout (30s)**
3. Manual stop -> user confirmed
4. Post-stop `get_project_info` -> success

Strict rerun conclusion:

- Timeout is repeatable in fixed reduced config with real `GameState`.
- The earlier one-off success was transient and not representative.

Additional control (McpInteractionServer off):

- Disabled only `autoload/McpInteractionServer` under same reduced config.
- During-play `get_project_info` still **timed out (30s)**.
- Therefore `McpInteractionServer` is not the primary co-trigger in this reduced set.
