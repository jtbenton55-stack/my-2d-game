# Phase 0M-C2A — Animation Target Decision

**Phase:** 0M-C2A  
**Phase Name:** Select Animation Target Option  
**Date:** 2026-05-09  

## Decision

**SELECTED TARGET: OPTION C — Generic Idle + Generic Walk**

## Rationale

Based on the Phase 1 (Full Kit Animation Audit) and Phase 2 (Frame/Layer Alignment Proof) results:

### Evidence Summary

| Factor | Finding | Confidence |
|--------|---------|------------|
| Frame Size | 100 x 200 pixels | HIGH |
| Grid Alignment | All 5 C2 layers aligned | HIGH |
| Sheet Dimensions | 10000 x 10000 | CONFIRMED |
| Total Frames per Layer | 5000 (50 rows x 100 cols) | CONFIRMED |
| Populated Rows | 12 of 50 rows | CONFIRMED |
| Frames per Row | 10, 10, 10, 10, 10, 10, 10, 10, 7, 5, 10, 10 | CONFIRMED |
| Direction Structure | Ambiguous 12-row pattern | MEDIUM-LOW |

### Why Not Option D (4-Direction) or E (8-Direction)?

The 12-row populated structure does not cleanly map to:
- 4 directions × 2 animations = 8 rows (we have 12)
- 8 directions × 2 animations = 16 rows (we have 12)

Possible interpretations:
- 8 idle directions (rows 0-7) + 4 walk directions (rows 8-11) = 12 rows
- OR 8 idle directions (rows 0-7) + transition (rows 8-9) + 2 walk directions (rows 10-11)

Without clear evidence of direction order, implementing directional animations risks:
- Character facing wrong directions in-game
- Walk animations playing when idle expected
- Visual disorientation for players

### Why Option C?

**Generic Idle + Generic Walk** provides:
1. **Visual feedback** — player animates when moving vs standing still
2. **No directional assumptions** — avoids wrong-facing risk
3. **Layer safety** — all 5 layers align, compositing is safe
4. **Fallback friendly** — if walk looks wrong, can fall back to idle-only
5. **Gameplay preserved** — no collision, movement, or input changes needed

## Selected Layers for Compositing

Using the same layers as C2 static visual:

| Layer | Variant | Kit | Frame Size |
|-------|---------|-----|------------|
| Base | CyberCity_3 | Kit 1 | 100 x 200 |
| Bottoms | CyberCity_13 | Kit 1 | 100 x 200 |
| Tops | CyberCity_24 | Kit 2 | 100 x 200 |
| Head | CyberCity_4 | Kit 2 | 100 x 200 |
| Hair | CyberCity_7 | Kit 1 | 100 x 200 |

## Animation Frame Selection Strategy

Given the ambiguous 12-row structure:

### Idle Animation
- **Row 0** (first idle frame detected)
- **Frames:** 0-9 (10 frames)
- **FPS:** 6 (slow, subtle breathing idle)
- **Loop:** true

### Walk Animation  
- **Row 10** (late row with full 10 frames, likely walk)
- **Frames:** 0-9 (10 frames)
- **FPS:** 10 (moderate walk pace)
- **Loop:** true

**Note:** Using generic (non-directional) animations means the same animation plays regardless of facing. This is less polished than directional but SAFER given evidence uncertainty.

## Hard Assertions

| Assertion | Status |
|-----------|--------|
| animation_target_option_selected | [PASS] |
| animation_target_supported_by_evidence | [PASS] |
| no_direction_mapping_guesswork | [PASS] |
| static_fallback_selected_if_animation_unsafe | N/A — animation deemed safe |

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Walk animation may not look right | Keep static visual as fallback; switch if needed |
| Generic animation looks bland | Acceptable tradeoff for safety |
| Row selection may be wrong | Chose rows with consistent 10-frame counts |
| No directional facing | Same limitation as static visual — no regression |

## Next Steps

Proceed to Phase 4 — Compose Animated Parmida Spritesheet:
- Extract row 0 frames (idle) from all 5 layers
- Extract row 10 frames (walk) from all 5 layers  
- Composite into single animated spritesheet
- Generate SpriteFrames resource
- Create visual-only PlayerVisualAnimator.gd
- Build animation sandbox for validation

