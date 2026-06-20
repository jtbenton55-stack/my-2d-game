@tool
extends VBoxContainer

const MECHANIC_TYPES: Array[String] = [
	"SearchZone",
	"RewardNode",
	"InventoryPickupNode",
	"CompanionCommandPoint",
	"BentleyCrawlspaceConnector",
	"BentleyWaitMarker",
	"NoiseEmitterNode",
	"DistractionObject",
	"LockedInteractionNode",
	"RouteUnlockNode",
	"InteractiveContainer",
	"ExtractionZone",
	"SideObjectiveNode",
	"TriggerZone",
]

const MECHANIC_SCRIPTS: Dictionary = {
	"SearchZone": "res://src/missions/iso/authoring/mechanics/SearchZone.gd",
	"RewardNode": "res://src/missions/iso/authoring/mechanics/RewardNode.gd",
	"InventoryPickupNode": "res://src/missions/iso/authoring/mechanics/InventoryPickupNode.gd",
	"CompanionCommandPoint": "res://src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd",
	"BentleyCrawlspaceConnector": "res://src/missions/iso/authoring/mechanics/BentleyCrawlspaceConnector.gd",
	"BentleyWaitMarker": "res://src/missions/iso/authoring/mechanics/BentleyWaitMarker.gd",
	"NoiseEmitterNode": "res://src/missions/iso/runtime/noise/NoiseEmitterNode.gd",
	"DistractionObject": "res://src/missions/iso/authoring/mechanics/DistractionObject.gd",
	"LockedInteractionNode": "res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd",
	"RouteUnlockNode": "res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd",
	"InteractiveContainer": "res://src/missions/iso/authoring/mechanics/InteractiveContainer.gd",
	"ExtractionZone": "res://src/missions/iso/authoring/mechanics/ExtractionZone.gd",
	"SideObjectiveNode": "res://src/missions/iso/authoring/mechanics/SideObjectiveNode.gd",
	"TriggerZone": "res://src/missions/iso/authoring/mechanics/TriggerZone.gd",
}

const FORBIDDEN_PARENT_FRAGMENTS: Array[String] = [
	"GeneratedRuntimeCollision",
	"GameplayCollisionLayer",
	"GameplayFloorLayer",
	"GameplayMarkersLayer",
	"DebugLabelLayer",
	"Phase0J",
	"Phase0K",
]

const EFFECT_TYPES_REQUIRING_KEY: Array[int] = [
	MissionEffect.EffectType.SET_MISSION_FLAG,
	MissionEffect.EffectType.CLEAR_MISSION_FLAG,
	MissionEffect.EffectType.SET_DIALOGUE_FLAG,
	MissionEffect.EffectType.ACTIVATE_OBJECTIVE,
	MissionEffect.EffectType.COMPLETE_OBJECTIVE,
	MissionEffect.EffectType.FAIL_OBJECTIVE,
	MissionEffect.EffectType.SET_PRIMARY_OBJECTIVE_TEXT,
	MissionEffect.EffectType.GRANT_CARD,
	MissionEffect.EffectType.GRANT_TYPED_COLLECTIBLE,
	MissionEffect.EffectType.GRANT_EVIDENCE_CLUE,
	MissionEffect.EffectType.GRANT_ITEM,
	MissionEffect.EffectType.REMOVE_ITEM,
	MissionEffect.EffectType.TRIGGER_DIALOGUE_KEY,
]

const FACT_TYPES: Array[String] = [
	"always",
	"mission_id",
	"mission_completed",
	"mission_flag",
	"dialogue_flag",
	"objective_active",
	"objective_completed",
	"alert_state",
	"selected_card",
	"unlocked_card",
	"scheme_effect",
	"typed_collectible",
	"evidence_clue",
	"crew_assist",
	"poop_bag_count",
	"inventory_has_item",
	"inventory_item_count",
	"inventory_has_category",
]

var _plugin: EditorPlugin
var _editor_interface: EditorInterface

var _status_label: Label
var _tabs: TabContainer

# Authoring Palette
var _mechanic_type: OptionButton
var _mission_id_override: LineEdit
var _mechanic_id_base: LineEdit
var _display_name: LineEdit
var _objective_id: LineEdit
var _parent_path: LineEdit
var _pos_x: SpinBox
var _pos_y: SpinBox
var _shape_x: SpinBox
var _shape_y: SpinBox
var _interaction_mode: OptionButton
var _prompt_text: LineEdit
var _one_shot: CheckBox
var _req_enabled: CheckBox
var _req_fact_type: OptionButton
var _req_key: LineEdit
var _req_operator: OptionButton
var _req_expected_bool: CheckBox
var _effect_enabled: CheckBox
var _effect_type: OptionButton
var _effect_key: LineEdit
var _effect_value_bool: CheckBox
var _template_details: RichTextLabel
var _placement_summary: Label

# Assist Browser
var _audit_severity: OptionButton
var _audit_type: OptionButton
var _audit_count: Label
var _audit_results: ItemList
var _audit_details: RichTextLabel

var _place_with_mouse_pending := false
var _consume_next_left_release := false
var _audit_issues: Array[Dictionary] = []
var _filtered_audit_issues: Array[Dictionary] = []
var _selected_audit_index := -1


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()


func _ready() -> void:
	_build_ui()
	_on_mechanic_type_changed(0)
	_status_label.text = "Mission Dock ready. Authoring Palette places existing mechanic classes only. Assist Browser is read-only."


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Mission Dock"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(380, 48)
	add_child(_status_label)
	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)
	_build_authoring_palette_tab()
	_build_assist_browser_tab()


