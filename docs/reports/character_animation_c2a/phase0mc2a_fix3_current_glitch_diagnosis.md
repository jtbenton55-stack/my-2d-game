# FIX3 — Current glitch diagnosis (pre-FIX3 primary = FIX2)

## Primary classification

**A — WRONG_FRAME_SIZE** (dominant): C2 documented **200×200** `source_frame_rect` for the same PVGames kit stack, while FIX2 animated path used **100×200** cells. That mismatch is consistent with “cut in half” / partial-body frames.

## Secondary factors

- **K — BAD_FIX1_OR_FIX2_SPRITEFRAMES:** Godot 4 text format was valid; problem is **pixels**, not parser.
- **G — WRONG_ROW_SELECTED / L — SOURCE_LAYOUT_MISUNDERSTOOD:** Temporal strip selection still matters after correcting cell size.

## Evidence artifacts

- Forensic PNGs: `phase0mc2a_fix3_frame_size_forensic_100x200.png`, `phase0mc2a_fix3_frame_size_forensic_200x200.png`, `phase0mc2a_fix3_frame_size_forensic_comparison.png`
- Bad frame sheets: `phase0mc2a_fix3_current_bad_idle_frames.png`, `phase0mc2a_fix3_current_bad_walk_frames.png`

JSON: `phase0mc2a_fix3_current_glitch_diagnosis.json`.
