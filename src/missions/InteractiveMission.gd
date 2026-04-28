extends "res://src/levels/LevelBase.gd"

@export var completion_item_name := "evidence"
@export var completion_line := "Evidence secured. Reach the exit."
@export var missing_item_line := "There is still work to do before we leave."

var required_total := 0
var required_done := 0
var completed_required: Dictionary = {}

func _ready() -> void:
	super._ready()
	_setup_interactive_zones()

func _setup_interactive_zones() -> void:
	for node in get_tree().get_nodes_in_group("mission_required"):
		if node is Area2D:
			required_total += 1
			node.body_entered.connect(_on_required_entered.bind(node))
	for node in get_tree().get_nodes_in_group("mission_optional"):
		if node is Area2D:
			node.body_entered.connect(_on_optional_entered.bind(node))

func _on_required_entered(body: Node, zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	var key := zone.get_path()
	if completed_required.has(key):
		return
	completed_required[key] = true
	required_done += 1
	zone.visible = false
	zone.set_deferred("monitoring", false)
	AudioManager.play_sfx("item_pickup")
	if required_done >= required_total:
		QuestManager.set_objective(completion_line, get_mission_id())
	else:
		QuestManager.set_objective("%s found: %d/%d" % [completion_item_name.capitalize(), required_done, required_total], get_mission_id())

func _on_optional_entered(body: Node, zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	zone.visible = false
	zone.set_deferred("monitoring", false)
	GameState.intel_points += 1
	AudioManager.play_sfx("intel_collect")
	QuestManager.set_objective("+1 intel. Bentley pretends he found it first.", get_mission_id())

func complete_level() -> void:
	if required_total > 0 and required_done < required_total:
		QuestManager.set_objective(missing_item_line, get_mission_id())
		return
	super.complete_level()
