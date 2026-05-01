extends Area2D

@export var marker_id: int = 1
## 0 = orange (food), 1 = blue (Sterling chemical), 2 = green (uncertainty / often the real path when rolled).
@export var trail_family: int = 0
@export var sniff_distance: float = 60.0

signal sniffed(marker_id: int, trail_family: int)

var sniffed_by_bentley := false
var bentley: Node2D = null

func _ready() -> void:
	add_to_group("scent_trail")
	body_entered.connect(_on_body_entered)
	_apply_trail_color()


func _apply_trail_color() -> void:
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis == null:
		return
	match trail_family:
		0:
			vis.modulate = Color(1.0, 0.45, 0.15, 0.55)
		1:
			vis.modulate = Color(0.25, 0.45, 1.0, 0.55)
		2:
			vis.modulate = Color(0.35, 0.9, 0.4, 0.55)
		_:
			vis.modulate = Color(0.4, 0.8, 0.4, 0.5)

func _process(_delta: float) -> void:
	if sniffed_by_bentley:
		return
	
	if bentley == null:
		bentley = get_tree().get_first_node_in_group("bentley")
		return
	
	if not is_instance_valid(bentley):
		bentley = null
		return
	
	# Check if Bentley is close enough to sniff
	if global_position.distance_to(bentley.global_position) <= sniff_distance:
		if bentley.has_method("sniff"):
			bentley.sniff()
		sniffed_by_bentley = true
		sniffed.emit(marker_id, trail_family)
		AudioManager.play_sfx("bentley_sniff")
		
		# Visual feedback
		modulate = Color(0.4, 0.8, 0.4, 0.6)

func _on_body_entered(body: Node) -> void:
	# Player can also trigger the trail
	if body.is_in_group("player") and not sniffed_by_bentley:
		var dog := get_tree().get_first_node_in_group("bentley")
		if dog and dog.has_method("sniff"):
			dog.sniff()
		sniffed_by_bentley = true
		sniffed.emit(marker_id, trail_family)
		AudioManager.play_sfx("bentley_sniff")
		modulate = Color(0.4, 0.8, 0.4, 0.6)
