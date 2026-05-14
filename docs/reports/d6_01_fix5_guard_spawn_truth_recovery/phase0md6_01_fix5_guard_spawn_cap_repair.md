# Guard spawn cap repair

Implemented:
- functional vs raw guard counting
- invalid/off-map guard rejection before cap accounting
- safe spawn position selection from source + bounded fallback near player
- spawn probe recording for F10 truth

Camera and wrong-code both use repaired spawn_attack_guard_near_player path.
