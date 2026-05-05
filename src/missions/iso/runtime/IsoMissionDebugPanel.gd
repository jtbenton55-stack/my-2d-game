class_name IsoMissionDebugPanel
extends CanvasLayer

@export var mission_id: String = ""

var _mission: Node = null
var _compact_panel: Panel = null
var _details_panel: Panel = null
var _status: Label = null
var _details: RichTextLabel = null


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("iso_debug_hud"):
		if node != self and is_instance_valid(node):
			node.queue_free()
	add_to_group("iso_debug_hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_mission = get_tree().current_scene
	_build_ui()
	set_process(true)
	visible = OS.is_debug_build()
	if _details_panel != null:
		_details_panel.visible = false


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_F10) and not Input.is_physical_key_pressed(KEY_ALT):
		if not get_meta("f10_latched", false):
			set_meta("f10_latched", true)
			toggle_compact_hud()
	elif get_meta("f10_latched", false):
		set_meta("f10_latched", false)
	if Input.is_key_pressed(KEY_F9):
		if not get_meta("f9_latched", false):
			set_meta("f9_latched", true)
			toggle_debug_details()
	elif get_meta("f9_latched", false):
		set_meta("f9_latched", false)
	if not visible:
		return
	_refresh_status()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_compact_panel = Panel.new()
	_compact_panel.name = "CompactDebugHUD"
	_compact_panel.anchor_left = 0.0
	_compact_panel.anchor_top = 0.5
	_compact_panel.anchor_right = 0.0
	_compact_panel.anchor_bottom = 0.5
	_compact_panel.offset_left = 18.0
	_compact_panel.offset_top = -84.0
	_compact_panel.offset_right = 306.0
	_compact_panel.offset_bottom = 84.0
	add_child(_compact_panel)
	var compact := Label.new()
	compact.name = "Status"
	compact.position = Vector2(8, 6)
	compact.size = Vector2(276, 110)
	compact.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status = compact
	_compact_panel.add_child(compact)
	_details_panel = Panel.new()
	_details_panel.name = "DebugDetailsPanel"
	_details_panel.position = Vector2(14, 190)
	_details_panel.size = Vector2(340, 220)
	add_child(_details_panel)
	_details = RichTextLabel.new()
	_details.position = Vector2(8, 8)
	_details.size = Vector2(324, 204)
	_details.fit_content = false
	_details.scroll_active = true
	_details_panel.add_child(_details)


func toggle_compact_hud() -> void:
	visible = not visible


func toggle_debug_details() -> void:
	if _details_panel != null:
		_details_panel.visible = not _details_panel.visible


func _refresh_status() -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	var def_mode := "unknown"
	if _mission != null and _mission.has_method("get_authoring_mode"):
		def_mode = String(_mission.call("get_authoring_mode"))
	var heat := GameState.get_mission_heat(mid)
	var perf: Dictionary = GameState.mission_performance.get(mid, {})
	var muts: Dictionary = GameState.mission_mutation_state.get(mid, {})
	var alert := String(GameState.get_mission_alert_state(mid))
	var route := GameState.has_scheme_card("louis_delivery_route")
	var real_scent := String(muts.get("real_scent_trail", "parking_garage"))
	var garage_code := String(muts.get("garage_code", "2174"))
	var extra_guard := false
	var extra_camera := false
	var attempt := {}
	var garage_beam_armed := true
	var garage_beam_triggered := false
	if _mission != null and _mission.has_method("get_runtime_debug_summary"):
		var runtime_summary: Dictionary = _mission.call("get_runtime_debug_summary")
		extra_guard = runtime_summary.get("extra_guard_active", false) == true
		extra_camera = runtime_summary.get("extra_camera_active", false) == true
		attempt = Dictionary(runtime_summary.get("attempt_runtime_state", {}))
		garage_beam_armed = runtime_summary.get("garage_beam_armed", true) == true
		garage_beam_triggered = runtime_summary.get("garage_beam_triggered", false) == true
	var detection_value := 0.0
	var mod := 1.0
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		detection_value = float(controller.get("alert_score"))
		mod = float(controller.get("player_detection_modifier"))
	_status.text = "mission=%s\nheat=%d attempts=%d\ncode=%s\ntiny=%d glow=%d polaroids=%d clues=%d poop_used=%d\nalert=%s alarms=%d wrong_code=%d guards=%d cameras=%d" % [
		mid,
		heat,
		int(GameState.failed_attempts.get(mid, 0)),
		garage_code,
		int(attempt.get("tiny_icon", 0)),
		int(attempt.get("glow_guy", 0)),
		int(attempt.get("polaroid", 0)),
		int(attempt.get("clues", 0)),
		int(attempt.get("poop_bags_used", 0)),
		alert,
		int(attempt.get("alarms", perf.get("alarms_triggered", 0))),
		int(attempt.get("wrong_code", perf.get("wrong_code_attempts", 0))),
		int(attempt.get("guards_alerted", perf.get("guards_alerted", 0))),
		int(attempt.get("cameras_triggered", perf.get("cameras_triggered", 0)))
	]
	_details.text = "authoring_mode=%s\nscene=%s\nactive_mutations=%s\nreal_scent_route=%s\nlouis_delivery_route=%s\nextra_guard=%s extra_camera=%s\ngarage_beam_armed=%s garage_beam_triggered=%s\ndetection=%.2f modifier=%.2f\nwrong_scent=%d collectibles=%d\n(F9 toggle details, F10 toggle compact HUD)" % [
		def_mode,
		String(get_tree().current_scene.scene_file_path),
		str(muts),
		real_scent,
		str(route),
		str(extra_guard),
		str(extra_camera),
		str(garage_beam_armed),
		str(garage_beam_triggered),
		detection_value,
		mod,
		int(perf.get("wrong_scent_trails_followed", 0)),
		int(perf.get("collectibles_found", 0))
	]


