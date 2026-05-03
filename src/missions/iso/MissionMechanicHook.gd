class_name MissionMechanicHook
extends Area2D
## Generic placeholder hook for Mission Bible mechanics. Specific missions can replace behavior later.

@export_enum(
	"bentley_scent_trail",
	"music_rhythm_timing",
	"annotation_legal_puzzle",
	"chase_lane_evidence_stability",
	"clean_to_reveal",
	"laser_timing_vault",
	"arm_wrestling_timing",
	"tea_brewing",
	"bentley_led_trail",
	"shadow_echo_combat",
	"final_tower_crew_chain"
) var mechanic_id: String = "bentley_scent_trail"
@export var display_name: String = "Mission Mechanic"
@export_multiline var placeholder_text: String = "Placeholder mechanic triggered."
@export var objective_update: String = ""
@export var auto_trigger_on_enter := true
@export var once_only := true

var _triggered := false


func _ready() -> void:
	add_to_group("interactable")
	if auto_trigger_on_enter and not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func interact(_player: Node) -> void:
	trigger()


func trigger() -> void:
	if once_only and _triggered:
		return
	_triggered = true
	var line := placeholder_text
	if line == "":
		line = display_name + " placeholder triggered."
	DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": line }])
	if objective_update != "":
		QuestManager.set_objective(objective_update)
	EventBus.debug("Mission mechanic placeholder: " + mechanic_id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		trigger()
