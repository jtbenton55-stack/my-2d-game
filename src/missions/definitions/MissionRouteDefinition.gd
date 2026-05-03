class_name MissionRouteDefinition
extends Resource

enum RouteType {
	MAIN,
	STEALTH,
	COMBAT,
	FRIEND_ASSIST,
	OPTIONAL
}

@export var route_id: String = ""
@export var display_name: String = ""
@export var type: RouteType = RouteType.MAIN
@export var zone_ids: Array[String] = []
@export var required_gate_ids: Array[String] = []
@export var required_card: String = ""
@export var required_item: String = ""
@export var required_clue: String = ""
@export var required_crew_assist: String = ""
@export_multiline var locked_message: String = "Route locked."
@export_multiline var unlocked_message: String = "Route unlocked."
@export var is_active := true
@export var is_future_placeholder := false
@export var notes: String = ""
