# Phase 0M-C2A-FIX2 — Source layer grid verification

## Verified frame geometry

All five selected PVGames **Spritesheet.png** files for Parmida’s stack measure **10000×10000** pixels. That implies a regular grid of **100×200** cells (100 columns × 50 rows), matching the earlier audit’s **100×200** frame size (no contradiction found).

## Selected layers (exact paths)

Paths match `parmida_player_animation_metadata_0mc2a_fix2.json`.

| Layer | Path |
|-------|------|
| Female Base 3 | `.../Female/Base/CyberCity_3/Spritesheet.png` |
| Bottoms 13 | `.../Female/Bottoms/CyberCity_13/Spritesheet.png` |
| Tops 24 | `.../Female/Tops/CyberCity_24/Spritesheet.png` |
| Head 4 | `.../Female/Head/CyberCity_4/Spritesheet.png` |
| Hair 7 | `.../Female/Hair/CyberCity_7/Spritesheet.png` |

## Rules observed

- Same **width/height** for every layer sheet → shared grid indexing is valid.
- FIX2 extraction uses the **same (row, col)** rectangle from each layer for a given animation frame (no per-layer row mismatch in the compositor).
- **Raw kit PNGs were not modified** (read-only inspection and compositing).

## JSON

See `phase0mc2a_fix2_source_layer_grid_verification.json` for assertions and dimensions.
