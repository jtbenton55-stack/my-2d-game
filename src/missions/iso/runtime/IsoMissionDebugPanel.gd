class_name IsoMissionDebugPanel
extends CanvasLayer

## Default F10 security view is authoring-focused. Set true to show FIX7 geometry legacy clutter.
const SHOW_LEGACY_SECURITY_DEBUG := false
## Which F10 section is expanded by default (others show one-line summaries when collapsed).
const DEBUG_FOCUS_SECTION := "collectibles"
const SHOW_COLLAPSED_DEBUG_SECTIONS := true
const QA_PANEL_TOGGLE_KEY := KEY_F12
const QA_PANEL_SCRIPT := preload("res://src/missions/iso/runtime/MissionQAChecklistPanel.gd")

@export var mission_id: String = ""
@export var debug_text_color := Color(1.0, 0.0, 0.0, 1.0)
@export var debug_outline_color := Color(0.0, 0.0, 0.0, 1.0)
@export var debug_outline_size := 3

var _mission: Node = null
var _compact_panel: Panel = null
var _details_panel: Panel = null
var _status: Label = null
var _details: RichTextLabel = null
var _qa_panel: Control = null


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
	## Hidden by default (0M-D5-02A); press F10 to show compact HUD, F9 for details.
	visible = false
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
	if Input.is_key_pressed(QA_PANEL_TOGGLE_KEY):
		if not get_meta("f8_latched", false):
			set_meta("f8_latched", true)
			toggle_qa_review()
	elif get_meta("f8_latched", false):
		set_meta("f8_latched", false)
	if not visible:
		return
	_refresh_status()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_compact_panel = Panel.new()
	_compact_panel.name = "CompactDebugHUD"
	_compact_panel.clip_contents = true
	_compact_panel.anchor_left = 0.0
	_compact_panel.anchor_top = 0.5
	_compact_panel.anchor_right = 0.0
	_compact_panel.anchor_bottom = 0.5
	_compact_panel.offset_left = 18.0
	_compact_panel.offset_top = -120.0
	_compact_panel.offset_right = 306.0
	_compact_panel.offset_bottom = 120.0
	_apply_dark_panel_style(_compact_panel)
	add_child(_compact_panel)
	var status_scroll := ScrollContainer.new()
	status_scroll.name = "StatusScroll"
	status_scroll.position = Vector2(6, 6)
	status_scroll.size = Vector2(284, 228)
	status_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_compact_panel.add_child(status_scroll)
	var compact := Label.new()
	compact.name = "Status"
	compact.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compact.custom_minimum_size = Vector2(268, 8)
	compact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status = compact
	status_scroll.add_child(compact)
	_apply_red_text_style(compact)
	_details_panel = Panel.new()
	_details_panel.name = "DebugDetailsPanel"
	_details_panel.position = Vector2(14, 190)
	_details_panel.size = Vector2(340, 220)
	_apply_dark_panel_style(_details_panel)
	add_child(_details_panel)
	_details = RichTextLabel.new()
	_details.position = Vector2(8, 8)
	_details.size = Vector2(324, 204)
	_details.fit_content = false
	_details.scroll_active = true
	_details_panel.add_child(_details)
	_apply_red_text_style(_details)
	_qa_panel = QA_PANEL_SCRIPT.new() as Control
	_qa_panel.call("set_mission", _mission)
	add_child(_qa_panel)


func toggle_compact_hud() -> void:
	visible = not visible


func toggle_debug_details() -> void:
	if _details_panel != null:
		_details_panel.visible = not _details_panel.visible


func toggle_qa_review() -> void:
	if _qa_panel == null:
		return
	if not visible and not _qa_panel.visible:
		visible = true
	_qa_panel.call("toggle_panel")


