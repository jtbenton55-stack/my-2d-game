# Phase 4 — F10 raw scheme debug

- `IsoMissionDebugPanel._refresh_status` appends `MissionSchemeCardFormatter.format_scheme_snapshot_debug_block(MissionSchemeBridge.get_scheme_snapshot(mid))` to the compact scrollable status text.
- Includes loadout arrays, legacy picker IDs, unlocked IDs, equipped rows, `scheme_debug_note`, and warnings.
