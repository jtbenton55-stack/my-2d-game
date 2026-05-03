class_name MissionZoneDefinition
extends Resource

@export var zone_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var origin: Vector2i = Vector2i.ZERO
@export var size: Vector2i = Vector2i(6, 6)
@export var route_tags: Array[String] = []
@export var objective_ids: Array[String] = []
@export var gate_ids: Array[String] = []