func _refresh_status() -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	var def_mode := "unknown"
	if _mission != null and _mission.has_method("get_authoring_mode"):
		def_mode = String(_mission.call("get_authoring_mode"))
	var heat := GameState.get_mission_heat(mid)
	var perf: Dictionary = GameState.mission_performance.get(mid, {})
	var muts: Dictionary = GameState.mission_mutation_state.get(mid, {})
	var alert := String(GameState.get_mission_alert_state(mid))
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		alert = String(controller.get("alert_state"))
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
	if controller != null:
		detection_value = float(controller.get("alert_score"))
		mod = float(controller.get("player_detection_modifier"))
	var p0j := _find_phase0j_adapter()
	var p0j_counts := ""
	if p0j != null and p0j.has_method("get_all_counts"):
		var ac: Dictionary = p0j.call("get_all_counts")
		var bits: Array[String] = []
		for k in ["poop_bag", "bag", "objective_bag", "evidence_clue", "polaroid", "glow_guy", "tiny_icon"]:
			bits.append("%s=%d" % [k, int(ac.get(k, 0))])
		p0j_counts = "\nphase0j_adapter " + " ".join(bits)
	var pbi := GameState.poop_bag_inventory
	var poop_line := "\npoop_inv count=%d collected_run=%d used_run=%d" % [
		int(pbi.get("count", 0)),
		int(pbi.get("collected_this_mission", 0)),
		int(pbi.get("used_this_mission", 0)),
	]
	var sch_snap := MissionSchemeBridge.get_scheme_snapshot(mid)
	var scheme_for_details := "\n" + MissionSchemeCardFormatter.format_scheme_snapshot_debug_block(sch_snap)
	var obj_line := "\nquest_line=%s" % String(QuestManager.get_current_objective(mid))
	var sec_lines := ""
	if _mission != null and _mission.has_method("get_runtime_debug_summary"):
		var rsum: Dictionary = _mission.call("get_runtime_debug_summary")
		sec_lines = _build_authoring_security_f10_lines(rsum, heat, alert, mid, garage_code, controller)
	_status.text = "mission=%s\nheat=%d attempts=%d\ncode=%s\ntiny=%d glow=%d polaroids=%d clues=%d poop_used=%d\nalert=%s alarms=%d wrong_code=%d guards=%d cameras=%d%s%s%s%s" % [
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
		int(attempt.get("cameras_triggered", perf.get("cameras_triggered", 0))),
		p0j_counts,
		poop_line,
		sec_lines,
		obj_line,
	]
	_apply_red_text_style(_status)
	_details.text = "authoring_mode=%s\nscene=%s\nactive_mutations=%s\nreal_scent_route=%s\nlouis_delivery_route=%s\nextra_guard=%s extra_camera=%s\ngarage_beam_armed=%s garage_beam_triggered=%s\ndetection=%.2f modifier=%.2f\nwrong_scent=%d collectibles=%d\n(F9 toggle details, F10 toggle compact HUD)%s" % [
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
		int(perf.get("collectibles_found", 0)),
		scheme_for_details,
	]
	_apply_red_text_style(_details)
	call_deferred("_fit_compact_status_height")


