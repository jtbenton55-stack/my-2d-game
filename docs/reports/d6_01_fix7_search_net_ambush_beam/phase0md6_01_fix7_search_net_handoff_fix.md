# FIX7 Search Net Handoff Fix
- ASSERT search_net_handoff_implemented == true
- ASSERT default_far_left_patrol_disabled_for_security_guards == true
- ASSERT chase_attack_behavior_preserved == true
- ASSERT local_route_assignment_persists_after_losing_player == true

Added explicit guard API handoff (`apply_security_search_net`) and route validation path in IsoMissionBase.
