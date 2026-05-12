# 0M-D5-02A — Phase 4: Hygiene changes implemented

## Summary

Reduced **default on-screen debug clutter**, added **bounded scrollable text** to pause and controls overlay, and tightened **Iso** debug panels — **no gameplay logic** changes.

## Files modified

1. `src/missions/iso/runtime/Phase0JDebugHUD.gd` — `visible_by_default` false; startup toast no longer forces `visible`; panel text block wrapped in **ScrollContainer**; labels autowrap + expand.
2. `src/missions/iso/runtime/IsoMissionDebugPanel.gd` — **hidden by default** (F10 shows); compact status in **ScrollContainer**; `_fit_compact_status_height` for label height; larger compact panel clip.
3. `src/player/PlayerSprintDebugOverlay.gd` — **hidden by default**; **F11** toggles; **ScrollContainer + RichTextLabel** bounded box; no `project.godot` action.
4. `src/hideout/HideoutDebugController.gd` — walks ancestors to find `DebugHideout*` root and sets **`visible = false`** after wiring buttons (scene unmodified).
5. `src/ui/test_ui/pause_menu.gd` — info area uses **ScrollContainer + RichTextLabel** + `_fit_pause_info_scroll`.
6. `src/ui/test_ui/controls_overlay.gd` + `controls_overlay.tscn` — **ScrollContainer + RichTextLabel**, panel `clip_contents`, deferred height fit.

## Not done (deferred)

- Duplicate `src/ui/PauseMenu.gd` vs `test_ui/pause_menu.gd` consolidation.
- World-space `Debug_*` marker reduction.
- Dialogue / scheme / storefront overflow passes.

## Gameplay / forbidden files

- **Not modified:** `Player.gd`, `PlayerStaminaController.gd`, `IsoMissionBase.gd`, `project.godot`, Taco scenes, `HideoutHub.tscn`, `player.tscn`, `assets/**`.