func _build_authoring_security_f10_lines(
	rsum: Dictionary,
	heat: int,
	alert: String,
	mid: String,
	garage_code: String,
	_controller: Node,
) -> String:
	var blocks: PackedStringArray = []
	blocks.append("\n--- Mission ---")
	blocks.append("Mission: %s  Heat: %d  Alert: %s  Code: %s" % [mid, heat, _dash_if_empty(alert), garage_code])
	blocks.append(
		_format_debug_section(
			"security",
			"Security Authoring",
			"root %s beams %d cameras %d spawns %d areas %d"
			% [
				_yes_no(rsum.get("d6_02_security_authoring_root_found", false)),
				int(rsum.get("d6_02_security_authoring_beam_count", 0)),
				int(rsum.get("d6_02_authored_camera_count", 0)),
				int(rsum.get("d6_02_authored_guard_spawn_count", 0)),
				int(rsum.get("d6_03_authored_area_trigger_count", 0)),
			],
			_build_security_authoring_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"events",
			"Event Router",
			"router %s events %d"
			% [
				_yes_no(rsum.get("d6_03_security_router_active", false)),
				int(rsum.get("d6_03_registered_event_count", 0)),
			],
			_build_event_router_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"ambush",
			"AMBUSH Beam",
			"trips %d source %s"
			% [
				int(rsum.get("d6_02_ambush_beam_trip_count", 0)),
				String(rsum.get("d6_02_ambush_beam_source", "unknown")),
			],
			_build_ambush_beam_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"camera",
			"Authored Camera",
			"runtime %d last %s"
			% [
				int(rsum.get("d6_04_runtime_authored_camera_count", 0)),
				_dash_if_empty(String(rsum.get("d6_04_last_camera_id", ""))),
			],
			_build_authored_camera_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"guard",
			"Guard Spawn / AI",
			"active %d/%d last %s"
			% [
				int(rsum.get("security_response_spawn_count", 0)),
				int(rsum.get("security_spawn_cap", 0)),
				_dash_if_empty(String(rsum.get("d6_03_last_guard_spawn_result", ""))),
			],
			_build_guard_spawn_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"effects",
			"Downstream Effects",
		"total %d sets %d door %d"
		% [
			int(rsum.get("d6_05_effect_author_count", 0)),
			int(rsum.get("d6_05_effect_set_count", 0)),
			int(rsum.get("d6_05_door_effect_count", 0)),
		],
			_build_downstream_effects_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"door",
			"Door Lock Test (D6-05D)",
			"door %s phys %s"
			% [
				_dash_if_empty(String(rsum.get("d6_05a_test_door_lock_state", ""))),
				_yes_no(rsum.get("d6_05a_test_door_collision_enabled", false)),
			],
			_build_door_lock_detail_lines(rsum)
		)
	)
	blocks.append(
		_format_debug_section(
			"collectibles",
			"Collectible Authoring",
			"pending %d committed %d path %s"
			% [
				int(rsum.get("d6_06_pending_collectible_count", 0)),
				int(rsum.get("d6_06_committed_collectible_count", 0)),
				_dash_if_empty(String(rsum.get("d6_06_runtime_path_kind", "unknown"))),
			],
			_build_collectible_authoring_detail_lines(rsum)
		)
	)
	blocks.append("\nManual test: enter authored camera cone -> camera alarm + guard + downstream effect.")
	if SHOW_LEGACY_SECURITY_DEBUG:
		blocks.append(
			_format_debug_section(
				"legacy",
				"Legacy Security (FIX7)",
				"beam %s" % String(rsum.get("beam_status", "unknown")),
				_build_legacy_security_detail_lines(rsum)
			)
		)
	return "\n".join(blocks)


func _section_is_open(section_id: String) -> bool:
	if not SHOW_COLLAPSED_DEBUG_SECTIONS:
		return true
	return section_id == DEBUG_FOCUS_SECTION


func _format_debug_section(
	section_id: String,
	title: String,
	collapsed_summary: String,
	detail_lines: PackedStringArray
) -> String:
	if _section_is_open(section_id):
		var open_lines: PackedStringArray = []
		open_lines.append("[-] %s" % title)
		open_lines.append_array(detail_lines)
		return "\n".join(open_lines)
	return "[+] %s: %s" % [title, collapsed_summary]


func _build_security_authoring_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append(
		"Root: %s  beams %d  cameras %d  spawns %d  patrols %d  areas %d"
		% [
			_yes_no(rsum.get("d6_02_security_authoring_root_found", false)),
			int(rsum.get("d6_02_security_authoring_beam_count", 0)),
			int(rsum.get("d6_02_authored_camera_count", 0)),
			int(rsum.get("d6_02_authored_guard_spawn_count", 0)),
			int(rsum.get("d6_02_authored_patrol_route_count", 0)),
			int(rsum.get("d6_03_authored_area_trigger_count", 0)),
		]
	)
	return lines


