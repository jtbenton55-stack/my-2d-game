# Spawn pipeline forensic audit

Path verified:
- MissionSecurityCamera.accumulate_exposure -> MissionAlertController.record_alarm_event(kind='camera_detected') -> IsoMissionBase.spawn_attack_guard_near_player -> deferred queue -> _flush_deferred_security_guard_spawns -> _spawn_guard_for_spawn -> EntityRoot/Enemies add_child.

Wrong-code path:
- MissionCodeGatePlaceholder._on_wrong_code and Phase0KBWrongCodeAttackGuardSpawner.register_wrong_code_attempt both route to spawn_attack_guard_near_player.

Exact failure root cause:
- Security response nodes could be tagged/countable before sanity validation, and bad spawn coordinates (from Vector2i.ZERO fallback marker resolution path) produced off-map nodes still counted against cap.
