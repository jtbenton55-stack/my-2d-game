# FIX7C — Implementation

## `IsoMissionBase.gd`

- Replaced tunables with:
  - `D6_FIX7C_AMBUSH_BEAM_CENTER_OFFSET := Vector2(-380, -48)`
  - `D6_FIX7C_AMBUSH_BEAM_HEIGHT := 840.0`
  - `D6_FIX7C_AMBUSH_BEAM_TRIGGER_SIZE := Vector2(72, 840)`
  - `D6_FIX7C_AMBUSH_BEAM_VISUAL_WIDTH := 32.0`
  - `D6_FIX7C_AMBUSH_BEAM_ORIENTATION := "vertical"`
- Renamed `_apply_fix7b_ambush_beam_rectangle_shape` → `_apply_fix7c_ambush_beam_rectangle_shape` using `D6_FIX7C_AMBUSH_BEAM_TRIGGER_SIZE`.
- `_setup_fix7_ambush_beam_runtime` / `_attach_fix7_ambush_beam_visual` use FIX7C constants only.
- Runtime debug keys remain `fix7b_ambush_beam_*` (values now reflect FIX7C tune).
- `_runtime_debug_summary`: `beam_f10_plain`, `beam_f10_fix7c_note` for F10.

## Wiring preserved

- `body_entered` bind `AMBUSH_security_beam`, `_on_runtime_alarm_zone_entered`, `beam_trip`, guard response — **unchanged**.