func _build_authoring_palette_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Mission Authoring Palette"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(380, 0)
	scroll.add_child(content)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Places existing MechanicAreaBase subclasses with safe defaults. Does not create a parallel mission format, runtime manager, or save files. RequirementSet/EffectSet are in-memory only in v1."
	content.add_child(help)
	content.add_child(_heading("Mechanic Template"))
	var grid := GridContainer.new()
	grid.columns = 2
	content.add_child(grid)
	grid.add_child(_label("Mechanic Type"))
	_mechanic_type = OptionButton.new()
	for mechanic_type in MECHANIC_TYPES:
		_mechanic_type.add_item(mechanic_type)
	_mechanic_type.item_selected.connect(_on_mechanic_type_changed)
	grid.add_child(_mechanic_type)
	grid.add_child(_label("Mission ID Override"))
	_mission_id_override = LineEdit.new()
	_mission_id_override.placeholder_text = "Optional mission id override"
	grid.add_child(_mission_id_override)
	grid.add_child(_label("Mechanic ID Base"))
	_mechanic_id_base = LineEdit.new()
	_mechanic_id_base.text = "dev_mechanic"
	grid.add_child(_mechanic_id_base)
	grid.add_child(_label("Display Name"))
	_display_name = LineEdit.new()
	_display_name.text = "Dev Mechanic"
	grid.add_child(_display_name)
	grid.add_child(_label("Objective ID"))
	_objective_id = LineEdit.new()
	_objective_id.placeholder_text = "Required for SideObjectiveNode"
	grid.add_child(_objective_id)
	content.add_child(_heading("Parent / Transform"))
	var parent_grid := GridContainer.new()
	parent_grid.columns = 2
	content.add_child(parent_grid)
	parent_grid.add_child(_label("Parent Target Path"))
	_parent_path = LineEdit.new()
	_parent_path.placeholder_text = "MissionMechanics or selected Node2D path"
	parent_grid.add_child(_parent_path)
	parent_grid.add_child(_label("Position X"))
	_pos_x = _spin(-100000, 100000, 0, 1)
	parent_grid.add_child(_pos_x)
	parent_grid.add_child(_label("Position Y"))
	_pos_y = _spin(-100000, 100000, 0, 1)
	parent_grid.add_child(_pos_y)
	parent_grid.add_child(_label("Shape Size X"))
	_shape_x = _spin(8, 4096, 96, 1)
	parent_grid.add_child(_shape_x)
	parent_grid.add_child(_label("Shape Size Y"))
	_shape_y = _spin(8, 4096, 96, 1)
	parent_grid.add_child(_shape_y)
	var parent_buttons := GridContainer.new()
	parent_buttons.columns = 1
	content.add_child(parent_buttons)
	_button(parent_buttons, "Use Selected Node As Parent", _use_selected_node_as_parent)
	_button(parent_buttons, "Ensure MissionMechanics Parent", _ensure_mission_mechanics_parent)
	content.add_child(_heading("Interaction"))
	var interact_grid := GridContainer.new()
	interact_grid.columns = 2
	content.add_child(interact_grid)
	interact_grid.add_child(_label("Interaction Mode"))
	_interaction_mode = OptionButton.new()
	_interaction_mode.add_item("AUTOMATIC_ON_ENTER")
	_interaction_mode.add_item("INTERACT_REQUIRED")
	_interaction_mode.add_item("SCRIPT_ONLY")
	_interaction_mode.select(1)
	interact_grid.add_child(_interaction_mode)
	interact_grid.add_child(_label("Prompt Text"))
	_prompt_text = LineEdit.new()
	_prompt_text.text = "Press E: Interact"
	interact_grid.add_child(_prompt_text)
	_one_shot = CheckBox.new()
	_one_shot.text = "One Shot"
	_one_shot.button_pressed = true
	content.add_child(_one_shot)
	content.add_child(_heading("Starter Requirement"))
	_req_enabled = CheckBox.new()
	_req_enabled.text = "Enable Starter Requirement"
	content.add_child(_req_enabled)
	var req_grid := GridContainer.new()
	req_grid.columns = 2
	content.add_child(req_grid)
	req_grid.add_child(_label("fact_type"))
	_req_fact_type = OptionButton.new()
	for fact in FACT_TYPES:
		_req_fact_type.add_item(fact)
	_req_fact_type.select(FACT_TYPES.find("mission_flag"))
	req_grid.add_child(_req_fact_type)
	req_grid.add_child(_label("key"))
	_req_key = LineEdit.new()
	req_grid.add_child(_req_key)
	req_grid.add_child(_label("operator"))
	_req_operator = OptionButton.new()
	_req_operator.add_item("EQUALS")
	_req_operator.add_item("NOT_EQUALS")
	_req_operator.add_item("EXISTS")
	_req_operator.add_item("NOT_EXISTS")
	_req_operator.select(2)
	req_grid.add_child(_req_operator)
	req_grid.add_child(_label("expected bool"))
	_req_expected_bool = CheckBox.new()
	_req_expected_bool.button_pressed = true
	req_grid.add_child(_req_expected_bool)
	content.add_child(_heading("Starter Success Effect"))
	_effect_enabled = CheckBox.new()
	_effect_enabled.text = "Enable Starter Success Effect"
	content.add_child(_effect_enabled)
	var effect_grid := GridContainer.new()
	effect_grid.columns = 2
	content.add_child(effect_grid)
	effect_grid.add_child(_label("effect_type"))
	_effect_type = OptionButton.new()
	for effect_name in MissionEffect.EffectType.keys():
		_effect_type.add_item(effect_name)
	_effect_type.select(MissionEffect.EffectType.SET_MISSION_FLAG)
	effect_grid.add_child(_effect_type)
	effect_grid.add_child(_label("key"))
	_effect_key = LineEdit.new()
	effect_grid.add_child(_effect_key)
	effect_grid.add_child(_label("value bool"))
	_effect_value_bool = CheckBox.new()
	_effect_value_bool.button_pressed = true
	effect_grid.add_child(_effect_value_bool)
	content.add_child(_heading("Template Details"))
	_template_details = RichTextLabel.new()
	_template_details.custom_minimum_size = Vector2(380, 120)
	_template_details.fit_content = false
	_template_details.bbcode_enabled = true
	content.add_child(_template_details)
	content.add_child(_heading("Placement Actions"))
	var actions := GridContainer.new()
	actions.columns = 1
	content.add_child(actions)
	_button(actions, "Dry Run Placement", _dry_run_placement)
	_button(actions, "Place At Typed Position", _place_at_typed_position)
	_button(actions, "Place With Mouse", _begin_place_with_mouse)
	_button(actions, "Disarm", _disarm_mouse_placement)
	content.add_child(_heading("Last Placement Summary"))
	_placement_summary = Label.new()
	_placement_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_placement_summary.custom_minimum_size = Vector2(380, 160)
	_placement_summary.text = "No placement yet."
	content.add_child(_placement_summary)


