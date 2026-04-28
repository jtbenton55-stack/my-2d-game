extends Area2D

@export_file("*.tscn") var destination_scene: String = ""
@export var spawn_point_name: String = "default"
@export_enum("none", "fade") var transition_in: String = "fade"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if destination_scene == "":
		EventBus.warn("Room transition has no destination scene.")
		return
	GameState.next_spawn = spawn_point_name
	SceneManager.change_scene(destination_scene)
