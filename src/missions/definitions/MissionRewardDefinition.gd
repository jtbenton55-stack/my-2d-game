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
@export var notes: String = ""