func _build_assist_browser_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Mission Assist Browser"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(380, 0)
	scroll.add_child(content)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Read-only scene audit. Refresh scans the edited scene for mechanic issues. No auto-fix, no scene mutation, no resource saves."
	content.add_child(help)
	var filters := GridContainer.new()
	filters.columns = 2
	content.add_child(filters)
	filters.add_child(_label("Severity"))
	_audit_severity = OptionButton.new()
	for severity in ["All", "Error", "Warning", "Info"]:
		_audit_severity.add_item(severity)
	_audit_severity.item_selected.connect(func(_i: int) -> void: _apply_audit_filters())
	filters.add_child(_audit_severity)
	filters.add_child(_label("Issue Type"))
	_audit_type = OptionButton.new()
	_audit_type.add_item("All")
	_audit_type.item_selected.connect(func(_i: int) -> void: _apply_audit_filters())
	filters.add_child(_audit_type)
	_audit_count = Label.new()
	content.add_child(_audit_count)
	_audit_results = ItemList.new()
	_audit_results.custom_minimum_size = Vector2(380, 220)
	_audit_results.select_mode = ItemList.SELECT_SINGLE
	_audit_results.item_selected.connect(_on_audit_selected)
	content.add_child(_audit_results)
	_audit_details = RichTextLabel.new()
	_audit_details.custom_minimum_size = Vector2(380, 160)
	_audit_details.fit_content = false
	_audit_details.bbcode_enabled = true
	content.add_child(_audit_details)
	var buttons := GridContainer.new()
	buttons.columns = 1
	content.add_child(buttons)
	_button(buttons, "Refresh Scene Audit", _refresh_scene_audit)
	_button(buttons, "Select Node", _select_audit_node)
	_button(buttons, "Copy Node Path", _copy_audit_node_path)
	_button(buttons, "Copy Issue Summary", _copy_issue_summary)
	_button(buttons, "Copy Full Audit Summary", _copy_full_audit_summary)


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _spin(min_value: float, max_value: float, value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.value = value
	spin.step = step
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_mechanic_type_changed(_idx: int) -> void:
	var mechanic_type := _selected_mechanic_type()
	match mechanic_type:
		"SearchZone":
			_prompt_text.text = "Press E: Search"
		"RewardNode":
			_prompt_text.text = "Press E: Collect"
		"InventoryPickupNode":
			_prompt_text.text = "Press E: Pick up item"
		"CompanionCommandPoint":
			_prompt_text.text = "Press E: Ask Bentley"
		"BentleyCrawlspaceConnector":
			_prompt_text.text = "Press E: Send Bentley through"
		"BentleyWaitMarker":
			_prompt_text.text = "Press E: Ask Bentley to wait"
		"NoiseEmitterNode":
			_prompt_text.text = "Press E: Emit noise"
		"DistractionObject":
			_prompt_text.text = "Press E: Create distraction"
		"LockedInteractionNode":
			_prompt_text.text = "Press E: Unlock"
		"RouteUnlockNode":
			_prompt_text.text = "Press E: Open Route"
		"InteractiveContainer":
			_prompt_text.text = "Press E: Open"
		"ExtractionZone":
			_prompt_text.text = "Press E: Extract"
		"SideObjectiveNode":
			_prompt_text.text = "Press E: Objective"
		"TriggerZone":
			_prompt_text.text = "Press E: Trigger"
	_update_template_details()


func _selected_mechanic_type() -> String:
	return _mechanic_type.get_item_text(_mechanic_type.selected)


func _normalized_mechanic_id_base() -> String:
	var base := _mechanic_id_base.text.strip_edges()
	if base == "":
		base = "dev_mechanic"
	return base


func _update_template_details() -> void:
	var mechanic_type := _selected_mechanic_type()
	var base_id := _normalized_mechanic_id_base()
	var script_path := String(MECHANIC_SCRIPTS.get(mechanic_type, ""))
	_template_details.text = "[b]%s[/b]\nScript: %s\nPlanned mechanic_id: %s\nStarter requirement: %s\nStarter success effect: %s" % [
		mechanic_type,
		script_path,
		base_id,
		"yes" if _req_enabled.button_pressed else "no",
		"yes" if _effect_enabled.button_pressed else "no",
	]


func _edited_scene_root() -> Node:
	return _editor_interface.get_edited_scene_root() if _editor_interface != null else null


func _path_is_unsafe(path_text: String) -> bool:
	for fragment in FORBIDDEN_PARENT_FRAGMENTS:
		if fragment in path_text:
			return true
	return false


func _resolve_parent() -> Dictionary:
	var scene_root := _edited_scene_root()
	if scene_root == null:
		return {"ok": false, "message": "Error: no open edited scene."}
	var path_text := _parent_path.text.strip_edges()
	var parent: Node2D = null
	if path_text != "":
		if _path_is_unsafe(path_text):
			return {"ok": false, "message": "Refused: unsafe parent target path."}
		parent = scene_root.get_node_or_null(path_text) as Node2D
		if parent == null:
			return {"ok": false, "message": "Error: parent target not found: %s" % path_text}
	var needs_mission_mechanics := false
	if parent == null:
		parent = scene_root.get_node_or_null("MissionMechanics") as Node2D
		if parent == null:
			needs_mission_mechanics = true
	if parent != null and _path_is_unsafe(str(parent.get_path())):
		return {"ok": false, "message": "Refused: parent is under protected/generated runtime content."}
	var reported_path := str(parent.get_path()) if parent != null else "MissionMechanics"
	if needs_mission_mechanics:
		reported_path = "MissionMechanics (will be created)"
	return {
		"ok": true,
		"parent": parent,
		"path": reported_path,
		"needs_mission_mechanics": needs_mission_mechanics,
	}


func _use_selected_node_as_parent() -> void:
	if _editor_interface == null:
		return
	var selected := _editor_interface.get_selection().get_selected_nodes()
	if selected.is_empty() or not (selected[0] is Node2D):
		_status_label.text = "Error: select a Node2D to use as parent."
		return
	var node := selected[0] as Node2D
	if _path_is_unsafe(str(node.get_path())):
		_status_label.text = "Refused: selected node is an unsafe parent target."
		return
	_parent_path.text = str(node.get_path())
	_status_label.text = "Parent target set to selected node: %s" % _parent_path.text


func _ensure_mission_mechanics_parent() -> void:
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open edited scene."
		return
	var existing := scene_root.get_node_or_null("MissionMechanics") as Node2D
	if existing != null:
		_parent_path.text = str(existing.get_path())
		_status_label.text = "MissionMechanics already exists: %s" % _parent_path.text
		return
	if _plugin == null:
		_status_label.text = "Error: editor plugin unavailable."
		return
	var parent := Node2D.new()
	parent.name = "MissionMechanics"
	var ur := _plugin.get_undo_redo()
	ur.create_action("Ensure MissionMechanics Parent")
	ur.add_do_method(scene_root, "add_child", parent)
	ur.add_do_method(self, "_set_owner_recursive", parent, scene_root)
	ur.add_undo_method(scene_root, "remove_child", parent)
	ur.commit_action()
	_parent_path.text = str(parent.get_path())
	_status_label.text = "Created MissionMechanics parent: %s" % _parent_path.text


func _preview_placement() -> Dictionary:
	var mechanic_type := _selected_mechanic_type()
	var base_id := _normalized_mechanic_id_base()
	var warnings: Array[String] = []
	var refused := false
	var refuse_reason := ""
	if base_id == "mechanic":
		warnings.append("mechanic_id base is still the generic default 'mechanic'.")
	if mechanic_type == "SideObjectiveNode" and _objective_id.text.strip_edges() == "":
		refused = true
		refuse_reason = "SideObjectiveNode requires an explicit objective_id."
	var parent_result := _resolve_parent()
	if not bool(parent_result.get("ok", false)):
		refused = true
		refuse_reason = String(parent_result.get("message", "Parent unresolved."))
	elif bool(parent_result.get("needs_mission_mechanics", false)):
		warnings.append("MissionMechanics parent will be created as part of placement UndoRedo.")
	return {
		"ok": not refused,
		"refused": refused,
		"message": refuse_reason,
		"mechanic_type": mechanic_type,
		"mechanic_id": base_id,
		"node_name": _planned_node_name(mechanic_type, base_id),
		"parent": parent_result.get("parent"),
		"parent_path": String(parent_result.get("path", "")),
		"needs_mission_mechanics": bool(parent_result.get("needs_mission_mechanics", false)),
		"position": Vector2(_pos_x.value, _pos_y.value),
		"shape_size": Vector2(_shape_x.value, _shape_y.value),
		"starter_requirement": _req_enabled.button_pressed,
		"starter_success_effect": _effect_enabled.button_pressed,
		"warnings": warnings,
	}


func _planned_node_name(mechanic_type: String, base_id: String) -> String:
	return "%s_%s" % [mechanic_type, base_id]


func _dry_run_placement() -> void:
	var preview := _preview_placement()
	if bool(preview.get("refused", false)):
		_status_label.text = "Dry run refused: %s" % String(preview.get("message", "Unknown refusal."))
		return
	var warnings: Array = preview.get("warnings", [])
	var warning_text := ""
	if not warnings.is_empty():
		warning_text = " Warnings: %s" % ", ".join(warnings)
	_status_label.text = "Dry run OK (no scene changes): %s -> %s at %s under parent %s.%s" % [
		String(preview.get("mechanic_type", "")),
		String(preview.get("mechanic_id", "")),
		str(preview.get("position", Vector2.ZERO)),
		String(preview.get("parent_path", "")),
		warning_text,
	]
	_update_placement_summary_from_preview(preview)


func _place_at_typed_position() -> void:
	_commit_placement(Vector2(_pos_x.value, _pos_y.value))


func _begin_place_with_mouse() -> void:
	_consume_next_left_release = false
	if _place_with_mouse_pending:
		_place_with_mouse_pending = false
		_notify_input_forwarding_changed()
	var preview := _preview_placement()
	if bool(preview.get("refused", false)):
		_status_label.text = String(preview.get("message", "Error: mouse placement refused."))
		return
	_place_with_mouse_pending = true
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	_status_label.text = "Mouse placement armed (%s): left-click viewport to place under %s; right-click/Esc to cancel." % [
		String(preview.get("mechanic_type", "")),
		String(preview.get("parent_path", "")),
	]


func _disarm_mouse_placement() -> void:
	_clear_mouse_placement_pending("Mouse placement disarmed.")


func _clear_mouse_placement_pending(status_text: String = "") -> void:
	if not _place_with_mouse_pending:
		if status_text != "":
			_status_label.text = status_text
		return
	_place_with_mouse_pending = false
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	if status_text != "":
		_status_label.text = status_text


func should_forward_canvas_gui_input() -> bool:
	return _place_with_mouse_pending or _consume_next_left_release


func handle_canvas_gui_input(event: InputEvent) -> bool:
	if _consume_next_left_release and event is InputEventMouseButton:
		var release_event := event as InputEventMouseButton
		if release_event.button_index == MOUSE_BUTTON_LEFT and not release_event.pressed:
			_consume_next_left_release = false
			return true
	if _place_with_mouse_pending:
		return _handle_place_with_mouse_canvas_input(event)
	return false


func _handle_place_with_mouse_canvas_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			_clear_mouse_placement_pending("Mouse placement cancelled.")
			return true
		return false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_clear_mouse_placement_pending("Mouse placement cancelled.")
			return true
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_consume_next_left_release = true
			_clear_mouse_placement_pending()
			_commit_placement(_canvas_position_from_mouse_event(mouse_event), true)
			call_deferred("_notify_input_forwarding_changed")
			return true
		return false
	if event is InputEventMouseMotion:
		return true
	return false


func _canvas_position_from_mouse_event(event: InputEventMouse) -> Vector2:
	var viewport := _editor_viewport_2d()
	if viewport == null:
		return event.position
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()


func _editor_viewport_2d() -> SubViewport:
	if _editor_interface == null:
		return null
	var viewport := _editor_interface.get_editor_viewport_2d()
	return viewport if viewport is SubViewport else null


func _commit_placement(local_or_canvas_pos: Vector2, from_mouse := false) -> void:
	var preview := _preview_placement()
	if bool(preview.get("refused", false)):
		_status_label.text = String(preview.get("message", "Error: placement refused."))
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open edited scene."
		return
	var created_parent := bool(preview.get("needs_mission_mechanics", false))
	var parent: Node2D = null
	var mission_mechanics_parent: Node2D = null
	if created_parent:
		mission_mechanics_parent = Node2D.new()
		mission_mechanics_parent.name = "MissionMechanics"
		parent = mission_mechanics_parent
	else:
		parent = preview.get("parent") as Node2D
	if parent == null:
		_status_label.text = "Error: placement parent unresolved."
		return
	var mechanic_type := String(preview.get("mechanic_type", ""))
	var base_id := String(preview.get("mechanic_id", ""))
	var node := _build_mechanic_node(mechanic_type, base_id)
	node.name = _unique_child_name(parent, String(preview.get("node_name", "Mechanic")))
	var node_position := local_or_canvas_pos
	if from_mouse:
		if created_parent:
			node_position = scene_root.to_local(local_or_canvas_pos)
		else:
			node_position = parent.to_local(local_or_canvas_pos)
	node.position = node_position
	_pos_x.value = node_position.x
	_pos_y.value = node_position.y
	if _plugin == null:
		_status_label.text = "Error: editor plugin unavailable."
		node.free()
		if created_parent:
			mission_mechanics_parent.free()
		return
	var ur := _plugin.get_undo_redo()
	ur.create_action("Place Mission Mechanic")
	if created_parent:
		ur.add_do_method(scene_root, "add_child", mission_mechanics_parent)
		ur.add_do_method(self, "_set_owner_recursive", mission_mechanics_parent, scene_root)
	ur.add_do_method(parent, "add_child", node)
	ur.add_do_method(self, "_set_owner_recursive", node, scene_root)
	ur.add_do_method(self, "_select_placed_node", node)
	if created_parent:
		ur.add_undo_method(self, "_undo_remove_placed_mechanic_with_parent", scene_root, mission_mechanics_parent, node)
	else:
		ur.add_undo_method(self, "_undo_remove_placed_mechanic", parent, node, parent)
	ur.commit_action()
	_status_label.text = "Placed %s '%s' at %s under %s" % [mechanic_type, base_id, str(node_position), str(parent.get_path())]
	_update_placement_summary_from_node(mechanic_type, base_id, node.name, str(parent.get_path()), node_position, node)
	_update_template_details()


func _build_mechanic_node(mechanic_type: String, base_id: String) -> Area2D:
	var script_path := String(MECHANIC_SCRIPTS.get(mechanic_type, ""))
	var script := load(script_path) as Script
	var node := Area2D.new()
	node.set_script(script)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_shape_x.value, _shape_y.value)
	shape_node.shape = rect
	node.add_child(shape_node)
	node.set("shape_size", Vector2(_shape_x.value, _shape_y.value))
	node.set("mechanic_id", StringName(base_id))
	node.set("display_name", _display_name.text.strip_edges())
	node.set("mission_id_override", _mission_id_override.text.strip_edges())
	node.set("interaction_mode", _interaction_mode.selected)
	node.set("prompt_text", _prompt_text.text)
	node.set("one_shot", _one_shot.button_pressed)
	_apply_type_defaults(node, mechanic_type, base_id)
	if _req_enabled.button_pressed:
		node.set("requirements", _build_starter_requirement(base_id))
	if _effect_enabled.button_pressed:
		node.set("success_effects", _build_starter_success_effect(base_id))
	return node


