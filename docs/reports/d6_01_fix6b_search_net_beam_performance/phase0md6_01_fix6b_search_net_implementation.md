# PHASE 0M-D6-01-FIX6B Search Net Implementation Report

## Implementation Summary

### Files Modified

**src/levels/IsoMissionBase.gd:**
1. Updated `_d6_fix6_right_hallway_beam_center()` - beam now 80px before bag (was 260px)
2. Rewrote `_assign_fallback_patrol_for_security_guard()` - heat-scaled search net
3. Added `_get_security_search_role(heat, ordinal)` - role assignment
4. Added `_build_search_net_points(center, heat, ordinal, role)` - point generation
5. Added `_build_triangle_points(center, radius, rotation_offset)` - triangle helper
6. Added `_process(delta)` override - lifecycle update hook
7. Added lifecycle management functions:
   - `_update_security_guard_lifecycle(delta)`
   - `_is_security_guard_cleanup_candidate(guard, player_pos)`
   - `_get_security_guard_lifecycle_stats()`
8. Added lifecycle member variables (tracking, thresholds)
9. Updated `_runtime_debug_summary()` - search net and lifecycle fields
10. Updated `_record_security_spawn_probe` calls to include role/ordinal/heat
11. Updated `_add_d6_fix5_temp_beam_visual()` - FIX6B tagging and visibility

**src/missions/iso/runtime/IsoMissionDebugPanel.gd:**
1. Updated `_refresh_status()` - lifecycle stats display
2. Updated `_refresh_status()` - search net info display
3. Added search net section to F10 output

## Key Implementation Details

### Heat-Scaled Radius
```gdscript
H0-1: 140px (territorial triangle)
H2-3: 200px (search net)
H4:   260px (strong search net)
H5:   320px (lockdown)
```

### Role Distribution
```gdscript
H0-1: [territorial]
H2-3: [pursuer_search, flanker, pursuer_search, flanker...]
H4:   [pursuer_search, flanker, chokepoint_holder, objective_sentry, ...]
H5:   [pursuer_search, flanker, chokepoint_holder, objective_sentry, objective_sentry, ...]
```

### Direction Alternation
```gdscript
rotation_offset = (ordinal * 60°) + (ordinal % 2 == 1 ? 180° : 0°)
```

### Lifecycle Thresholds
```gdscript
Active radius: 1000px
Cleanup radius: 1600px
Min age: 12 seconds
Heat 5: 2000px / 20 seconds (more conservative)
```

## Assertions

- ASSERT search_net_implemented == true
- ASSERT far_left_patrol_fallback_removed_for_security_spawns == true
- ASSERT triangle_fallback_supported == true
- ASSERT successive_guard_direction_alternates == true

## Result

**Implementation complete. All search net features implemented.**
