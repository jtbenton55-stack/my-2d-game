class_name MissionSpawnDefinition
extends Resource

enum SpawnType {
	PLAYER,
	DOG,
	ENEMY,
	FRIEND,
	PROP_PLACEHOLDER
}

@export var spawn_id: String = ""
@export var type: SpawnType = SpawnType.ENEMY
@export var scene_path: String = ""
@export var marker_cell: Vector2i = Vector2i.ZERO
@export var zone_id: String = ""
@export var route_id: String = ""
@export var heat_min: int = 0
@export var count: int = 1
