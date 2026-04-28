extends Area2D

@export var collectible_id: String = ""
@export var collectible_type: String = "polaroid"
@export var title: String = "Collectible"
@export var description: String = "A mysterious item."

@onready var sprite: Polygon2D = $Visual
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("interactable")
	label.text = "[" + title + "]"

var _last_body: Node = null

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_last_body = body
		_collect()

func _collect() -> void:
	match collectible_type:
		"polaroid":
			if CollectibleManager.collect_polaroid(collectible_id):
				AudioManager.play_sfx("polaroid_collect")
				QuestManager.set_objective("Collected: " + title)
		"intel":
			GameState.intel_points += 1
			AudioManager.play_sfx("intel_collect")
		"health":
			if _last_body and _last_body.has_method("heal"):
				_last_body.heal(25)
				AudioManager.play_sfx("heal")
		_:
			AudioManager.play_sfx("item_pickup")
	
	visible = false
	set_deferred("monitoring", false)
