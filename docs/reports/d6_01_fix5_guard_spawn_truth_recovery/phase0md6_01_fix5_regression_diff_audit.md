# Regression diff / last-known-good audit

Root regression sequence:
1. FIX4 changed cap to count security_response_spawn but still allowed invalid coordinates to be counted as live if node existed in-tree.
2. Attack guard creation used marker_cell = Vector2i.ZERO path before repositioning; this made fallback marker resolution vulnerable to bad/irrelevant positions in scene-authored marker space.
3. Result: off-map/invisible security nodes could be tagged and counted, filling cap with no visible gameplay guards.

Preserved behaviors:
- Deferred spawn queue (no flushing-query error).
- Camera sweep restore logic.
- Mid-run heat policy unchanged.
