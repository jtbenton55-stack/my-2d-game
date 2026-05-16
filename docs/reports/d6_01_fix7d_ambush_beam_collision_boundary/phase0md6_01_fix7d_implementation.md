# FIX7D implementation

## `IsoMissionBase.gd`

- **`_find_fix7d_spawn_route_louis_return_marker()`** — authoring then runtime debug marker.
- **`_fix7d_intersect_vertical_ray` / `_probe_fix7d_vertical_wall_boundaries`** — dual vertical rays, mask `7`, bodies only.
- **`_compute_fix7d_ambush_beam_from_collision(anchor_pos)`** — returns `mode` `collision_boundary` or `fallback`, geometry fields, `reason` on failure.
- **`_apply_fix7d_ambush_beam_rectangle_shape(area, sz)`** — `RectangleShape2D` matches computed height.
- **`_setup_fix7_ambush_beam_runtime`** — uses geometry dict; stores `fix7d_*` + computed `fix7b_ambush_beam_center_offset` (`beam_center - anchor`).
- **`_attach_fix7_ambush_beam_visual(..., beam_half_height)`** — line span from collision height.

## Preserved

- `body_entered` → `AMBUSH_security_beam` binding, `beam_trip`, guard response unchanged.
