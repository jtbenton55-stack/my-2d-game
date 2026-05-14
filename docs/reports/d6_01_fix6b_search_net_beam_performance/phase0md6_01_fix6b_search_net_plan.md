# PHASE 0M-D6-01-FIX6B Search Net Implementation Plan

## 1. Search Net Logic Location

**Owner:** `IsoMissionBase.gd`

**Functions:**
- `_assign_fallback_patrol_for_security_guard(guard, anchor)` - entry point
- `_get_security_search_role(heat, ordinal)` - role assignment
- `_build_search_net_points(center, heat, ordinal, role)` - point generation
- `_build_triangle_points(center, radius, rotation_offset)` - triangle helper

## 2. Guard Role Assignment

| Heat | Roles | Behavior |
|------|-------|----------|
| 0-1 | territorial | Simple triangle patrol around spawn |
| 2-3 | pursuer_search, flanker | Search near last known, flanker offsets |
| 4 | pursuer_search, flanker, chokepoint_holder, objective_sentry | Full role distribution |
| 5 | + double objective_sentry | Aggressive lockdown with sentry emphasis |

## 3. Triangle Route Generation

**Formula:**
- Base angles: 0°, 120°, 240°
- Rotation offset: `ordinal * 60°` (alternates direction by parity)
- Y-flattened for isometric: `sin(angle) * radius * 0.6`
- Heat-scaled radius: H0-1=140, H2-3=200, H4=260, H5=320

**Role offsets:**
- pursuer_search: centered on anchor
- flanker: ±0.6 * radius X offset
- chokepoint_holder: radius * 0.4 offset by rotation
- objective_sentry: toward bag room if known

## 4. Far-Left Point Rejection

All points are generated relative to the spawn anchor (near player), so they naturally avoid far-left markers. No explicit rejection needed.

## 5. F10 Debug Display

**New fields:**
- `search_net_heat` - current heat level
- `search_net_last_role` - last assigned role
- `search_net_last_ordinal` - spawn order
- `search_net_triangle_radius_by_heat` - radius used
- `lifecycle_active/searching/dormant/removed` - lifecycle counts

## 6. Performance Lifecycle

**Owner:** `IsoMissionBase.gd`

**Functions:**
- `_process(delta)` - calls `_update_security_guard_lifecycle(delta)`
- `_update_security_guard_lifecycle(delta)` - periodic cleanup check
- `_is_security_guard_cleanup_candidate(guard, player_pos)` - eligibility check
- `_get_security_guard_lifecycle_stats()` - F10 stats

**Policy:**
- Check every 2 seconds
- Only `security_response_spawn` guards
- Never cleanup chasing/attacking/recent guards
- Never cleanup on-screen guards
- Heat 5: more conservative thresholds

## 7. Assertions

- ASSERT search_net_plan_created == true
- ASSERT heat_scaled_roles_defined == true
- ASSERT low_heat_triangle_fallback_defined == true

## 8. Result

**Plan approved. Proceeding with implementation.**
