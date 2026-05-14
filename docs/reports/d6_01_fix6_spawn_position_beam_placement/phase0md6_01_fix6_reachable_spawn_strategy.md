# Reachable Spawn Strategy

Strategy: live security response prioritizes player-near global positions over far source markers. Candidate offsets around player are checked first at roughly 180-300 px. Candidates must be within playable bounds, 150-430 px from player, and on a floor cell not marked collision-blocked when layer data is available. If collision validation cannot prove a candidate, the fallback remains player-near, not far-left source-marker based. Functional cap rejects invisible/offmap guards and guards more than 760 px from player.

## Assertions
- ASSERT reachable_spawn_strategy_created == true
- ASSERT player_near_fallback_defined == true
- ASSERT far_left_unreachable_spawn_rejected_or_justified == true