func _build_event_router_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var listener_counts: Dictionary = rsum.get("d6_03_router_listener_counts", {}) as Dictionary
	lines.append(
		"Router: %s | events %d | %s"
		% [
			_yes_no(rsum.get("d6_03_security_router_active", false)),
			int(rsum.get("d6_03_registered_event_count", 0)),
			_format_listener_event_names(listener_counts),
		]
	)
	lines.append("Last event: %s" % _dash_if_empty(String(rsum.get("d6_03_last_dispatched_event", ""))))
	lines.append(
		"Listeners: called %d  handled %d  rejected %d"
		% [
			int(rsum.get("d6_04_last_event_listeners_called", 0)),
			int(rsum.get("d6_04_last_event_listeners_handled", 0)),
			int(rsum.get("d6_04_last_event_listeners_rejected", 0)),
		]
	)
	lines.append("Reject: %s" % _format_rejection_reasons(rsum.get("d6_04_last_event_rejection_reasons", [])))
	lines.append("Duplicate spawn avoided: %s" % _yes_no(rsum.get("d6_03_duplicate_spawn_avoided", false)))
	return lines


func _build_ambush_beam_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var beam_source := String(rsum.get("d6_02_ambush_beam_source", "unknown"))
	lines.append("Source: %s  trips: %d" % [beam_source, int(rsum.get("d6_02_ambush_beam_trip_count", 0))])
	var beam_author := String(rsum.get("d6_02_ambush_beam_author_path", ""))
	lines.append("Beam id: %s  Event: ambush_beam_tripped" % _short_path(beam_author))
	lines.append("Author: %s" % _short_path(beam_author))
	var trig_sz: Vector2 = rsum.get("d6_02_ambush_beam_trigger_size", Vector2.ZERO)
	lines.append(
		"Visual H: %.0f  Trigger: %.0fx%.0f"
		% [
			float(rsum.get("d6_02_ambush_beam_visual_height", 0.0)),
			trig_sz.x,
			trig_sz.y,
		]
	)
	lines.append(
		"Spawn: %s (%s)  beam handled: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_03_last_guard_spawn_result", ""))),
			_dash_if_empty(String(rsum.get("d6_03_last_guard_spawn_reason", ""))),
			_yes_no(rsum.get("d6_04_last_beam_event_handled", false)),
		]
	)
	lines.append("Direct fallback: %s" % _beam_direct_fallback_label(rsum))
	return lines


func _build_authored_camera_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append(
		"Runtime cameras: %d  active: %s"
		% [
			int(rsum.get("d6_04_runtime_authored_camera_count", 0)),
			_dash_if_empty(String(rsum.get("d6_04_last_camera_id", ""))),
		]
	)
	lines.append(
		"Parity: %s  class: %s  parent: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_04_authored_camera_parity_target", "CAM_market_01"))),
			_dash_if_empty(String(rsum.get("d6_04_authored_camera_runtime_class", ""))),
			_short_path(String(rsum.get("d6_04_authored_camera_parent_path", ""))),
		]
	)
	lines.append(
		"Camera live: enabled %s  shape %s  in cone %s  detect %.2f"
		% [
			_yes_no(rsum.get("d6_04_authored_camera_enabled", false)),
			_yes_no(rsum.get("d6_04_authored_camera_has_shape", false)),
			_yes_no(rsum.get("d6_04_authored_camera_player_in_cone", false)),
			float(rsum.get("d6_04_authored_camera_detection_value", 0.0)),
		]
	)
	var cam_alarm := String(rsum.get("d6_04_last_camera_alarm_event", ""))
	if cam_alarm == "":
		cam_alarm = "test_camera_alarm"
	lines.append("Alarm event: %s" % cam_alarm)
	lines.append(
		"Detect: %s  Alarm: %s  handled: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_04_last_camera_detect_event", ""))),
			_dash_if_empty(String(rsum.get("d6_04_last_camera_alarm_event", ""))),
			_yes_no(rsum.get("d6_04_last_camera_alarm_handled", false)),
		]
	)
	var cam_spawn := "-"
	if String(rsum.get("d6_03_last_dispatched_event", "")) == cam_alarm:
		cam_spawn = "%s (%s)" % [
			String(rsum.get("d6_03_last_guard_spawn_result", "-")),
			String(rsum.get("d6_03_last_guard_spawn_reason", "")),
		]
	lines.append("Camera spawn: %s" % cam_spawn)
	lines.append("Direct fallback: %s" % _camera_direct_fallback_label(rsum, cam_alarm))
	return lines


