# Phase 1 — Scheme display audit

- **Pause text builder:** `pause_menu.gd` → `_scheme_cards_text()` (was inline debug copy; now delegates to `MissionSchemeCardFormatter.format_player_pause_scheme_text`).
- **Raw payload:** `MissionSchemeBridge.get_scheme_snapshot()` returns `equipped`, `loadout_slots`, `legacy_selected_card_ids`, `unlocked_ids`, `scheme_debug_note`, `warnings`.
- **Readable names:** `HideoutStationCatalog.scheme_cards()` + `CardManager.get_card()` + snake_case title fallback in `MissionSchemeCardFormatter.display_name_for_id`.
- **Player vs debug:** Pause uses formatter player path only; F10 compact status appends `MissionSchemeCardFormatter.format_scheme_snapshot_debug_block`.
