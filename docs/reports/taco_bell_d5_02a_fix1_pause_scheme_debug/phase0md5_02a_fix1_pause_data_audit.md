# Phase 1 — Pause data / GameState warning forensic audit

## Source of "(warn) GameState missing"

- **Emitters:** `MissionSchemeBridge.gd` and `MissionClueBridge.gd` appended `"GameState missing"` when `Engine.has_singleton("GameState")` was false.
- **Root cause:** In Godot 4.x, **autoload singletons are not registered via `Engine.has_singleton()`**. That API is for engine-registered singletons. `/root/GameState` exists at runtime, but `has_singleton` returns false.
- **Propagation:** `MissionPauseDataProvider.get_scheme_card_snapshot` / `get_clue_snapshot` forwarded `warnings` into `get_pause_payload`; `pause_menu.gd` printed each warning as `(warn) ...`.

## Autoload access pattern

- **Correct pattern from RefCounted/static context:** resolve `Engine.get_main_loop()` as `SceneTree`, then `root.get_node_or_null("GameState")` (same for `CardManager`, etc.).
- **Implemented helper:** `MissionAutoloadResolver.get_root_autoload()` + `has_game_state()` / `has_card_manager()`.

## mission_id / timing

- `MissionPauseDataProvider._effective_mission_id` also used `Engine.has_singleton("GameState")`, so `mid` could fall back to `""` in the same false-negative scenario. Fixed to use `MissionAutoloadResolver.has_game_state()`.

## Classification

| Area | Finding |
|------|---------|
| Pause UI | Correctly used bridges; warnings were false positives from bad API |
| RefCounted | Not a tree issue — wrong singleton check |
| Fix strategy | Resolver + bridge swap; user-facing text uses "Note:" instead of "(warn)" for residual warnings |
