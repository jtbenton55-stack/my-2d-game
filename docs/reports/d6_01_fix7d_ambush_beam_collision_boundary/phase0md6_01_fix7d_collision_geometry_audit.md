# Collision / wall geometry audit

## Scene facts (read-only)

- **Gameplay collision:** `GameplayRoot/GameplayCollisionLayer` — tileset `physics_layer_0/collision_layer = 4` (tile physics).
- **Player body** (`player.tscn`): `collision_mask = 7` (layers 1+2+4). FIX7D vertical rays use **`collision_mask = 7`** so hits match walk-blocking geometry the player meets.
- **Choke X:** `spawn_route_louis_return` (`GameplayRoot/MarkerRoot/Spawns/...` or `Debug_spawn_route_louis_return`) — authored entry at the post-gate choke per screenshots; **X is taken from this marker’s `global_position`**, not a numeric offset from AMBUSH.

## Algorithm

1. Resolve `AMBUSH_security_beam` anchor (FIX7A unchanged).
2. `choke_x = spawn_route_louis_return.global_position.x` when marker exists; else `anchor_pos.x` (recorded as `anchor_x_only_spawn_marker_missing`).
3. At `choke_x`, vertical `PhysicsDirectSpaceState2D.intersect_ray` up/down from probe Y candidates (anchor Y, spawn Y, midpoint); pick probe with largest corridor gap.
4. `top_y = hit_up.y - overlap`, `bottom_y = hit_down.y + overlap`, `height = bottom_y - top_y`, `center = (choke_x, (top_y+bottom_y)/2)`.
5. **Fallback** (explicit, F10): prior FIX7C-style `D6_FIX7D_FALLBACK_ANCHOR_OFFSET` + fixed height only if rays fail or height &lt; minimum.
