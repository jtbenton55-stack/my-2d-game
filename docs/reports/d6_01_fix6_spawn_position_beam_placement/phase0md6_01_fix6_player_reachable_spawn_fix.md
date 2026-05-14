# Player Reachable Spawn Fix

Implemented in IsoMissionBase.gd. Camera and wrong-code share _choose_security_response_spawn_position. The live security path records requested/chosen/actual and mode. It sets final guard.global_position after add_child and again after fallback patrol assignment, because Guard.assign_patrol_path snaps position. Functional cap ignores far/offscreen/unreachable guards by requiring security_response_spawn metadata, visible chain, playable bounds, and <=760 px from player. Spawned security guards get aggro_range at least 440 for immediate response without Player.gd changes.

## Assertions
- ASSERT player_reachable_spawn_fix_implemented == true
- ASSERT final_guard_position_set_after_add_child == true
- ASSERT far_left_unreachable_spawn_not_functional_for_cap == true
- ASSERT camera_and_wrong_code_use_same_spawn_selector == true