func _apply_type_defaults(node: Area2D, mechanic_type: String, base_id: String) -> void:
	match mechanic_type:
		"SearchZone":
			node.set("searched_flag", StringName("%s_searched" % base_id))
		"RewardNode":
			node.set("reward_id", StringName(base_id))
			node.set("collected_flag", StringName("%s_collected" % base_id))
		"InventoryPickupNode":
			node.set("item_id", StringName(base_id))
			node.set("reward_id", StringName(base_id))
			node.set("collected_flag", StringName("%s_collected" % base_id))
		"CompanionCommandPoint":
			node.set("command_type", "bark")
			node.set("command_label", "Bentley command: %s" % base_id)
		"BentleyCrawlspaceConnector":
			node.set("command_type", "crawlspace")
			node.set("command_label", "Bentley crawlspace: %s" % base_id)
		"BentleyWaitMarker":
			node.set("command_type", "wait")
			node.set("command_label", "Bentley wait: %s" % base_id)
		"NoiseEmitterNode":
			node.set("noise_id", StringName(base_id))
			node.set("noise_kind", "generic")
			node.set("noise_team", "player")
		"DistractionObject":
			node.set("noise_id", StringName(base_id))
			node.set("noise_kind", "decoy")
			node.set("noise_team", "player")
		"LockedInteractionNode":
			node.set("unlocked_flag", StringName("%s_unlocked" % base_id))
			node.set("locked_prompt_text", "Locked")
		"RouteUnlockNode":
			node.set("route_id", StringName(base_id))
			node.set("route_flag", StringName("%s_open" % base_id))
		"InteractiveContainer":
			node.set("opened_flag", StringName("%s_opened" % base_id))
			node.set("searched_flag", StringName("%s_searched" % base_id))
			node.set("open_prompt_text", "Open")
		"ExtractionZone":
			node.set("extraction_tag", StringName(base_id))
			node.set("extraction_flag", StringName("%s_extracted" % base_id))
			node.set("complete_mission_on_success", false)
		"SideObjectiveNode":
			node.set("objective_id", StringName(_objective_id.text.strip_edges()))
			node.set("objective_flag", StringName("%s_handled" % base_id))
		"TriggerZone":
			node.set("trigger_on_enter", false)
			node.set("trigger_on_exit", false)
			node.set("interaction_mode", MechanicAreaBase.InteractionMode.INTERACT_REQUIRED)


