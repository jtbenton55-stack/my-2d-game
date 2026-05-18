# 0M-D6-01-FIX7F — Implementation

## Problem (FIX7E manual fail)
Single-probe inner gap at seed X was not centered in the walkable doorway; beam overlapped walls.

## Solution
`_compute_fix7f_ambush_beam_doorway_rect` searches a grid of candidate `(x, probe_y)` around seed X/Y from AMBUSH anchor + `spawn_route_louis_return`. Each candidate:
- Rejects if origin inside wall (`intersect_point`, mask 7)
- Vertical rays up/down for inner top/bottom hits
- Rejects invalid height (<96 or >520)
- Rejects if visual or trigger `RectangleShape2D` overlaps blocking collision (`intersect_shape`)
- Scores survivors by distance from seed + height proximity to ideal 220px

## Wiring
- `_setup_fix7_ambush_beam_runtime` uses FIX7F geometry only
- `_apply_fix7f_ambush_beam_geometry` sizes alarm zone trigger
- `_attach_fix7_ambush_beam_visual` draws Line2D + optional `_attach_fix7f_debug_markers`
- F10 block `--- AMBUSH beam (FIX7F) ---` in `IsoMissionDebugPanel.gd`

## Unchanged
Guard spawn, camera, wrong-code, search-net, heat, player, scenes, `project.godot`.