func _typed_collectible_summary() -> Dictionary:
	var out := {
		"polaroid": 0,
		"glow_guy": 0,
		"tiny_icon": 0,
	}
	for id in GameState.typed_collectibles.keys():
		var record: Dictionary = GameState.typed_collectibles.get(id, {})
		if record.get("discovered", false) != true:
			continue
		var group := String(record.get("collection_group", ""))
		var ctype := String(record.get("collectible_type", ""))
		if group.begins_with("polaroid") or ctype == "polaroid":
			out["polaroid"] = int(out["polaroid"]) + 1
		elif ctype == "glow_guy":
			out["glow_guy"] = int(out["glow_guy"]) + 1
		elif ctype == "tiny_icon":
			out["tiny_icon"] = int(out["tiny_icon"]) + 1
	return out


func _on_restart() -> void:
	var mid := mission_id if mission_id != "" else "taco_bell_drop"
	GameState.begin_mission_performance(mid)
	SceneManager.change_scene("res://scenes/missions_iso/TacoBellIso_Editable.tscn")


func _set_heat(heat: int) -> void:
	var mid := mission_id if mission_id != "" else "taco_bell_drop"
	GameState.failed_attempts[mid] = heat
	GameState.clear_mission_mutations(mid)
	EventBus.debug("Debug heat set: %s -> %d" % [mid, heat])


func _on_reroll_mutations() -> void:
	var mid := mission_id if mission_id != "" else "taco_bell_drop"
	GameState.clear_mission_mutations(mid)
	EventBus.debug("Debug mutations reroll requested for " + mid)


func _on_trigger_alarm() -> void:
	if _mission != null and _mission.has_method("trigger_alarm_test"):
		_mission.call("trigger_alarm_test")


func _on_spawn_extra_guard() -> void:
	if _mission != null and _mission.has_method("spawn_extra_guard_test"):
		_mission.call("spawn_extra_guard_test")


func _on_unlock_louis_route() -> void:
	GameState.unlock_scheme_card("louis_delivery_route", {"source": "iso_debug_panel"})


func _on_lock_louis_route() -> void:
	GameState.unlocked_scheme_cards.erase("louis_delivery_route")
	GameState.unlocked_cards.erase("louis_delivery_route")


func _on_grant_poop_bag() -> void:
	GameState.add_poop_bag()


func _on_clear_poop_bags() -> void:
	GameState.poop_bag_count = 0
	GameState.poop_bag_inventory["count"] = 0
	GameState.poop_bag_inventory["used_this_mission"] = 0
	GameState.poop_bag_inventory["collected_this_mission"] = 0


func _on_reset_perf() -> void:
	var mid := mission_id if mission_id != "" else "taco_bell_drop"
	GameState.begin_mission_performance(mid)


func _teleport_to(spawn_id: String) -> void:
	if _mission != null and _mission.has_method("teleport_player_to_spawn_id"):
		_mission.call("teleport_player_to_spawn_id", spawn_id)
