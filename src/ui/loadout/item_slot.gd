extends Button
class_name LoadoutItemSlot

signal equip_toggled(item: EquipmentItem, add: bool)

var item: EquipmentItem
var equipped := false

func setup(value: EquipmentItem) -> void:
	item = value
	text = item.item_name
	tooltip_text = item.description

func _ready() -> void:
	toggle_mode = true
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	equipped = toggled_on
	equip_toggled.emit(item, equipped)