func _build_starter_requirement(base_id: String) -> RequirementSet:
	var requirement := MissionRequirement.new()
	requirement.resource_name = "req_%s" % base_id
	requirement.requirement_id = StringName("req_%s" % base_id)
	requirement.fact_type = StringName(_req_fact_type.get_item_text(_req_fact_type.selected))
	requirement.key = _req_key.text.strip_edges()
	var operator_value: MissionRequirement.Operator = _req_operator.selected as MissionRequirement.Operator
	requirement.operator = operator_value
	if operator_value == MissionRequirement.Operator.EXISTS or operator_value == MissionRequirement.Operator.NOT_EXISTS:
		requirement.expected_value_type = "exists"
	else:
		requirement.expected_value_type = "bool"
	requirement.expected_bool = _req_expected_bool.button_pressed
	requirement.fail_message = "Requirement not met for %s." % base_id
	var set := RequirementSet.new()
	set.resource_name = "reqset_%s" % base_id
	set.set_id = StringName("reqset_%s" % base_id)
	var requirements: Array[MissionRequirement] = []
	requirements.append(requirement)
	set.requirements = requirements
	set.locked_message = requirement.fail_message
	return set


func _build_starter_success_effect(base_id: String) -> EffectSet:
	var effect := MissionEffect.new()
	effect.resource_name = "effect_%s" % base_id
	effect.effect_id = StringName("effect_%s" % base_id)
	effect.effect_type = _effect_type.selected as MissionEffect.EffectType
	var key := _effect_key.text.strip_edges()
	if key == "":
		key = "%s_done" % base_id
	effect.key = key
	effect.value_type = "bool"
	effect.value_bool = _effect_value_bool.button_pressed
	var set := EffectSet.new()
	set.resource_name = "effectset_%s" % base_id
	set.set_id = StringName("effectset_%s" % base_id)
	var effects: Array[MissionEffect] = []
	effects.append(effect)
	set.effects = effects
	return set


func _operator_label(operator_value: MissionRequirement.Operator) -> String:
	match operator_value:
		MissionRequirement.Operator.NOT_EQUALS:
			return "NOT_EQUALS"
		MissionRequirement.Operator.EXISTS:
			return "EXISTS"
		MissionRequirement.Operator.NOT_EXISTS:
			return "NOT_EXISTS"
		MissionRequirement.Operator.GREATER_THAN:
			return "GREATER_THAN"
		MissionRequirement.Operator.GREATER_OR_EQUAL:
			return "GREATER_OR_EQUAL"
		MissionRequirement.Operator.LESS_THAN:
			return "LESS_THAN"
		MissionRequirement.Operator.LESS_OR_EQUAL:
			return "LESS_OR_EQUAL"
		_:
			return "EQUALS"


func _effect_type_label(effect_type: MissionEffect.EffectType) -> String:
	var keys := MissionEffect.EffectType.keys()
	if effect_type >= 0 and effect_type < keys.size():
		return keys[effect_type]
	return str(effect_type)


