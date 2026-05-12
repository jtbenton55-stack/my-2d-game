# Phase 5 — Scheme card visibility / honesty

- `MissionSchemeBridge.get_scheme_snapshot` now merges:
  - Legacy `CardManager.get_selected_cards()` rows, and
  - Non-empty IDs from `GameState.current_scheme_loadout` (plan/trick/comfort_chaos), with `CardManager.get_card` when available.
- Snapshot adds `loadout_slots`, `legacy_selected_card_ids`, merged `unlocked_ids`, and multi-line `effects_note` explaining **which systems read which stores** (no claim that all cards apply in Taco).
- `pause_menu.gd` Scheme Cards tab renders slots, legacy picker, unlocked list, and the effects note inside existing scrollable `RichTextLabel`.
