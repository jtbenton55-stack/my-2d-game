# PHASE 0M-D6-01-FIX6B Guard Performance Lifecycle Report

## Implementation Summary

### Purpose
Prevent performance degradation when many security-response guards are spawned by safely removing distant inactive guards.

### Design

**Only affects:** `security_response_spawn` guards (temporary mission spawns)
**Does not affect:** Hand-authored patrol guards, permanent map guards

### Lifecycle States

1. **Active** - near player, chasing, attacking, recently spawned
2. **Searching** - lost player but still relevant, has search role
3. **Dormant** - far away, inactive, candidate for cleanup
4. **Removed** - cleaned up and freed

### Cleanup Eligibility

A guard is eligible for cleanup if ALL of:
- Is a `security_response_spawn` guard
- Is NOT chasing (`chasing` property false, no target)
- Is NOT attacking (`attacking` property false)
- Is far from player (>1600px, or >2000px at heat 5)
- Is old enough (>12 seconds, or >20 at heat 5)
- Is NOT on screen (outside 1000px active radius)

### Functions Added

**`func _process(delta: float) -> void:`**
- Calls super._process(delta)
- Calls _update_security_guard_lifecycle(delta)

**`func _update_security_guard_lifecycle(delta: float) -> void:`**
- Checks every 2 seconds (throttled)
- Iterates security guards
- Calls `_is_security_guard_cleanup_candidate()`
- Marks eligible guards and queues free
- Updates removal counter

**`func _is_security_guard_cleanup_candidate(guard, player_pos) -> bool:`**
- Validates all eligibility conditions
- Returns true if guard should be cleaned up

**`func _get_security_guard_lifecycle_stats() -> Dictionary:`**
- Returns counts: active, searching, dormant, removed_total
- Returns thresholds for F10 display

### Thresholds

```gdscript
var _d6_fix6b_lifecycle_active_near_radius: float = 1000.0
var _d6_fix6b_lifecycle_distant_cleanup_radius: float = 1600.0
var _d6_fix6b_lifecycle_min_age_sec: int = 12
var _d6_fix6b_lifecycle_min_distant_time_sec: int = 8
```

At heat 5:
- Cleanup radius: 2000px
- Min age: 20 seconds

### Cap Management

When a guard is cleaned up:
- `security_response_spawn` meta set to false (removes from functional count)
- `security_lifecycle_removed` meta set to true
- `_d6_fix6b_lifecycle_removed_count` incremented
- `queue_free()` called

This correctly reduces the functional guard count, allowing new spawns.

### F10 Visibility

F10 now shows:
```
Lifecycle: active X / searching Y / dormant Z / removed N
```

### Assertions

- ASSERT guard_performance_lifecycle_implemented_or_deferred_with_reason == true
- ASSERT permanent_patrol_guards_not_destructively_changed == true
- ASSERT cap_freed_when_security_guard_removed == true

### Result

**Performance lifecycle implemented. Distant inactive security-response guards will be safely cleaned up.**