func _build_guard_spawn_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("Author: %s" % _dash_if_empty(String(rsum.get("d6_03_last_guard_spawn_author_id", ""))))
	lines.append(
		"Result: %s  reason: %s  spawned: %d"
		% [
			_dash_if_empty(String(rsum.get("d6_03_last_guard_spawn_result", ""))),
			_dash_if_empty(String(rsum.get("d6_03_last_guard_spawn_reason", ""))),
			int(rsum.get("d6_03_last_spawned_guard_count", 0)),
		]
	)
	lines.append(
		"Active guards: %d / cap %d"
		% [
			int(rsum.get("security_response_spawn_count", 0)),
			int(rsum.get("security_spawn_cap", 0)),
		]
	)
	lines.append(
		"Behavior: %s  fallback: %s  patrol route: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_04_last_guard_initial_behavior", ""))),
			_dash_if_empty(String(rsum.get("d6_04_last_guard_fallback_behavior", ""))),
			_yes_no(rsum.get("d6_04_last_guard_patrol_route_assigned", false)),
		]
	)
	lines.append("Force chase: %s" % _force_chase_label(rsum))
	lines.append(
		"Authored chase: %s  fallback entered: %s  cone %.0f (aggro %.0f)"
		% [
			_yes_no(rsum.get("d6_04_authored_guard_force_chase", false)),
			_yes_no(rsum.get("d6_04_authored_guard_fallback_entered", false)),
			float(rsum.get("d6_04_authored_guard_debug_cone_range", 0.0)),
			float(rsum.get("d6_04_authored_guard_aggro_range", 0.0)),
		]
	)
	return lines


func _build_downstream_effects_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append(
		"Effects: %d (sets %d door %d lockdown %d objective %d toggle %d)"
		% [
			int(rsum.get("d6_05_effect_author_count", 0)),
			int(rsum.get("d6_05_effect_set_count", 0)),
			int(rsum.get("d6_05_door_effect_count", 0)),
			int(rsum.get("d6_05_lockdown_effect_count", 0)),
			int(rsum.get("d6_05_objective_effect_count", 0)),
			int(rsum.get("d6_05_node_toggle_effect_count", 0)),
		]
	)
	lines.append(
		"Last: %s / %s on %s"
		% [
			_dash_if_empty(String(rsum.get("d6_05_last_effect_type", ""))),
			_dash_if_empty(String(rsum.get("d6_05_last_effect_id", ""))),
			_dash_if_empty(String(rsum.get("d6_05_last_effect_event", ""))),
		]
	)
	lines.append(
		"Result: %s (%s) target: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_05_last_effect_result", ""))),
			_dash_if_empty(String(rsum.get("d6_05_last_effect_reason", ""))),
			_short_path(String(rsum.get("d6_05_last_effect_target", ""))),
		]
	)
	lines.append(
		"Lockdown: %s  alert: %s"
		% [
			_yes_no(rsum.get("d6_05_lockdown_active", false)),
			_dash_if_empty(String(rsum.get("d6_05_lockdown_alert_state", ""))),
		]
	)
	if int(rsum.get("d6_05_effect_set_count", 0)) > 0 or String(rsum.get("d6_05_last_effect_set_id", "")) != "":
		lines.append(
			"EffectSet: %s applied %d failed %d"
			% [
				_dash_if_empty(String(rsum.get("d6_05_last_effect_set_id", ""))),
				int(rsum.get("d6_05_last_effect_set_applied_count", 0)),
				int(rsum.get("d6_05_last_effect_set_failed_count", 0)),
			]
		)
		lines.append("Chain: %s" % _format_debug_chain(rsum.get("d6_05_last_effect_chain", [])))
	return lines


