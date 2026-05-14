# Spawn Coordinate Audit

Pipeline audited: camera/wrong-code events route through MissionAlertController or Phase0KB/MissionCodeGatePlaceholder into IsoMissionBase.spawn_attack_guard_near_player, queued flush, spawn selector, MissionSpawnDefinition, _spawn_guard_for_spawn, guard.tscn instantiate under EntityRoot/Enemies, target assignment, patrol assignment, cap accounting, and F10 summary. The remaining exact root cause found by runtime probe was post-placement patrol snapping: Guard.assign_patrol_path sets global_position to the first generated patrol point. Earlier _spawn_guard_for_spawn also assigned from marker-cell resolution before the caller's live security placement, so requested/chosen/actual truth was obscured. FIX6 now sets/verifies final global_position after add_child and after fallback patrol assignment.

## Assertions
- ASSERT spawn_coordinate_pipeline_audited == true
- ASSERT requested_vs_actual_spawn_divergence_checked == true
- ASSERT off_left_spawn_cause_identified_or_runtime_probe_required == true
