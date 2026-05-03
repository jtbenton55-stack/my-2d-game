class_name MissionRewardDefinition
extends Resource

enum RewardType {
	SCHEME_CARD,
	POLAROID,
	CREW_FAVOR,
	INTEL,
	PLAYER_UPGRADE,
	BENTLEY_UPGRADE
}

@export var reward_id: String = ""
@export var display_name: String = ""
@export var type: RewardType = RewardType.SCHEME_CARD
@export var mission_id: String = ""
@export_multiline var description: String = ""
@export var effect_type: String = "route_access"
@export var effect_data: Dictionary = {}
@export var is_unlocked_by_default := false
@export var notes: String = ""
