# OPENCODE_CONFIG_FIX_AND_NOWLEDGE_PLUGIN_REPORT

## 1) Date/time

- Date: 2026-05-17
- Local time window: ~18:03-18:05 (UTC-4)

## 2) Branch

- `c2a-full-character-animation-20260509-172230`

## 3) Git status before/after

### Before this task

```text
AM .gitattributes
M  .gitignore
 M AGENTS.md
?? docs/NOWLEDGE_MEM_SETUP.md
?? docs/OPENCODE_PLANNING_PROMPT.md
?? reports/ai/NMEM_CLI_INSTALL_REPORT.md
?? reports/ai/NOWLEDGE_MEM_OPENCODE_WINDOWS_SETUP_FINAL_REPORT.md
?? reports/ai/NOWLEDGE_MEM_OPENCODE_WINDOWS_SETUP_REPORT.md
?? scenes/testing/
?? scripts/ai/
?? src/autoload/GameState.gd.bisect.bak
?? src/autoload/GameState_McpBisectShim.gd
?? src/autoload/GameState_McpBisectShim.gd.uid
?? src/autoload/GameState_McpBisectStub.gd
?? src/autoload/GameState_McpBisectStub.gd.uid
?? tests/
```

### After this task

```text
AM .gitattributes
M  .gitignore
 M AGENTS.md
 M opencode.json
?? docs/NOWLEDGE_MEM_SETUP.md
?? docs/OPENCODE_PLANNING_PROMPT.md
?? reports/ai/NMEM_CLI_INSTALL_REPORT.md
?? reports/ai/NOWLEDGE_MEM_OPENCODE_WINDOWS_SETUP_FINAL_REPORT.md
?? reports/ai/NOWLEDGE_MEM_OPENCODE_WINDOWS_SETUP_REPORT.md
?? scenes/testing/
?? scripts/ai/
?? src/autoload/GameState.gd.bisect.bak
?? src/autoload/GameState_McpBisectShim.gd
?? src/autoload/GameState_McpBisectShim.gd.uid
?? src/autoload/GameState_McpBisectStub.gd
?? src/autoload/GameState_McpBisectStub.gd.uid
?? tests/
```

## 4) Invalid `opencode.json` keys found

Original top-level invalid keys:

- `policies`
- `intendedUse`
- `notes`

These caused:

`Configuration is invalid ... Unrecognized keys: policies, intendedUse, notes`

## 5) What changed in `opencode.json`

### Backup created first

Created timestamped backup folder:

`reports/ai/setup-backups/opencode-config-fix-20260517-180440/`

Backed up existing files:

- `opencode.json`
- `AGENTS.md`
- `docs/NOWLEDGE_MEM_SETUP.md`
- `docs/OPENCODE_PLANNING_PROMPT.md`

### Config fix applied

- Removed unsupported top-level keys from `opencode.json`.
- Replaced with minimal safe config:

```json
{
  "$schema": "https://opencode.ai/config.json"
}
```

Validation:

- `opencode debug config` succeeded and returned parsed config.
- Additional JSON parse check confirmed valid syntax.

## 6) Where planning notes were moved

Moved/retained policy/intention text in docs (not in OpenCode JSON):

- `docs/OPENCODE_PLANNING_PROMPT.md`
  - Added default planning/review-only mode note.
  - Added intended planning/review scope (architecture, prompt generation, diff/risk review, handoffs).
  - Added coordination note (AGENTS.md, reports/ai, Nowledge Mem, copied prompts).

- `docs/NOWLEDGE_MEM_SETUP.md`
  - Updated plugin status.
  - Added exact terminal launch steps for OpenCode.
  - Added coordination guidance with AGENTS.md/reports/Nowledge Mem/prompts.

## 7) OpenCode version

- `opencode --version` -> `1.15.4`
- `where.exe opencode` ->
  - `C:\Users\jtben\AppData\Roaming\npm\opencode`
  - `C:\Users\jtben\AppData\Roaming\npm\opencode.cmd`

## 8) nmem status

- `nmem status` ->
  - CLI `v0.8.6`
  - Server `v0.8.6`
  - `status ok`
  - database connected
  - search ready
  - agent running

- `where.exe nmem` ->
  - `C:\Users\jtben\AppData\Local\Nowledge Mem\cli\nmem.cmd` (preferred, first)
  - Python scripts fallback `nmem.exe`

## 9) Plugin install result

Command:

`opencode plugin opencode-nowledge-mem -g`

Result:

- **Success**
- Installed globally and added to:
  - `C:\Users\jtben\.config\opencode\opencode.jsonc`
- Output ended with:
  - `Installed opencode-nowledge-mem`
  - `Done`

## 10) Memory search result

Commands run:

- `nmem m search "Godot AI tooling architecture"`
- `nmem m search "Godot MCP Pro runtime validation lesson"`

Result:

- Both memories present (2 matches shown each, including the expected titled records).
- No duplicate add performed in this run.

## 11) Manual validation step

Open a new Cursor terminal, run:

```powershell
cd "C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game"
opencode
```

Then ask OpenCode:

`What was I working on recently?`