func _summarize_requirement_set(resource: Resource) -> String:
	if resource == null or not (resource is RequirementSet):
		return "RequirementSet: none"
	var set := resource as RequirementSet
	var lines: PackedStringArray = []
	lines.append("RequirementSet %s (count=%d)" % [String(set.set_id), set.requirements.size()])
	for requirement in set.requirements:
		if requirement == null:
			continue
		lines.append(
			"  - %s fact_type=%s key=%s operator=%s expected_value_type=%s expected_bool=%s" % [
				String(requirement.requirement_id),
				String(requirement.fact_type),
				requirement.key,
				_operator_label(requirement.operator),
				requirement.expected_value_type,
				str(requirement.expected_bool),
			]
		)
	return "\n".join(lines)


func _summarize_effect_set(resource: Resource, label: String) -> String:
	if resource == null or not (resource is EffectSet):
		return "%s: none" % label
	var set := resource as EffectSet
	var lines: PackedStringArray = []
	lines.append("%s %s (count=%d)" % [label, String(set.set_id), set.effects.size()])
	for effect in set.effects:
		if effect == null:
			continue
		lines.append(
			"  - %s effect_type=%s key=%s value_type=%s value_bool=%s" % [
				String(effect.effect_id),
				_effect_type_label(effect.effect_type),
				effect.key,
				effect.value_type,
				str(effect.value_bool),
			]
		)
	return "\n".join(lines)


func _update_placement_summary_from_preview(preview: Dictionary) -> void:
	if _placement_summary == null:
		return
	var lines: PackedStringArray = [
		"[Dry run preview]",
		"Mechanic type: %s" % String(preview.get("mechanic_type", "")),
		"Mechanic ID: %s" % String(preview.get("mechanic_id", "")),
		"Parent: %s" % String(preview.get("parent_path", "")),
		"Position: %s" % str(preview.get("position", Vector2.ZERO)),
		"Starter requirement enabled: %s" % str(preview.get("starter_requirement", false)),
		"Starter success effect enabled: %s" % str(preview.get("starter_success_effect", false)),
	]
	if bool(preview.get("starter_requirement", false)):
		lines.append(_summarize_requirement_set(_build_starter_requirement(String(preview.get("mechanic_id", "")))))
	if bool(preview.get("starter_success_effect", false)):
		lines.append(_summarize_effect_set(_build_starter_success_effect(String(preview.get("mechanic_id", ""))), "Success EffectSet"))
	_placement_summary.text = "\n".join(lines)


func _update_placement_summary_from_node(
	mechanic_type: String,
	base_id: String,
	node_name: String,
	parent_path: String,
	node_position: Vector2,
	node: Node,
) -> void:
	if _placement_summary == null:
		return
	var lines: PackedStringArray = [
		"Mechanic type: %s" % mechanic_type,
		"Mechanic ID: %s" % base_id,
		"Node name: %s" % node_name,
		"Parent: %s" % parent_path,
		"Position: %s" % str(node_position),
		"Starter requirement assigned: %s" % str(_req_enabled.button_pressed),
	]
	if _req_enabled.button_pressed:
		lines.append(_summarize_requirement_set(node.get("requirements")))
	else:
		lines.append("RequirementSet: none")
	lines.append("Starter success effect assigned: %s" % str(_effect_enabled.button_pressed))
	if _effect_enabled.button_pressed:
		lines.append(_summarize_effect_set(node.get("success_effects"), "Success EffectSet"))
	else:
		lines.append("Success EffectSet: none")
	_placement_summary.text = "\n".join(lines)


func _summarize_mechanic_node_resources(node: Node) -> String:
	if node == null:
		return ""
	var lines: PackedStringArray = []
	if "requirements" in node:
		lines.append(_summarize_requirement_set(node.get("requirements")))
	if "success_effects" in node:
		lines.append(_summarize_effect_set(node.get("success_effects"), "Success EffectSet"))
	if "failure_effects" in node:
		lines.append(_summarize_effect_set(node.get("failure_effects"), "Failure EffectSet"))
	return "\n".join(lines)


func _unique_child_name(parent: Node, desired: String) -> String:
	if parent.get_node_or_null(desired) == null:
		return desired
	var index := 2
	while parent.get_node_or_null("%s_%d" % [desired, index]) != null:
		index += 1
	return "%s_%d" % [desired, index]


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)


func _select_placed_node(node: Node) -> void:
	if _editor_interface == null:
		return
	var selection := _editor_interface.get_selection()
	selection.clear()
	selection.add_node(node)


func _undo_remove_placed_mechanic(parent: Node, node: Node, safe_selection: Node = null) -> void:
	_consume_next_left_release = false
	_place_with_mouse_pending = false
	if _editor_interface != null:
		var selection := _editor_interface.get_selection()
		if selection != null:
			selection.clear()
	if parent != null and node != null and is_instance_valid(node) and node.get_parent() == parent:
		parent.remove_child(node)
	if _editor_interface != null and safe_selection != null and is_instance_valid(safe_selection) and safe_selection is CanvasItem:
		var safe_sel := _editor_interface.get_selection()
		if safe_sel != null:
			safe_sel.add_node(safe_selection)
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")


func _undo_remove_placed_mechanic_with_parent(scene_root: Node, mission_mechanics_parent: Node, node: Node) -> void:
	_consume_next_left_release = false
	_place_with_mouse_pending = false
	if _editor_interface != null:
		var selection := _editor_interface.get_selection()
		if selection != null:
			selection.clear()
	if mission_mechanics_parent != null and is_instance_valid(mission_mechanics_parent):
		if node != null and is_instance_valid(node) and node.get_parent() == mission_mechanics_parent:
			mission_mechanics_parent.remove_child(node)
		if scene_root != null and mission_mechanics_parent.get_parent() == scene_root:
			scene_root.remove_child(mission_mechanics_parent)
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")


func _notify_input_forwarding_changed() -> void:
	if _plugin != null and _plugin.has_method("notify_input_forwarding_changed"):
		_plugin.call("notify_input_forwarding_changed")


# --- Assist Browser (read-only) ---

func _refresh_scene_audit() -> void:
	var scene_root := _edited_scene_root()
	_audit_issues.clear()
	if scene_root == null:
		_status_label.text = "Audit: no open edited scene."
		_apply_audit_filters()
		return
	var mechanics: Array[Node] = []
	_collect_mechanic_nodes(scene_root, mechanics)
	_audit_duplicate_ids(mechanics)
	_audit_duplicate_flags(mechanics)
	for mechanic in mechanics:
		_audit_mechanic_node(mechanic, scene_root)
	_status_label.text = "Audit refreshed: %d issue(s) across %d mechanic node(s)." % [_audit_issues.size(), mechanics.size()]
	_apply_audit_filters()


func _collect_mechanic_nodes(node: Node, out: Array[Node]) -> void:
	if _node_is_supported_mechanic(node):
		out.append(node)
	for child in node.get_children():
		_collect_mechanic_nodes(child, out)


