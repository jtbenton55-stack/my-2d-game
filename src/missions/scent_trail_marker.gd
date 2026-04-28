extends Area2D

@export var marker_id: int = 1
@export var sniff_distance: float = 60.0

signal sniffed(marker_id: int)

var sniffed_by_bentley := false
var bentley: Node2D = null

func _ready() -> void:
	add_to_group("scent_trail")
	body_entered.connect(_on_body_entered)

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
		sniffed.emit(marker_id)
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
		sniffed.emit(marker_id)
		AudioManager.play_sfx("bentley_sniff")
		modulate = Color(0.4, 0.8, 0.4, 0.6)
