# Phase 6 — F10 debug consolidation

- **Phase0JDebugHUD:** `force_playfield_hidden` (default true) clears scene `visible_by_default` at runtime, `hide()`s the layer, and routes `show_message` text to `EventBus.debug` instead of flashing UI.
- **IsoMissionDebugPanel (F10):** compact status now includes Phase0J adapter category counts, `GameState.poop_bag_inventory`, `current_scheme_loadout` + `selected_cards`, and `QuestManager` objective line — single scrollable dev surface.
- **HideoutManager:** `_write_scheme_loadout_to_game_state()` now runs before **replay** and legacy mission-board direct launches so `GameState.current_scheme_loadout` matches the Planning Table without requiring the confirm subpanel path only.
