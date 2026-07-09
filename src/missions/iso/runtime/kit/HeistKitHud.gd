class_name HeistKitHud
extends CanvasLayer

## Replan Packet 2: the 8-slot heist kit bar. Left 4 slots show loadout items
## (mission_only = false), right 4 show mission pickups (mission_only = true).
## Refreshes from MissionInventory on EventBus.game_state_changed and shows
## incriminating weight + bulky state so pocket risk is always readable.

const SLOT_COUNT_PER_SIDE := 4

var _root: PanelContainer = null
var _slot_labels: Array[Label] = []
var _status_label: Label = null


func _ready() -> void:
	layer = 20
	_build_ui()
	if not EventBus.game_state_changed.is_connected(_refresh):
		EventBus.game_state_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if EventBus.game_state_changed.is_connected(_refresh):
		EventBus.game_state_changed.disconnect(_refresh)


func get_kit_summary() -> Dictionary:
	var snapshot := MissionInventory.get_snapshot()
	var loadout: Array[Dictionary] = []
	var mission: Array[Dictionary] = []
	var items: Dictionary = snapshot.get("items", {})
	for key in items.keys():
		var summary: Dictionary = items[key]
		if bool(summary.get("mission_only", true)):
			mission.append(summary)
		else:
			loadout.append(summary)
	return {
		"loadout": loadout,
		"mission": mission,
		"incriminating_total": MissionInventory.get_incriminating_total(),
		"has_bulky": MissionInventory.has_bulky_item(),
	}


func _build_ui() -> void:
	_root = PanelContainer.new()
	_root.name = "HeistKitRoot"
	_root.anchor_left = 0.5
	_root.anchor_right = 0.5
	_root.anchor_top = 1.0
	_root.anchor_bottom = 1.0
	_root.offset_left = -260.0
	_root.offset_right = 260.0
	_root.offset_top = -76.0
	_root.offset_bottom = -12.0
	_root.self_modulate = Color(1.0, 1.0, 1.0, 0.9)
	add_child(_root)
	var column := VBoxContainer.new()
	_root.add_child(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	for i in range(SLOT_COUNT_PER_SIDE * 2):
		if i == SLOT_COUNT_PER_SIDE:
			var divider := Label.new()
			divider.text = "|"
			row.add_child(divider)
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(56.0, 40.0)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.text = "-"
		slot.add_child(label)
		row.add_child(slot)
		_slot_labels.append(label)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	column.add_child(_status_label)


func _refresh() -> void:
	if _slot_labels.is_empty():
		return
	var kit := get_kit_summary()
	var loadout: Array = kit.get("loadout", [])
	var mission: Array = kit.get("mission", [])
	for i in range(SLOT_COUNT_PER_SIDE):
		_set_slot(i, loadout[i] if i < loadout.size() else {})
	for i in range(SLOT_COUNT_PER_SIDE):
		_set_slot(SLOT_COUNT_PER_SIDE + i, mission[i] if i < mission.size() else {})
	var incriminating := int(kit.get("incriminating_total", 0))
	var bulky := bool(kit.get("has_bulky", false))
	var status := "Kit clean"
	if incriminating > 0:
		status = "Incriminating weight: %d" % incriminating
	if bulky:
		status += "  [BULKY: loud + slow]"
	_status_label.text = status
	_status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.5, 0.4) if incriminating > 0 or bulky else Color(0.6, 0.9, 0.6)
	)


func _set_slot(index: int, summary: Dictionary) -> void:
	if index < 0 or index >= _slot_labels.size():
		return
	var label := _slot_labels[index]
	if summary.is_empty():
		label.text = "-"
		label.remove_theme_color_override("font_color")
		return
	var text := String(summary.get("item_id", "?"))
	var count := int(summary.get("count", 0))
	if count > 1:
		text += " x%d" % count
	label.text = text
	if int(summary.get("incriminating", 0)) > 0:
		label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	elif bool(summary.get("bulky", false)):
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	else:
		label.remove_theme_color_override("font_color")
