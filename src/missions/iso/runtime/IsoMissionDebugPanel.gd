class_name IsoMissionDebugPanel
extends CanvasLayer

@export var mission_id: String = ""
@export var debug_text_color := Color(1.0, 0.0, 0.0, 1.0)
@export var debug_outline_color := Color(0.0, 0.0, 0.0, 1.0)
@export var debug_outline_size := 3

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
	var sec_lines := "\n--- Security ---"
	sec_lines += "\nCameras: stand in cone until alert builds; reinforcements use live cap (not stale counter)."
	sec_lines += "\nWrong code: keypad; wrong_code / wrong_code_alarm in counts below."
	if controller != null and controller.has_method("get_security_event_adapter"):
		var adapter: Variant = controller.call("get_security_event_adapter")
		if adapter != null and adapter.has_method("get_security_debug_snapshot"):
			var ssec: Dictionary = adapter.call("get_security_debug_snapshot")
			var kinds: Dictionary = ssec.get("counters_by_kind", {}) as Dictionary
			sec_lines += "\nHeat %d/5  failed_runs %d  alert %s" % [
				int(ssec.get("heat", heat)),
				int(ssec.get("failed_attempts", int(GameState.failed_attempts.get(mid, 0)))),
				String(ssec.get("alert_state", alert)),
			]
			sec_lines += "\nCam det %d  wrong %d  wrong_alm %d  beam %d  reinf %d  fail_heat_evt %d" % [
				int(kinds.get("camera_detection", 0)),
				int(kinds.get("wrong_code", 0)),
				int(kinds.get("wrong_code_alarm", 0)),
				int(kinds.get("beam_trip", 0)),
				int(kinds.get("reinforcement_spawned", 0)),
				int(kinds.get("mission_failure_heat", 0)),
			]
	if _mission != null and _mission.has_method("get_runtime_debug_summary"):
		var rsum: Dictionary = _mission.call("get_runtime_debug_summary")
		## D6-01-FIX6A: show reinforcement cooldown and reserved count.
		sec_lines += "\nCooldown: %.1fs  Heat %d/5" % [
			float(rsum.get("reinforcement_cooldown_sec", 6.0)),
			int(rsum.get("heat_profile", {}).get("heat", heat)),
		]
		sec_lines += "\nLast reinforcement: %s  (%s)" % [
			String(rsum.get("last_reinforcement_source", "-")),
			String(rsum.get("last_reinforcement_result", "-")),
		]
		sec_lines += "\nGuards: functional %d / raw %d / invalid %d / cap %d / queued %d / reserved %d" % [
			int(rsum.get("security_response_spawn_count", 0)),
			int(rsum.get("security_response_spawn_count_raw", int(rsum.get("security_response_spawn_count", 0)))),
			int(rsum.get("invalid_offmap_security_guard_count", 0)),
			int(rsum.get("security_spawn_cap", 0)),
			int(rsum.get("security_spawn_pending_count", 0)),
			int(rsum.get("security_reserved_count", 0)),
		]
		## D6-01-FIX6B: show lifecycle stats (active/searching/dormant/removed).
		sec_lines += "\nLifecycle: active %d / searching %d / dormant %d / removed %d" % [
			int(rsum.get("lifecycle_active", 0)),
			int(rsum.get("lifecycle_searching", 0)),
			int(rsum.get("lifecycle_dormant", 0)),
			int(rsum.get("lifecycle_removed_total", 0)),
		]
		sec_lines += "\nCameras in tree: %d moving / %d total" % [
			int(rsum.get("security_cameras_moving", 0)),
			int(rsum.get("security_cameras_total", 0)),
		]
		sec_lines += "\nActive security guards:"
		var ag: Array = rsum.get("security_active_guards_preview", []) as Array
		if ag.is_empty():
			sec_lines += " (none)"
		else:
			for line in ag:
				sec_lines += "\n  %s" % String(line)
		var probe: Dictionary = rsum.get("d6_fix6_spawn_probe", rsum.get("d6_fix5_spawn_probe", {})) as Dictionary
		sec_lines += "\nLast spawn: %s / %s" % [
			String(probe.get("source_id", "-")),
			String(probe.get("spawn_mode", "-")),
		]
		sec_lines += "\n  req %s  chosen %s  actual %s" % [
			str(probe.get("requested_position", "-")),
			str(probe.get("chosen_position", "-")),
			str(probe.get("actual_position", "-")),
		]
		sec_lines += "\n  result %s  reason %s  dist %d" % [
			String(probe.get("result", "-")),
			String(probe.get("reject_reason", "")),
			int(probe.get("last_spawn_distance_to_player", -1)),
		]
		## D6-01-FIX6B: search net info.
		sec_lines += "\n--- Search Net (FIX6B) ---"
		sec_lines += "\nHeat %d/5  Radius %d  Role %s  Ordinal %d" % [
			int(rsum.get("search_net_heat", heat)),
			int(rsum.get("search_net_triangle_radius_by_heat", 140)),
			String(rsum.get("search_net_last_role", "-")),
			int(rsum.get("search_net_last_ordinal", -1)),
		]
		sec_lines += "\nRoles: %s" % str(rsum.get("search_net_roles_by_heat", "territorial/pursuer/flanker/choke/sentry"))
		sec_lines += "\nSearch-net handoff active: %s" % str(rsum.get("search_net_local_route_real_handoff", false))
		## D6-01-FIX6A: beam locator with distance/direction.
		sec_lines += "\n--- Beam Locator ---"
		var beam_dist: float = float(rsum.get("beam_distance_from_player", -1.0))
		var beam_dir: String = str(rsum.get("beam_direction_from_player", "unknown"))
		sec_lines += "\nBeam: %s  dist %.0fpx  direction: %s" % [
			str(rsum.get("beam_status", "unknown")),
			beam_dist,
			beam_dir,
		]
		sec_lines += "\nAMBUSH anchor found: %s" % str(rsum.get("ambush_beam_anchor_found", false))
		sec_lines += "\nAMBUSH resolve source: %s" % str(rsum.get("ambush_beam_anchor_resolve_source", "missing"))
		sec_lines += "\nAMBUSH anchor path: %s" % str(rsum.get("ambush_beam_anchor_path", "missing"))
		sec_lines += "\nanchor %s  visual %s  trigger %s  mismatch %.1fpx" % [
			str(rsum.get("ambush_beam_anchor_position", Vector2.ZERO)),
			str(rsum.get("ambush_beam_visual_center", Vector2.ZERO)),
			str(rsum.get("ambush_beam_trigger_center", Vector2.ZERO)),
			float(rsum.get("ambush_beam_visual_trigger_mismatch_px", -1.0)),
		]
		sec_lines += "\n%s" % str(rsum.get("beam_f10_plain", "Beam: red line before bag room."))
		sec_lines += "\n%s" % str(rsum.get("beam_f10_how_to_test", "Walk through red line to test."))
		sec_lines += "\n%s" % str(rsum.get("heat_restart_audit_note", ""))
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
