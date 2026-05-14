# PHASE 0M-D6-01-FIX6B Guard Fallback / Performance Audit

## Current Guard Behavior Analysis

### 1. What Happens When Guards Lose the Player

**Previous behavior (FIX6/FIX6A):**
- Guards assigned to local patrol ring (6-point circle, 180px radius)
- Patrol around spawn position
- Stored `security_spawn_position` and `security_local_patrol_enabled` metadata

**Root cause of far-left collection:**
- Prior to FIX6: Guards were assigned to far-left map patrol markers via `assign_patrol_path(path_node)` which snapped `global_position` to the first patrol point
- FIX6/FIX6A: Fixed by creating local patrol rings, but guards could still bunch on the left side if they didn't have proper patrol targets

### 2. Performance Risk Areas

| Risk | Severity | Status |
|------|----------|--------|
| Too many physics bodies | Medium | No hard limit, cap at 6 guards |
| Navigation agents | Low | Simple patrol, no pathfinding |
| Vision cones | Medium | Per-frame checks |
| Per-frame detection loops | Medium | Alert controller handles |
| F10 preview | Low | Only when visible |

### 3. Guard AI Ownership

- **Movement/Patrol**: Guard.gd / EnemyBase.gd
- **Spawn/Search Assignment**: IsoMissionBase.gd (FIX6B additions)
- **State Tracking**: Metadata on guard nodes

### 4. Dynamic Patrol API

**Existing:**
- `guard.assign_patrol_path(path: Path2D)` - uses Path2D with world-space points
- Guards iterate through curve points

**FIX6B Enhancement:**
- `_assign_fallback_patrol_for_security_guard()` now generates heat-scaled search net points
- Triangle patrol generation with role-based offsets
- Ordinal-based rotation to prevent stacking

### 5. Performance Lifecycle Policy (FIX6B)

**Cleanup candidates:**
- Far from player (>1600px)
- Not visible on screen
- Not chasing
- Not attacking
- Not recently spawned (>12 sec)
- Not currently alerted
- Only applies to `security_response_spawn` guards

**Thresholds:**
- Active radius: 1000px
- Cleanup radius: 1600px
- Min age: 12 seconds
- Min distant time: 8 seconds
- Heat 5: More conservative (2000px, 20 sec)

### 6. Assertions

- ASSERT guard_fallback_audited == true
- ASSERT far_left_collection_cause_identified_or_gap_reported == true
- ASSERT performance_risk_audited == true

### 7. Result

**Audit completed. Root causes identified:**
1. Guards previously assigned to far-left patrol markers (FIX6 fixed this)
2. Lack of heat-scaled search behavior (FIX6B addresses)
3. No distant guard cleanup (FIX6B lifecycle addresses)
