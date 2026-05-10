# 0M-D2A-FIX2 — Debug overlay

- **Script:** `res://src/player/PlayerSprintDebugOverlay.gd` (`class_name PlayerSprintDebugOverlay`)
- **Spawn:** `Player._ready()` adds a child when `OS.is_debug_build()` or `Engine.is_editor_hint()`; calls `setup(self)` so overlay reads the real player each physics frame.
- **Display:** Top-left `CanvasLayer` + `PanelContainer` + `Label`; updates in `_physics_process` via `get_sprint_runtime_debug()`.
- **Signal chain:** Ctrl physical/key, sprint action + strength, Space/dodge, stamina requested/active/multiplier, movement speeds, velocity pre/post slide, combat/dash/dodge gates, suppression reason.

Assertions: `debug_overlay_created`, `debug_overlay_uses_actual_player_runtime`, `get_sprint_runtime_debug_available`, `overlay_shows_full_signal_chain` — all true (see JSON).
