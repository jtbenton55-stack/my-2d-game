# D6-01-FIX7B — Final report: AMBUSH beam geometry

## Verdict: **PARTIAL**

Vertical beam and trigger alignment are implemented in code with named constants and F10 fields. **Interactive Godot playtest was not run** in this pass (no `godot` CLI in environment), so choke placement, true wall-to-wall coverage, `beam_trip`, and guard spawn must be confirmed manually.

## Root cause (horizontal era)

`Line2D` used world-space X endpoints with an unpositioned host; `RectangleShape2D` was wide and short.

## After this pass

- **Orientation:** Vertical `Line2D` + tall `RectangleShape2D`.
- **Center:** `anchor_pos + D6_FIX7B_AMBUSH_BEAM_CENTER_OFFSET` (`Vector2(-180,-48)`).
- **Dimensions:** Visual width 32, trigger `(56, 560)`, height 560.

## Kimi

Not used (skipped by engineering choice).

## Files

- **Modified:** `src/levels/IsoMissionBase.gd`, `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- **Created:** `docs/reports/d6_01_fix7b_ambush_beam_geometry/*`, `src/tools/editor/d6_01_fix7b_ambush_beam_geometry/phase0md6_01_fix7b_static_validator.py`

## Next pass

Manual playtest; tune `D6_FIX7B_AMBUSH_BEAM_CENTER_OFFSET` / `D6_FIX7B_AMBUSH_BEAM_HEIGHT` from in-editor screenshot alignment; optional corridor raycast only if needed.
