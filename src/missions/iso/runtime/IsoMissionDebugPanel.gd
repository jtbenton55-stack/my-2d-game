class_name IsoMissionDebugPanel
extends CanvasLayer

@export var mission_id: String = ""

var _mission: Node = null
var _panel: Panel = null
var _status: RichTextLabel = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_mission = get_tree().current_scene
	_build_ui()
	set_process(true)
	visible = OS.is_debug_build()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		visible = not visible
	if not visible:
		return
	_refresh_status()


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.name = "DebugPanel"
	_panel.size = Vector2(460, 620)
	_panel.position = Vector2(20, 20)
	add_child(_panel)
	var root := VBoxContainer.new()
	root.name = "VBox"
	root.anchors_preset = Control.PRESET_FULL_RECT
	root.offset_left = 8
	root.offset_top = 8
	root.offset_right = -8
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 4)
	_panel.add_child(root)
	_status = RichTextLabel.new()
	_status.custom_minimum_size = Vector2(430, 260)
	_status.fit_content = true
	_status.scroll_active = true
	root.add_child(_status)
	_add_button(root, "Restart Taco Bell Iso", _on_restart)
	_add_button(root, "Heat 0", func(): _set_heat(0))
	_add_button(root, "Heat 1", func(): _set_heat(1))
	_add_button(root, "Heat 2", func(): _set_heat(2))
	_add_button(root, "Heat 3", func(): _set_heat(3))
	_add_button(root, "Reroll Mutations", _on_reroll_mutations)
	_add_button(root, "Trigger Alarm", _on_trigger_alarm)
	_add_button(root, "Spawn Extra Guard", _on_spawn_extra_guard)
	_add_button(root, "Unlock Louis Delivery Route", _on_unlock_louis_route)
	_add_button(root, "Lock Louis Delivery Route", _on_lock_louis_route)
	_add_button(root, "Grant Poop Bag", _on_grant_poop_bag)
	_add_button(root, "Clear Poop Bags", _on_clear_poop_bags)
	_add_button(root, "Reset Taco Bell Performance", _on_reset_perf)
	_add_button(root, "Teleport: Start", func(): _teleport_to("start_main"))
	_add_button(root, "Teleport: Delivery Hub", func(): _teleport_to("delivery_hub"))
	_add_button(root, "Teleport: Garage 1", func(): _teleport_to("garage_1"))
	_add_button(root, "Teleport: Code Gate", func(): _teleport_to("code_gate"))
	_add_button(root, "Teleport: Ambush", func(): _teleport_to("ambush"))
	_add_button(root, "Teleport: Bag Recovery", func(): _teleport_to("bag_recovery"))
	_add_button(root, "Teleport: Exit", func(): _teleport_to("exit"))


func _add_button(parent: VBoxContainer, text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 24)
	button.pressed.connect(on_pressed)
	parent.add_child(button)


func _refresh_status() -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	var def_mode := "unknown"
	if _mission != null and _mission.has_method("get_authoring_mode"):
		def_mode = String(_mission.call("get_authoring_mode"))
	var heat := GameState.get_mission_heat(mid)
	var perf: Dictionary = GameState.mission_performance.get(mid, {})
	var muts: Dictionary = GameState.mission_mutation_state.get(mid, {})
	var alert := String(GameState.get_mission_alert_state(mid))
	var glow := GameState.typed_collectibles.has("taco_bell_glow_guys")
	var icon := GameState.typed_collectibles.has("louis_tiny_icon_delivery_bag")
	var route := GameState.has_scheme_card("louis_delivery_route")
	var cards := GameState.unlocked_scheme_cards.keys()
	var detection_value := 0.0
	var mod := 1.0
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		detection_value = float(controller.get("alert_score"))
		mod = float(controller.get("player_detection_modifier"))
	_status.text = "mission=%s\nscene=%s\nauthoring_mode=%s\nheat=%d failed_attempts=%d\nactive_mutations=%s\ncards=%s\nlouis_delivery_route=%s\ntyped_collectibles=%d glow=%s tiny_icon=%s\npoop_bags=%d\nalert=%s detection=%.2f modifier=%.2f\nperf wrong_scent=%d wrong_code=%d alarms=%d guards_alerted=%d collectibles=%d" % [
		mid,
		String(get_tree().current_scene.scene_file_path),
		def_mode,
		heat,
		int(GameState.failed_attempts.get(mid, 0)),
		str(muts),
		str(cards),
		str(route),
		int(GameState.typed_collectibles.size()),
		str(glow),
		str(icon),
		GameState.get_poop_bag_count(),
		alert,
		detection_value,
		mod,
		int(perf.get("wrong_scent_trails_followed", 0)),
		int(perf.get("wrong_code_attempts", 0)),
		int(perf.get("alarms_triggered", 0)),
		int(perf.get("guards_alerted", 0)),
		int(perf.get("collectibles_found", 0))
	]


func _on_restart() -> void:
	SceneManager.change_scene("res://scenes/missions_iso/TacoBellIsoBlockout.tscn")


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
