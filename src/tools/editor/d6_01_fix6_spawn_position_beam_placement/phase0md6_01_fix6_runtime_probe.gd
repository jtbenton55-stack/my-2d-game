extends SceneTree

const SCENE_PATH := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		print(JSON.stringify({"passed": false, "reason": "scene_load_failed"}))
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		print(JSON.stringify({"passed": false, "reason": "scene_instantiate_failed"}))
		quit(1)
		return
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var result := {
		"passed": true,
		"camera": await _probe_spawn(scene, "garage_fallback_camera"),
		"wrong_code": await _probe_spawn(scene, "wrong_code_phase0kb"),
		"beam_status": _beam_status(scene),
	}
	scene.queue_free()
	print(JSON.stringify(result))
	quit(0)


func _probe_spawn(scene: Node, source_id: String) -> Dictionary:
	if not scene.has_method("spawn_attack_guard_near_player"):
		return {"passed": false, "reason": "spawn_method_missing"}
	scene.call("spawn_attack_guard_near_player", source_id)
	await process_frame
	await process_frame
	if not scene.has_method("get_runtime_debug_summary"):
		return {"passed": false, "reason": "debug_summary_missing"}
	var summary: Dictionary = scene.call("get_runtime_debug_summary")
	var probe: Dictionary = summary.get("d6_fix6_spawn_probe", {}) as Dictionary
	var result := String(probe.get("result", ""))
	var distance := float(probe.get("last_spawn_distance_to_player", 99999.0))
	return {
		"passed": result == "success" and distance >= 150.0 and distance <= 760.0,
		"source": source_id,
		"result": result,
		"mode": String(probe.get("spawn_mode", "")),
		"requested": str(probe.get("requested_position", "")),
		"chosen": str(probe.get("chosen_position", "")),
		"actual": str(probe.get("actual_position", "")),
		"distance": distance,
		"functional": int(summary.get("security_response_spawn_count", 0)),
		"raw": int(summary.get("security_response_spawn_count_raw", 0)),
		"invalid": int(summary.get("invalid_offmap_security_guard_count", 0)),
	}


func _beam_status(scene: Node) -> Dictionary:
	var node := scene.get_node_or_null("GameplayRoot/RuntimeSystems/D6_FIX6_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS")
	if node == null:
		node = scene.get_node_or_null("GameplayRoot/D6_FIX6_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS")
	return {
		"visible_node_exists": node != null,
		"node_path": str(node.get_path()) if node != null else "",
	}
