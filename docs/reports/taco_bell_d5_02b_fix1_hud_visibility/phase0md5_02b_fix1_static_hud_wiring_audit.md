# Phase 1 — Static HUD wiring audit

## 1. How `hud.tscn` is instanced

- **Levels using `LevelBase._ensure_common_ui()`**: If `HUD` child is missing, `preload(res://scenes/ui/hud.tscn)` is instantiated and `add_child` to the level root.
- **Taco `TacoBellIso_Editable_RedesignTest.tscn`**: Contains an instanced `HUD` node (`instance=ExtResource(... hud.tscn)`) as a direct child of the mission root (read-only confirmation from prior audits; scene file exists).

## 2. `LevelBase` and `_ensure_common_ui()`

`LevelBase._ready()` calls `_ensure_common_ui()` **before** `QuestManager.set_objective(...)` so dynamically spawned HUD exists before the first `objective_updated` emit.

## 3. Taco RedesignTest path

Uses `IsoMissionBase` → `LevelBase`; common UI path applies for HUD spawn when absent; Taco embeds HUD anyway.

## 4. `QuestManager.set_objective` vs HUD existence

Mitigated for dynamic HUD: `_ensure_common_ui()` runs first. For embedded HUD, `_ready` order still means HUD may run before `GameState.start_mission`; deferred refresh + signals cover that.

## 5–7. `hud.tscn` root / strip

- Root: **CanvasLayer**, **`layer = 50`** (player-facing band 40–80 per policy).
- **`MissionHudStrip`** present with stamina + poop + optional control hint.
- **`HUD.gd`**: `process_mode = PROCESS_MODE_ALWAYS` on the HUD root.

## 8–10. Paths / visibility

`@onready` paths match `hud.tscn`. Health/detection/style bars are direct children of the CanvasLayer (not inside `MissionHudStrip`). `MissionHudStrip` default visible in scene; runtime toggles via `GameState.is_in_mission`.

## 11. `GameState.is_in_mission` gating

`_refresh_mission_compact_hud()` sets `_mission_strip.visible = in_mission` and clears objective when not in mission.

## 12. `MissionHudDataProvider`

Resolves `GameState` via `MissionAutoloadResolver`; reads `QuestManager.get_current_objective(mid)`; stamina from `get_sprint_runtime_debug` on `player` group; poop from `GameState.get_poop_bag_count()`.

## 13–15. Debug / hotkeys (static)

- **Phase0JDebugHUD**: `_ready` ends with `hide()`; `force_playfield_hidden` default true.
- **IsoMissionDebugPanel**: `visible = false` in `_ready`; F10 toggles.
- **Pause**: CanvasLayer **120**; **F11 overlay** moved to **110** in this pass so it sits in debug tier **below pause** and **above HUD 50**.

## CanvasLayer ordering (Godot truth)

**Larger `layer` values draw on top of smaller values.** Therefore HUD **50** is **below** Phase0J **90** and IsoMissionDebugPanel **100** when those are visible. Preferred mitigation: **keep debug hidden by default** (already the case in scripts audited).

## Assertions

See `phase0md5_02b_fix1_static_hud_wiring_audit.json`.
