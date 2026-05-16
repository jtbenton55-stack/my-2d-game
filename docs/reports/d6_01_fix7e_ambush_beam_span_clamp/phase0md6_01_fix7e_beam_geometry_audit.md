# FIX7E — Current beam geometry audit (pre-change reference + root cause)

1. **AMBUSH anchor:** `_setup_fix7_ambush_beam_runtime` resolves `AMBUSH_security_beam` via `_find_authoring_marker` / `_find_runtime_debug_marker` (FIX7A).
2. **Choke X:** `_compute_fix7d_ambush_beam_from_collision` used `spawn_route_louis_return` marker `global_position.x` when present; else anchor X.
3. **Visual top/bottom (FIX7D):** `_probe_fix7d_vertical_wall_boundaries` tried several `probe_y` values and kept the pair with the **largest** vertical gap; then applied `± D6_FIX7D_AMBUSH_BEAM_WALL_OVERLAP_PX` (36px) **outside** the hit interval.
4. **Trigger:** Same vertical span as computed `height`; width `D6_FIX7D_AMBUSH_BEAM_TRIGGER_WIDTH`.
5. **Line2D:** `_attach_fix7_ambush_beam_visual` — vertical segment, `half_h = height * 0.5`.
6. **Why too tall:** Hypothesis **C** confirmed — largest-gap selection; Hypothesis **B** — 36px overlap on visual contributed to wall pierce.
7. **FIX7E change:** Single probe Y, inner hits without outward visual overlap; separate trigger overlap only.
