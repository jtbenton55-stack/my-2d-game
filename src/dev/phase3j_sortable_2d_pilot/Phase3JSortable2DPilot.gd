extends Node2D
## Phase 3J validation pilot — isolated sortable 2.5D depth contract test.
## Not referenced by production scenes, autoloads, or mission runtime.

const MOVE_SPEED := 240.0

@onready var _player_proxy: Node2D = $VisualRoot/SortableWorld/PlayerProxy
@onready var _npc_proxy: Node2D = $VisualRoot/SortableWorld/NPCProxy
@onready var _sortable_prop: Node2D = $VisualRoot/SortableWorld/SortableProp
@onready var _sort_hint_label: Label = $VisualRoot/DebugVisuals/SortHintLabel
@onready var _info_label: Label = $VisualRoot/DebugVisuals/InfoLabel


func _ready() -> void:
	_update_sort_hint()


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_player_proxy.position += direction * MOVE_SPEED * delta
	_update_sort_hint()


func _update_sort_hint() -> void:
	if _sort_hint_label == null or _player_proxy == null or _sortable_prop == null:
		return
	var player_y := _player_proxy.position.y
	var prop_y := _sortable_prop.position.y
	var npc_y := _npc_proxy.position.y if _npc_proxy != null else 0.0
	var relation := "Near prop Y band — watch draw-order transition."
	if player_y < prop_y - 6.0:
		relation = "Player ABOVE prop — prop should draw IN FRONT of player."
	elif player_y > prop_y + 6.0:
		relation = "Player BELOW prop — player should draw IN FRONT of prop."
	_sort_hint_label.text = (
		"Player Y=%.0f | Prop Y=%.0f | NPC Y=%.0f | %s"
		% [player_y, prop_y, npc_y, relation]
	)
	if _info_label != null:
		_info_label.text = (
			"SortableWorld uses y_sort_enabled. Origins are floor-contact pivots. "
			+ "WASD to move player proxy."
		)
