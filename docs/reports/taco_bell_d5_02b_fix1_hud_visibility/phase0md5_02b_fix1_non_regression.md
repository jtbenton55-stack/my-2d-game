# Phase 5 — F10 / F1 / F11 / Pause non-regression (static)

## Layer ordering after fix

| Surface | CanvasLayer |
| --- | ---: |
| Player HUD | **50** |
| Phase0JDebugHUD | **90** |
| IsoMissionDebugPanel (F10) | **100** |
| PlayerSprintDebugOverlay (F11) | **110** |
| PauseMenu | **120** |

Godot rule: **higher draws above lower**.

## Expected behavior

- **F10**: still toggles IsoMissionDebugPanel; still the home for dense metrics; **only when toggled** should it sit above HUD.
- **F11**: sprint overlay remains toggle-only; now **110** so it is **below pause** and **above HUD**.
- **F1**: controls overlay unchanged in this pass.
- **Esc / Pause**: pause layer **120** remains above HUD and above F11 overlay.

## Default visibility

- Phase0J playfield debug HUD: `_ready` forces `hide()` with `force_playfield_hidden` default.
- IsoMissionDebugPanel: `visible = false` in `_ready`.
- Sprint overlay: `hide()` in `_ready`.

## Assertions

See `phase0md5_02b_fix1_non_regression.json`.