func _build_door_lock_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var door_visual := String(rsum.get("d6_05a_test_door_lock_state", ""))
	var door_phys := _yes_no(rsum.get("d6_05a_test_door_collision_enabled", false))
	lines.append(
		"Test door: %s  visual: %s  physics: %s  rot: %.0f deg"
		% [
			_short_path(String(rsum.get("d6_05a_test_door_path", ""))),
			_dash_if_empty(door_visual),
			door_phys,
			float(rsum.get("d6_05a_test_door_orientation_degrees", 0.0)),
		]
	)
	lines.append(
		"Collision: enabled=%s  layer=%s"
		% [
			door_phys,
			str(rsum.get("d6_05a_test_door_collision_layer", 0)),
		]
	)
	if door_visual == "locked" and not bool(rsum.get("d6_05a_test_door_collision_enabled", false)):
		lines.append("WARNING: visual locked but collision disabled")
	elif door_visual == "unlocked" and bool(rsum.get("d6_05a_test_door_collision_enabled", false)):
		lines.append("WARNING: visual unlocked but collision enabled")
	lines.append(
		"Last zone: %s -> %s"
		% [
			_dash_if_empty(String(rsum.get("d6_05c_last_zone_id", ""))),
			_dash_if_empty(String(rsum.get("d6_05c_last_zone_event", ""))),
		]
	)
	lines.append(
		"Last door event: %s  effect: %s  action: %s  result: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_05_last_door_event", rsum.get("d6_05_last_effect_event", "")))),
			_dash_if_empty(String(rsum.get("d6_05_last_door_effect_id", ""))),
			_dash_if_empty(String(rsum.get("d6_05_last_door_action", ""))),
			_dash_if_empty(String(rsum.get("d6_05_last_door_lock_state", ""))),
		]
	)
	lines.append("D6-05D: cyan LOCK ZONE or camera alarm locks (red + blocks); lime UNLOCK ZONE unlocks.")
	lines.append("AMBUSH does NOT unlock. Rotate door in editor (15 deg snap).")
	lines.append("Find: D6-05A TEST LOCK DOOR near security proof (~9280,200).")
	return lines


