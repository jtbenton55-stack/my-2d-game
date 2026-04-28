extends Control

const ITEM_SLOT := preload("res://src/ui/loadout/item_slot.tscn")

var available_items: Array[EquipmentItem] = []
var equipped: Array[EquipmentItem] = []
var max_equipped := 3

@onready var item_grid: GridContainer = $Panel/VBoxContainer/HBoxContainer/ItemGrid
@onready var selected_items: VBoxContainer = $Panel/VBoxContainer/HBoxContainer/SelectedItems
@onready var start_mission_button: Button = $Panel/VBoxContainer/StartMissionButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready() -> void:
	start_mission_button.pressed.connect(_on_start_mission)
	close_button.pressed.connect(queue_free)
	_load_items()
	start_mission_button.grab_focus()

func _load_items() -> void:
	available_items.clear()
	var dir := DirAccess.open("res://resources/equipment/")
	if dir != null:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(".tres") or file.ends_with(".res"):
				var item := load("res://resources/equipment/" + file) as EquipmentItem
				if item != null:
					available_items.append(item)
			file = dir.get_next()
	if available_items.is_empty():
		available_items = _default_items()
	for item in available_items:
		var slot := ITEM_SLOT.instantiate()
		if slot.has_method("setup"):
			slot.setup(item)
		if slot.has_signal("equip_toggled"):
			slot.connect("equip_toggled", _on_toggle_equip)
		item_grid.add_child(slot)

func _default_items() -> Array[EquipmentItem]:
	var defaults: Array[EquipmentItem] = []
	defaults.append(_make_item("Bentley Treats", "A focus snack for the city's best Shiba."))
	defaults.append(_make_item("Clorox Wipes", "Useful for fingerprints, smug glass, and dramatic reveals."))
	defaults.append(_make_item("Lockpick Hairpin", "A stylish backup plan."))
	defaults.append(_make_item("Doctor's Note", "Jake insists this counts as risk management."))
	return defaults

func _make_item(item_name: String, description: String) -> EquipmentItem:
	var item := EquipmentItem.new()
	item.item_name = item_name
	item.description = description
	return item

func _on_toggle_equip(item: EquipmentItem, add: bool) -> void:
	if add:
		if equipped.size() >= max_equipped:
			_refresh_selected()
			return
		if not equipped.has(item):
			equipped.append(item)
	else:
		equipped.erase(item)
	_refresh_selected()

func _refresh_selected() -> void:
	for child in selected_items.get_children():
		child.queue_free()
	for item in equipped:
		var label := Label.new()
		label.text = item.item_name
		selected_items.add_child(label)

func _on_start_mission() -> void:
	GameState.equipped_items = []
	for item in equipped:
		GameState.equipped_items.append(item.item_name)
	SceneManager.start_pending_mission()
