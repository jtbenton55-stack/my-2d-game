extends Area2D

@export var chain: ObjectiveChain
@export var completes_on_interact := true
@export var completes_on_player_enter := false

var current_step := 0

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	_update_objective()

func interact(_player: Node) -> void:
	if completes_on_interact:
		complete_current()

func complete_current() -> void:
	current_step += 1
	_update_objective()

func _update_objective() -> void:
	if chain == null:
		return
	if current_step < chain.steps.size():
		QuestManager.set_objective(chain.steps[current_step], chain.mission_id)
	else:
		QuestManager.complete_objective(chain.mission_id)
		EventBus.debug("Mission objective chain complete: " + chain.mission_id)

func _on_body_entered(body: Node) -> void:
	if completes_on_player_enter and body.is_in_group("player"):
		complete_current()
