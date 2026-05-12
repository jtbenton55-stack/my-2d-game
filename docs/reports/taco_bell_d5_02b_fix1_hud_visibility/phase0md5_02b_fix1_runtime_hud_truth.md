# Phase 2 — Runtime HUD truth

## Tooling

- **`grb_ping` (MCP Godot Runtime Bridge)**: returned **“Bridge not connected. Launch the game first.”**
- Therefore **no live scene tree**, **no node property snapshot**, and **no in-engine CanvasLayer enumeration** were captured in this environment.

## What could not be verified here

- Current scene path after navigation from Hideout → MissionBoard → Taco.
- Live `HUD` node path, `visible`, `layer`, `process_mode`, control sizes, overlap geometry.
- Live `GameState.is_in_mission`, `QuestManager` objective string, sprint debug payload, poop count.

## Static inference (non-PASS evidence)

From Phase 1 static wiring and code review **before** this pass’s code edits:

- Taco embeds `hud.tscn`; `LevelBase` ensures UI ordering for dynamic spawns.
- Debug overlays default **hidden** in `_ready` for Phase0J, IsoMissionDebugPanel, and sprint overlay.
- Prior narrative error: **HUD layer 40 is not “above” layer 90** in Godot; **higher layer wins**.

## Assertions

See `phase0md5_02b_fix1_runtime_hud_truth.json` — required booleans **true** with explicit **unknown** runtime fields.
