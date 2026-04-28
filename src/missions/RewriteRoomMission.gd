extends "res://src/levels/LevelBase.gd"

var documents_collected := false

func _ready() -> void:
	mission_id = "rewrite_room"
	objective_text = "Recover the creative documents from the file room."
	guard_count = 3
	super._ready()
	
	var docs := get_node_or_null("DocumentsZone")
	if docs:
		docs.add_to_group("interactable")
		docs.body_entered.connect(_on_docs_body_entered)
	
	# Check if sniff trail should be shown via card effects
	if CardEffects and CardEffects.show_sniff_trail():
		_create_sniff_trail()

func _create_sniff_trail() -> void:
	var trail := Line2D.new()
	trail.points = PackedVector2Array([
		Vector2(100, 550), Vector2(200, 450),
		Vector2(350, 350), Vector2(500, 250),
		Vector2(625, 175)
	])
	trail.width = 4.0
	trail.default_color = Color(0.4, 0.8, 0.4, 0.6)
	add_child(trail)

func _on_docs_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		documents_collected = true
		QuestManager.set_objective("Documents secured. Mere will handle the legal side.", mission_id)
		var docs := get_node_or_null("DocumentsZone")
		if docs:
			docs.visible = false
		AudioManager.play_sfx("item_pickup")

func complete_level() -> void:
	if not documents_collected:
		QuestManager.set_objective("The documents prove creative theft. We need them.", mission_id)
		return
	CollectibleManager.collect_polaroid("rewrite_room_polaroid")
	super.complete_level()
