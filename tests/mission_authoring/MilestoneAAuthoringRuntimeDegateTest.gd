extends GdUnitTestSuite

const IsoMissionBaseScript := preload("res://src/levels/IsoMissionBase.gd")
const MissionDefinitionScript := preload("res://src/missions/definitions/MissionDefinition.gd")
const SecurityAuthoringRootScript := preload("res://src/missions/iso/authoring/SecurityAuthoringRoot.gd")
const SecurityBeamAuthorScript := preload("res://src/missions/iso/authoring/SecurityBeamAuthor.gd")
const SecurityCameraAuthorScript := preload("res://src/missions/iso/authoring/SecurityCameraAuthor.gd")


func test_non_taco_security_root_builds_router_and_authored_beam() -> void:
	var mission := _spawn_mission("milestone_a_runtime_test")
	var sec_root := _add_security_root(mission)
	var beam := SecurityBeamAuthorScript.new()
	beam.name = "BeamAuthor"
	beam.beam_id = &"AMBUSH_security_beam"
	beam.alarm_id = &"AMBUSH_security_beam"
	sec_root.add_child(beam)
	var camera := SecurityCameraAuthorScript.new()
	camera.name = "CameraAuthor"
	camera.camera_id = &"milestone_a_camera"
	sec_root.add_child(camera)

	mission.call("_setup_fix7_ambush_beam_runtime")
	mission.call("_setup_d6_03_authoring_security_runtime")
	var summary: Dictionary = mission.get_runtime_debug_summary()

	assert_bool(summary.get("d6_03_security_router_active", false)).is_true()
	assert_str(String(summary.get("d6_02_ambush_beam_source", ""))).is_equal("authoring_node")
	assert_bool(int(summary.get("d6_02_security_authoring_beam_count", 0)) >= 1).is_true()
	assert_bool(mission.get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones/AlarmZone_AMBUSH_security_beam") is Area2D).is_true()
	assert_bool(mission.get_node_or_null("EntityRoot/Cameras/AuthoredCamera_milestone_a_camera") is Area2D).is_true()

	_free_node(mission)


func test_non_taco_without_security_root_records_no_collectible_root_and_no_router() -> void:
	var mission := _spawn_mission("milestone_a_no_root_test")
	mission.call("_setup_d6_03_authoring_security_runtime")
	mission.call("_setup_d6_06_collectible_authoring_runtime")
	var summary: Dictionary = mission.get_runtime_debug_summary()

	assert_bool(summary.get("d6_03_security_router_active", true)).is_false()
	assert_bool(summary.get("d6_06_authoring_root_found", true)).is_false()
	assert_bool(mission.get_node_or_null("GameplayRoot/RuntimeSystems/SecurityEventRouter") == null).is_true()

	_free_node(mission)


func _spawn_mission(mission_id: String) -> Node:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "MilestoneATestMission"
	var definition := MissionDefinitionScript.new()
	definition.mission_id = mission_id
	mission.set("mission_definition", definition)
	add_child(mission)
	var gameplay_root := Node2D.new()
	gameplay_root.name = "GameplayRoot"
	mission.add_child(gameplay_root)
	var runtime_systems := Node2D.new()
	runtime_systems.name = "RuntimeSystems"
	gameplay_root.add_child(runtime_systems)
	var alarm_zones := Node2D.new()
	alarm_zones.name = "AlarmZones"
	runtime_systems.add_child(alarm_zones)
	var entity_root := Node2D.new()
	entity_root.name = "EntityRoot"
	mission.add_child(entity_root)
	return mission


func _add_security_root(mission: Node) -> Node2D:
	var gameplay_root := mission.get_node("GameplayRoot")
	var sec_root: Node2D = SecurityAuthoringRootScript.new()
	sec_root.name = "SecurityAuthoringRoot"
	sec_root.runtime_enabled = true
	gameplay_root.add_child(sec_root)
	return sec_root


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