func _node_is_supported_mechanic(node: Node) -> bool:
	if node.get_script() == null:
		return false
	var path: String = String(node.get_script().resource_path)
	return path in MECHANIC_SCRIPTS.values()


func _audit_duplicate_ids(mechanics: Array[Node]) -> void:
	var buckets: Dictionary = {}
	for mechanic in mechanics:
		var id_text := String(mechanic.get("mechanic_id"))
		if id_text == "":
			continue
		if not buckets.has(id_text):
			buckets[id_text] = []
		(buckets[id_text] as Array).append(mechanic)
	for id_text in buckets.keys():
		var nodes: Array = buckets[id_text]
		if nodes.size() < 2:
			continue
		for mechanic in nodes:
			_audit_issues.append(_issue("Error", "duplicate_mechanic_id", "Duplicate mechanic_id '%s'." % id_text, mechanic))


func _audit_duplicate_flags(mechanics: Array[Node]) -> void:
	var flag_properties := [
		"searched_flag", "collected_flag", "route_flag", "unlocked_flag",
		"opened_flag", "extraction_flag", "objective_flag",
	]
	for property in flag_properties:
		var buckets: Dictionary = {}
		for mechanic in mechanics:
			if not property in mechanic:
				continue
			var flag_text := String(mechanic.get(property)).strip_edges()
			if flag_text == "":
				continue
			if not buckets.has(flag_text):
				buckets[flag_text] = []
			(buckets[flag_text] as Array).append(mechanic)
		for flag_text in buckets.keys():
			var nodes: Array = buckets[flag_text]
			if nodes.size() < 2:
				continue
			for mechanic in nodes:
				_audit_issues.append(_issue("Error", "duplicate_%s" % property, "Duplicate %s '%s'." % [property, flag_text], mechanic))