func _build_collectible_authoring_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append(
		"Runtime path: %s  parent: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_06_runtime_path_kind", "unknown"))),
			_short_path(String(rsum.get("d6_06_runtime_parent_path", ""))),
		]
	)
	lines.append(
		"Root: %s  authors: %d  spawned: %d"
		% [
			_yes_no(rsum.get("d6_06_authoring_root_found", false)),
			int(rsum.get("d6_06_collectible_author_count", 0)),
			int(rsum.get("d6_06_runtime_pickup_count", 0)),
		]
	)
	lines.append(
		"Pending: %d (poop %d case_cash total %d x%d photo %d tiny %d glow %d clue %d)  committed: %d"
		% [
			int(rsum.get("d6_06_pending_collectible_count", 0)),
			int(rsum.get("d6_06_pending_poop", 0)),
			int(rsum.get("d6_06_pending_case_cash_amount", 0)),
			int(rsum.get("d6_06_pending_case_cash_instances", 0)),
			int(rsum.get("d6_06_pending_polaroid", 0)),
			int(rsum.get("d6_06_pending_tiny_icon", 0)),
			int(rsum.get("d6_06_pending_glow_guy", 0)),
			int(rsum.get("d6_06_pending_clue", 0)),
			int(rsum.get("d6_06_committed_collectible_count", 0)),
		]
	)
	lines.append(
		"Authors: poop=%d legacy_money_alias=%d case_cash=%d photo=%d tiny=%d glow=%d clue=%d"
		% [
			int(rsum.get("d6_06_poop_author_count", 0)),
			int(rsum.get("d6_06_money_author_count", 0)),
			int(rsum.get("d6_06_case_cash_author_count", 0)),
			int(rsum.get("d6_06_polaroid_author_count", 0)),
			int(rsum.get("d6_06_tiny_icon_author_count", 0)),
			int(rsum.get("d6_06_glow_guy_author_count", 0)),
			int(rsum.get("d6_06_clue_author_count", 0)),
		]
	)
	lines.append(
		"Last pickup: %s (%s) -> %s"
		% [
			_dash_if_empty(String(rsum.get("d6_06_last_authored_pickup_id", ""))),
			_dash_if_empty(String(rsum.get("d6_06_last_authored_pickup_type", ""))),
			_dash_if_empty(String(rsum.get("d6_06_last_authored_pickup_result", ""))),
		]
	)
	lines.append(
		"Last: %s via %s  hideout: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_06_last_authored_pickup_result", ""))),
			_dash_if_empty(String(rsum.get("d6_06_last_pickup_source", "interact"))),
			_dash_if_empty(String(rsum.get("d6_06_hideout_sync_status", ""))),
		]
	)
	lines.append(
		"Poop inv: %d  committed Case Cash: %d  bank(pending hub): %d  proof flags: %d"
		% [
			int(rsum.get("d6_06_poop_count", 0)),
			int(rsum.get("d6_06_money_proof_cash", 0)),
			int(rsum.get("d6_06_case_cash_bank", 0)),
			int(rsum.get("d6_06_proof_flags", 0)),
		]
	)
	lines.append(
		"Hideout sync: %s  clues: %s  glow shelf: %s"
		% [
			_dash_if_empty(String(rsum.get("d6_06_hideout_sync_status", ""))),
			_dash_if_empty(String(rsum.get("d6_06_clue_corkboard_sync", ""))),
			_dash_if_empty(String(rsum.get("d6_06_glow_guy_shelf_sync", ""))),
		]
	)
	lines.append(
		"Duplicate author IDs blocked: %d"
		% [int(rsum.get("d6_06_duplicate_author_id_count", 0))]
	)
	lines.append("Find: D6-06/07 proof cluster SW of door lock (~8950,620). Walk into colored circles.")
	return lines


