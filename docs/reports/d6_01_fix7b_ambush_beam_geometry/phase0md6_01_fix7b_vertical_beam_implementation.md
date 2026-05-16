# Vertical beam implementation (FIX7B)

## Code changes (`IsoMissionBase.gd`)

- **Constants:** `D6_FIX7B_AMBUSH_BEAM_*` — orientation `vertical`, visual width 32, trigger width 56, height 560, center offset `(-180,-48)`.
- **`_apply_fix7b_ambush_beam_rectangle_shape`:** Ensures `RectangleShape2D.size = (56, 560)` on `AlarmZone_AMBUSH_security_beam`.
- **`_setup_fix7_ambush_beam_runtime`:** `beam_center = anchor + offset`; applies rect; sets `beam_area.global_position = beam_center`; records `fix7b_*` in `_attempt_runtime_state`.
- **`_attach_fix7_ambush_beam_visual`:** `host.global_position = beam_center`; `Line2D` points `(0, -h/2)` → `(0, h/2)`; beacons top/bottom; mismatch = distance visual center vs trigger center (both `beam_center` when armed).
- **`_compute_beam_player_relationship`:** Uses `fix7b_ambush_beam_center` when present.
- **`_spawn_alarm_zone`:** Removed duplicate `_attach_fix7_ambush_beam_visual` for `AMBUSH_security_beam` (deferred setup owns geometry).

## Non-goals

- Four-guard ambush not implemented.
- No new save keys.
