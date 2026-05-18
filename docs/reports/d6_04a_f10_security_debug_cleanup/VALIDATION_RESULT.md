# D6-04A Validation Result

## Static validator

**Command:** `python src/tools/editor/d6_04a_f10_security_debug_cleanup/phase0md6_04a_static_validator.py`

**Result:** PASS

**Artifact:** `docs/reports/d6_04a_f10_security_debug_cleanup/phase0md6_04a_static_validator_run.json`

**Warnings (pre-existing dirty tree, not introduced by D6-04A):**

- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/enemies/Guard.gd`

## Godot LSP diagnostics

**File:** `src/missions/iso/runtime/IsoMissionDebugPanel.gd`

**Result:** No diagnostics reported.

## Godot MCP Pro — validate_script

**Result:** Reported parse error (error_code 43) after reload; likely stale editor validator state.

**Runtime:** Scene played successfully; `execute_game_script` refreshed F10 and confirmed new sections render.

## Godot MCP Pro — runtime F10 check

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

**Script probe results:**

| Check | Result |
|-------|--------|
| `--- Security Authoring ---` present | yes |
| Manual test help line | yes |
| FIX7 clutter (`fix7f_chosen_x`) in text | no |

**Sample preview (idle mission start):**

```
--- Mission ---
Mission: taco_bell_drop  Heat: 0  Alert: normal  Code: 9021

--- Security Authoring ---
Root: yes  beams 2  cameras 1  spawns 2  patrols 1  areas 1

--- Event Router ---
Router: yes | events 2 | ambush_beam_tripped(1), test_camera_alarm(1)
...

Manual test: cross AMBUSH beam -> one guard; enter authored camera cone -> camera alarm + one guard.
```

## Screenshot

**Path:** `user://d6_04a_f10_security_debug_cleanup.png` (960×540, captured with compact HUD forced visible via runtime script)

On Windows, typically under Godot app user data for this project (e.g. `%APPDATA%\Godot\app_userdata\<project_name>\`).

## GdUnit4

No relevant tests found for `IsoMissionDebugPanel` / F10 security sections.

## Godot DAP debugger

Not used — runtime script probe sufficient.

## Kimi K2.6

Not used.
