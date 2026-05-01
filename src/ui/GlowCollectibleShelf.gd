extends Control
## Lists legally-safe tiny environmental collectibles (Glow Guys, Shelf Goblins, etc.).

@onready var list_label: Label = $Panel/ListLabel
@onready var back_button: Button = $BackButton

## IDs shown on this shelf (canonical + legacy save IDs until migrated).
const SHELF_POLAROID_IDS: Array[String] = [
	"taco_bell_glow_guys",
	"velvet_shelf_goblins",
	"velvet_bathroom_glow_guy",
	"louis_tiny_icon_delivery_bag",
	"yordano_tiny_icon_headphones",
	"taco_bell_smiskis",
	"velvet_smiskis",
]


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_render_shelf_list()


func _is_shelf_polaroid(id: String) -> bool:
	if SHELF_POLAROID_IDS.has(id):
		return true
	var n := GameState.normalize_polaroid_id(id)
	return SHELF_POLAROID_IDS.has(n)


func _render_shelf_list() -> void:
	var found: Array[String] = []
	var seen: Dictionary = {}
	for item in GameState.collected_polaroids:
		var id := String(item)
		if not _is_shelf_polaroid(id):
			continue
		var canon := GameState.normalize_polaroid_id(id)
		if seen.has(canon):
			continue
		seen[canon] = true
		found.append(canon)
	found.sort()
	if found.is_empty():
		list_label.text = "No Glow Guys or Shelf Goblins yet.\n\nSearch mission corners and optional routes."
		return
	var lines: Array[String] = ["Collected (Glow Guys / Shelf Goblins):"]
	for pid in found:
		var info := CollectibleManager.get_polaroid_info(pid)
		lines.append("- " + String(info.get("title", pid)))
	list_label.text = "\n".join(lines)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	SceneManager.return_to_hideout()
