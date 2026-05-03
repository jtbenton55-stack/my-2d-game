class_name MissionGateDefinition
extends Resource

enum GateType {
	ACCESS_ITEM,
	PUZZLE,
	OBJECTIVE_CHAIN,
	HEAT,
	FRIEND_ASSIST,
	ROUTE_CHOICE
}

@export var gate_id: String = ""
@export var display_name: String = ""
@export var type: GateType = GateType.PUZZLE
@export var required_item_id: String = ""
@export var required_objective_ids: Array[String] = []
@export var marker_cell: Vector2i = Vector2i.ZERO
@export var zone_id: String = ""
@export var locked_text: String = "Locked."
@export var unlocked_text: String = "Unlocked."
