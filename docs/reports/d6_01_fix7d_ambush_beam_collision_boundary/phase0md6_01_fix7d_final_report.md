# FIX7D final report

## Verdict: **PARTIAL**

Collision-derived placement is implemented in code; **no in-editor playtest** in this pass. **PASS** requires confirming F10 `collision_boundary`, no fallback, and visual match to white-line choke.

## Method

Vertical `intersect_ray` at `choke_x` (spawn_route_louis_return when present), `collision_mask=7`, `collide_with_bodies=true`, overlap into walls via `D6_FIX7D_AMBUSH_BEAM_WALL_OVERLAP_PX`.
