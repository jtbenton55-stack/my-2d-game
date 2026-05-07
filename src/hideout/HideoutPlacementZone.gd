extends Area2D
class_name HideoutPlacementZone

@export var zone_id := ""
@export var zone_display_name := ""
@export var allowed_tags: Array[String] = []
@export var highlight_debug := true
@export_multiline var description := ""

func _ready() -> void:
	add_to_group("hideout_placeable")
	add_to_group("hideout_snap_zone")
	monitoring = false
	monitorable = false
