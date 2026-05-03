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
@export var notes: String = ""
