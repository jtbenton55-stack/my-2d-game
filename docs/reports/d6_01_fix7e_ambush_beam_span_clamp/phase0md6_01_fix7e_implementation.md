# FIX7E — Implementation summary

- **IsoMissionBase.gd:** Added `D6_FIX7E_*` constants. Replaced active geometry path in `_setup_fix7_ambush_beam_runtime` with `_compute_fix7e_ambush_beam_inner_gap`. Single-probe vertical rays; visual overlap **0**; trigger overlap **8px**. Clamped/fallback per constants. `_apply_fix7e_ambush_beam_geometry` sizes `RectangleShape2D` to trigger width × `trigger_height`. Line2D width uses `D6_FIX7E_AMBUSH_BEAM_VISUAL_WIDTH`. Legacy `_compute_fix7d_*` retained for history only — **not** called from setup.
- **IsoMissionDebugPanel.gd:** F10 adds `--- AMBUSH beam (FIX7E) ---` block with mode, collision, fallback, choke/probe, hits, visual/trigger spans, mismatch, reason.
- **Runtime summary:** `_runtime_debug_summary` exposes `fix7e_*` keys and updated beam F10 strings.

See `phase0md6_01_fix7e_implementation.json` for structured detail.
