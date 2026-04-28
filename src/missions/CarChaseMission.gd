extends "res://src/levels/LevelBase.gd"

var survival_timer := 0.0
const REQUIRED_SURVIVAL_TIME := 30.0
var survived_long_enough := false

func _ready() -> void:
	mission_id = "fast_family_getaway"
	objective_text = "Survive the chase for 30 seconds, then reach the escape point."
	guard_count = 5
	super._ready()
	QuestManager.set_objective("Drive! Dom's route is the only way out.", mission_id)

func _physics_process(delta: float) -> void:
	# Parent class doesn't override _physics_process, so no super call needed
	if not survived_long_enough:
		survival_timer += delta
		if survival_timer >= REQUIRED_SURVIVAL_TIME:
			survived_long_enough = true
			QuestManager.set_objective("Escape route open! Get to the exit!", mission_id)
			AudioManager.play_sfx("objective_complete")

func complete_level() -> void:
	if not survived_long_enough:
		QuestManager.set_objective("Too soon! The streets are still hot.", mission_id)
		return
	CollectibleManager.collect_polaroid("car_chase_polaroid")
	super.complete_level()