func _build_legacy_security_detail_lines(rsum: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray(_build_legacy_security_f10_lines(rsum, 0).split("\n"))
	return lines


func _build_legacy_security_f10_lines(rsum: Dictionary, _heat: int) -> String:
	var lines: PackedStringArray = []
	lines.append("\n--- Legacy Security (FIX7) ---")
	lines.append(
		"Beam status: %s  FIX7F mode: %s  fallback: %s"
		% [
			String(rsum.get("beam_status", "unknown")),
			String(rsum.get("fix7f_mode", "-")),
			_yes_no(rsum.get("fix7f_fallback_used", false)),
		]
	)
	lines.append(
		"choke_x %.0f  probe_y %.0f  mismatch %.1fpx"
		% [
			float(rsum.get("fix7f_chosen_x", 0.0)),
			float(rsum.get("fix7f_chosen_probe_y", 0.0)),
			float(rsum.get("fix7e_visual_trigger_mismatch_px", -1.0)),
		]
	)
	lines.append("Anchor: %s" % _short_path(String(rsum.get("ambush_beam_anchor_path", ""))))
	var ag: Array = rsum.get("security_active_guards_preview", []) as Array
	if ag.is_empty():
		lines.append("Active guards: (none)")
	else:
		lines.append("Active guards:")
		var shown := mini(ag.size(), 4)
		for i in range(shown):
			lines.append("  %s" % _short_path(String(ag[i])))
		if ag.size() > shown:
			lines.append("  ... +%d more" % (ag.size() - shown))
	return "\n".join(lines)


func _yes_no(value: Variant) -> String:
	return "yes" if value == true else "no"


func _dash_if_empty(text: String) -> String:
	var t := text.strip_edges()
	return t if t != "" else "-"


func _short_path(path: String) -> String:
	var t := path.strip_edges()
	if t == "":
		return "-"
	var parts := t.split("/")
	return parts[parts.size() - 1] if parts.size() > 0 else t


func _format_listener_event_names(counts: Dictionary) -> String:
	if counts.is_empty():
		return "none"
	var names: PackedStringArray = []
	for key in counts.keys():
		names.append("%s(%s)" % [String(key), str(counts[key])])
	return ", ".join(names)


func _format_rejection_reasons(reasons: Variant) -> String:
	if not (reasons is Array):
		return "-"
	var arr := reasons as Array
	if arr.is_empty():
		return "-"
	var first := String(arr[0])
	if ":" in first:
		return first.get_slice(":", -1).strip_edges()
	return first


func _format_debug_chain(chain_value: Variant) -> String:
	var parts := PackedStringArray()
	if chain_value is PackedStringArray:
		parts = chain_value as PackedStringArray
	elif chain_value is Array:
		for item in (chain_value as Array):
			var text := String(item).strip_edges()
			if text != "":
				parts.append(text)
	if parts.is_empty():
		return "-"
	return " -> ".join(parts)


func _beam_direct_fallback_label(rsum: Dictionary) -> String:
	if rsum.get("d6_03_beam_direct_fallback_suppressed", false) == true:
		return "suppressed"
	var src := String(rsum.get("d6_02_ambush_beam_source", ""))
	if src.findn("fallback") != -1:
		return "used"
	if rsum.get("d6_03_beam_event_route_used", false) == true:
		return "not needed"
	return "unknown"


func _camera_direct_fallback_label(rsum: Dictionary, alarm_event: String) -> String:
	if rsum.get("d6_03_security_router_active", false) != true:
		return "unknown"
	var counts: Dictionary = rsum.get("d6_03_router_listener_counts", {}) as Dictionary
	if not counts.has(alarm_event):
		return "not needed"
	if String(rsum.get("d6_03_last_dispatched_event", "")) == alarm_event:
		if rsum.get("d6_04_last_event_listeners_called", 0):
			return "suppressed"
	return "unknown"


func _force_chase_label(rsum: Dictionary) -> String:
	var init := String(rsum.get("d6_04_last_guard_initial_behavior", "")).strip_edges().to_lower()
	if init == "attack_player":
		return "yes"
	if init == "":
		return "-"
	return "no"


func _find_phase0j_adapter() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Phase0JMissionStateAdapter", true, false)


func _fit_compact_status_height() -> void:
	if _status == null:
		return
	# Godot 4 Label has no get_content_height() (that is RichTextLabel). Fit using line metrics.
	var lines: int = maxi(1, _status.get_line_count())
	var line_h: float = float(_status.get_line_height())
	var h: float = line_h * float(lines) + 8.0
	_status.custom_minimum_size.y = maxf(40.0, h)


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


func _apply_dark_panel_style(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.72)
	style.border_color = Color(0.5, 0, 0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)


func _apply_red_text_style(control: Control) -> void:
	if control is Label:
		var label := control as Label
		label.add_theme_color_override("font_color", debug_text_color)
		label.add_theme_color_override("font_outline_color", debug_outline_color)
		label.add_theme_constant_override("outline_size", debug_outline_size)
	elif control is RichTextLabel:
		var rich := control as RichTextLabel
		rich.add_theme_color_override("default_color", debug_text_color)
		rich.add_theme_color_override("font_outline_color", debug_outline_color)
		rich.add_theme_constant_override("outline_size", debug_outline_size)


func _on_restart() -> void:
	var mid := mission_id if mission_id != "" else "taco_bell_drop"
	GameState.begin_mission_performance(mid)
	SceneManager.change_scene(MissionSceneResolver.resolve_playable_scene_path(mid))


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
