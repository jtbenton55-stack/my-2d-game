# FIX7E — Collision inner-gap plan (A–B visual vs trigger)

- **X:** Unchanged from FIX7D (`choke_x`).
- **Probe Y:** Average of AMBUSH anchor Y and `spawn_route_louis_return` Y when the spawn marker exists; otherwise anchor Y (local hallway vertical center).
- **Rays:** Single origin `(choke_x, probe_y)`; mask **7**; bodies only; length **2200**.
- **Visual:** Raw hit `y` values as inner boundaries; `D6_FIX7E_VISUAL_WALL_OVERLAP_PX = 0`.
- **Trigger:** Extends **8px** beyond visual top/bottom (`D6_FIX7E_TRIGGER_WALL_OVERLAP_PX`).
- **Anti-giant:** Reject inner span `< 96` or `> 520` → centered numeric fallback (360 visual / 400 trigger) with F10 `reason`.
- **Center:** Midpoint of **visual** span for host + alarm zone position (trigger symmetric → same center Y).
