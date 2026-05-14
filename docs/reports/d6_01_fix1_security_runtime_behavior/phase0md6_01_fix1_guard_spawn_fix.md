# Guard spawn fix

- **`MissionSecurityGuardResolver`**: canonical `guard.tscn` path; documents deprecated procedural script path.
- **`Phase0KBWrongCodeAttackGuardSpawner`**: delegates to **`spawn_attack_guard_near_player`**.
- **`IsoMissionBase.spawn_attack_guard_near_player`**: instantiates **GOOD** scene, caps, offset, metadata.
