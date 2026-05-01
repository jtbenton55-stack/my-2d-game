class_name MissionMutationHelper
extends RefCounted
## Thin wrapper so missions request save-stable mutation rolls via GameState.


static func roll(mission_id: String, pool: Dictionary) -> Dictionary:
	return GameState.get_or_roll_mission_mutations(mission_id, pool)