func _audit_mechanic_node(node: Node, scene_root: Node) -> void:
	var mechanic_id := String(node.get("mechanic_id"))
	if mechanic_id.strip_edges() == "":
		_audit_issues.append(_issue("Error", "empty_mechanic_id", "mechanic_id is empty.", node))
	elif mechanic_id == "mechanic":
		_audit_issues.append(_issue("Warning", "default_mechanic_id", "mechanic_id is still the generic default 'mechanic'.", node))
	if String(node.get("mission_id_override")).strip_edges() == "":
		_audit_issues.append(_issue("Info", "empty_mission_id_override", "mission_id_override is empty; runtime will resolve mission id from scene context.", node))
	var parent_path := str(node.get_path()).trim_prefix(str(scene_root.get_path()))
	if not parent_path.contains("MissionMechanics"):
		_audit_issues.append(_issue("Warning", "unexpected_parent_container", "Mechanic is not under MissionMechanics.", node))
	_audit_collision_shape(node)
	if node is RewardNode and String(node.get("reward_id")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_reward_id", "RewardNode missing reward_id.", node))
	if node is InventoryPickupNode and String(node.get("item_id")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_item_id", "InventoryPickupNode missing item_id.", node))
	if node is CompanionCommandPoint and String(node.get("command_type")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_companion_command", "CompanionCommandPoint missing command_type.", node))
	if node is NoiseEmitterNode and String(node.get("noise_id")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_noise_id", "NoiseEmitterNode missing noise_id.", node))
	if node is RouteUnlockNode and String(node.get("route_id")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_route_id", "RouteUnlockNode missing route_id.", node))
	if node is ExtractionZone and String(node.get("extraction_tag")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_extraction_tag", "ExtractionZone missing extraction_tag.", node))
	if node is SideObjectiveNode and String(node.get("objective_id")).strip_edges() == "":
		_audit_issues.append(_issue("Error", "missing_objective_id", "SideObjectiveNode missing objective_id.", node))
	if node is ExtractionZone and bool(node.get("complete_mission_on_success")):
		_audit_issues.append(_issue("Warning", "complete_mission_on_success", "ExtractionZone.complete_mission_on_success is true.", node))
	_audit_node_path(scene_root, node, "target_visual_path")
	if node is LockedInteractionNode:
		_audit_node_path(scene_root, node, "target_collision_path")
	if node is SearchZone:
		_audit_node_path_array(scene_root, node, "nodes_to_show_on_search")
		_audit_node_path_array(scene_root, node, "nodes_to_hide_on_search")
	if node is RewardNode:
		_audit_node_path_array(scene_root, node, "nodes_to_show_on_collect")
		_audit_node_path_array(scene_root, node, "nodes_to_hide_on_collect")
	if node is LockedInteractionNode:
		_audit_node_path_array(scene_root, node, "nodes_to_show_on_unlock")
		_audit_node_path_array(scene_root, node, "nodes_to_hide_on_unlock")
		_audit_node_path_array(scene_root, node, "collisions_to_enable_on_unlock")
		_audit_node_path_array(scene_root, node, "collisions_to_disable_on_unlock")
	if node is RouteUnlockNode:
		_audit_node_path_array(scene_root, node, "nodes_to_show")
		_audit_node_path_array(scene_root, node, "nodes_to_hide")
		_audit_node_path_array(scene_root, node, "collisions_to_enable")
		_audit_node_path_array(scene_root, node, "collisions_to_disable")
	_audit_requirement_set(node.get("requirements"))
	_audit_effect_set(node.get("success_effects"), "success_effects")
	_audit_effect_set(node.get("failure_effects"), "failure_effects")


func _audit_collision_shape(node: Node) -> void:
	var shape_path: NodePath = node.get("collision_shape_path")
	var shape_node := node.get_node_or_null(shape_path)
	if shape_node == null or not (shape_node is CollisionShape2D):
		_audit_issues.append(_issue("Error", "missing_collision_shape", "Missing CollisionShape2D at collision_shape_path.", node))
		return
	if (shape_node as CollisionShape2D).shape == null:
		_audit_issues.append(_issue("Error", "invalid_collision_shape", "CollisionShape2D has no shape assigned.", node))


func _audit_node_path(scene_root: Node, node: Node, property: String) -> void:
	if not property in node:
		return
	var node_path: NodePath = node.get(property)
	if node_path == NodePath():
		return
	if _resolve_audit_target(scene_root, node, node_path) == null:
		_audit_issues.append(_issue("Error", "broken_%s" % property, "Broken %s: %s" % [property, str(node_path)], node))


func _audit_node_path_array(scene_root: Node, node: Node, property: String) -> void:
	if not property in node:
		return
	var paths: Array = node.get(property)
	for entry in paths:
		var node_path := NodePath(entry)
		if node_path == NodePath():
			continue
		if _resolve_audit_target(scene_root, node, node_path) == null:
			_audit_issues.append(_issue("Error", "broken_%s" % property, "Broken %s entry: %s" % [property, str(node_path)], node))


func _resolve_audit_target(scene_root: Node, node: Node, node_path: NodePath) -> Node:
	var local := node.get_node_or_null(node_path)
	if local != null:
		return local
	if scene_root != null:
		return scene_root.get_node_or_null(node_path)
	return null


func _audit_requirement_set(resource: Resource) -> void:
	if resource == null or not (resource is RequirementSet):
		return
	for requirement in (resource as RequirementSet).requirements:
		if requirement == null:
			continue
		if not MissionFactBridge.is_known_fact_type(requirement.fact_type):
			_audit_issues.append(_issue("Error", "unknown_requirement_fact_type", "Unknown requirement fact_type: %s" % String(requirement.fact_type), null))
		if String(requirement.fact_type) not in ["always", "mission_id", "mission_completed"] and requirement.key.strip_edges() == "":
			_audit_issues.append(_issue("Error", "empty_requirement_key", "Requirement missing key for fact_type %s." % String(requirement.fact_type), null))


func _audit_effect_set(resource: Resource, label: String) -> void:
	if resource == null or not (resource is EffectSet):
		return
	for effect in (resource as EffectSet).effects:
		if effect == null:
			continue
		if effect.effect_type in EFFECT_TYPES_REQUIRING_KEY and effect.key.strip_edges() == "":
			_audit_issues.append(_issue("Error", "empty_effect_key", "%s effect missing key for effect_type %s." % [label, MissionEffect.EffectType.keys()[effect.effect_type]], null))
		if effect.effect_type == MissionEffect.EffectType.TOGGLE_NODE and effect.target_path == NodePath():
			_audit_issues.append(_issue("Error", "toggle_node_missing_target", "%s TOGGLE_NODE effect missing target_path." % label, null))
		if effect.effect_type == MissionEffect.EffectType.CALL_METHOD:
			if effect.target_path == NodePath():
				_audit_issues.append(_issue("Error", "call_method_missing_target", "%s CALL_METHOD effect missing target_path." % label, null))
			if String(effect.method_name).strip_edges() == "":
				_audit_issues.append(_issue("Error", "call_method_missing_method", "%s CALL_METHOD effect missing method_name." % label, null))


func _issue(severity: String, code: String, message: String, node: Node, details: Dictionary = {}) -> Dictionary:
	return {
		"severity": severity,
		"code": code,
		"message": message,
		"node_path": str(node.get_path()) if node != null else "",
		"node_name": node.name if node != null else "",
		"mechanic_id": String(node.get("mechanic_id")) if node != null and "mechanic_id" in node else "",
		"details": details,
	}


func _apply_audit_filters() -> void:
	var severity := _audit_severity.get_item_text(_audit_severity.selected)
	var issue_type := _audit_type.get_item_text(_audit_type.selected)
	_filtered_audit_issues.clear()
	var type_options := {"All": true}
	for issue in _audit_issues:
		if severity != "All" and issue.get("severity", "") != severity:
			continue
		if issue_type != "All" and issue.get("code", "") != issue_type:
			continue
		_filtered_audit_issues.append(issue)
		type_options[issue.get("code", "unknown")] = true
	_rebuild_audit_type_filter(type_options.keys())
	_audit_results.clear()
	for issue in _filtered_audit_issues:
		_audit_results.add_item("[%s] %s" % [issue.get("severity", "?"), issue.get("message", "")])
	_audit_count.text = "%d issue(s) shown (of %d total)." % [_filtered_audit_issues.size(), _audit_issues.size()]
	if _filtered_audit_issues.is_empty():
		_audit_details.text = "No audit issues for current filters."
	else:
		_on_audit_selected(0)


func _rebuild_audit_type_filter(type_codes: Array) -> void:
	var selected := _audit_type.get_item_text(_audit_type.selected)
	_audit_type.clear()
	_audit_type.add_item("All")
	for code in type_codes:
		if code == "All":
			continue
		_audit_type.add_item(String(code))
	for i in range(_audit_type.item_count):
		if _audit_type.get_item_text(i) == selected:
			_audit_type.select(i)
			return
	_audit_type.select(0)


func _on_audit_selected(index: int) -> void:
	if index < 0 or index >= _filtered_audit_issues.size():
		return
	_selected_audit_index = index
	var issue: Dictionary = _filtered_audit_issues[index]
	var details_lines: PackedStringArray = [
		"[b]%s[/b] (%s)" % [issue.get("severity", ""), issue.get("code", "")],
		String(issue.get("message", "")),
		"Node: %s" % issue.get("node_path", ""),
		"Mechanic ID: %s" % issue.get("mechanic_id", ""),
	]
	var path_text := String(issue.get("node_path", ""))
	if path_text != "":
		var scene_root := _edited_scene_root()
		if scene_root != null:
			var node := scene_root.get_node_or_null(path_text)
			if node != null and _node_is_supported_mechanic(node):
				var resource_summary := _summarize_mechanic_node_resources(node)
				if resource_summary.strip_edges() != "":
					details_lines.append("")
					details_lines.append("[b]Mechanic resources[/b]")
					details_lines.append(resource_summary)
	_audit_details.text = "\n".join(details_lines)


func _select_audit_node() -> void:
	if _selected_audit_index < 0 or _editor_interface == null:
		return
	var issue: Dictionary = _filtered_audit_issues[_selected_audit_index]
	var path_text := String(issue.get("node_path", ""))
	if path_text == "":
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		return
	var node := scene_root.get_node_or_null(path_text)
	if node == null:
		_status_label.text = "Audit node not found: %s" % path_text
		return
	_editor_interface.get_selection().clear()
	_editor_interface.get_selection().add_node(node)
	_editor_interface.edit_node(node)
	_status_label.text = "Selected audit node: %s" % path_text


func _copy_audit_node_path() -> void:
	if _selected_audit_index < 0:
		return
	DisplayServer.clipboard_set(String(_filtered_audit_issues[_selected_audit_index].get("node_path", "")))
	_status_label.text = "Copied node path to clipboard."


func _copy_issue_summary() -> void:
	if _selected_audit_index < 0:
		return
	var issue: Dictionary = _filtered_audit_issues[_selected_audit_index]
	DisplayServer.clipboard_set("[%s] %s (%s)" % [issue.get("severity", ""), issue.get("message", ""), issue.get("node_path", "")])
	_status_label.text = "Copied issue summary to clipboard."


func _copy_full_audit_summary() -> void:
	var lines: PackedStringArray = []
	for issue in _filtered_audit_issues:
		lines.append("[%s] %s | %s | %s" % [issue.get("severity", ""), issue.get("code", ""), issue.get("message", ""), issue.get("node_path", "")])
	DisplayServer.clipboard_set("\n".join(lines))
	_status_label.text = "Copied full audit summary to clipboard."
