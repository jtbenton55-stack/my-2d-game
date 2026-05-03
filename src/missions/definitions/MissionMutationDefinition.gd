class_name MissionMutationDefinition
extends Resource

enum MutationType {
	ALTERNATE_CODE,
	ALTERNATE_LOCKED_DOOR,
	ALTERNATE_COLLECTIBLE_LOCATION,
	ALTERNATE_GUARD_ROUTE,
	EXTRA_GUARD,
	FRIEND_HINT,
	OTHER
}

@export var mutation_id: String = ""
@export var type: MutationType = MutationType.OTHER
@export var heat_min: int = 0
@export var failed_attempt_min: int = 0
@export var options: Array[String] = []
@export var target_id: String = ""
@export var hint_text: String = ""


func as_pool_entry() -> Array[String]:
	return options
