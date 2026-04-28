extends "res://src/levels/LevelBase.gd"

var ledger_collected := false

func _ready() -> void:
	mission_id = "velvet_paw_jazz_club"
	objective_text = "Steal the blackmail ledger from the stage, then exit."
	guard_count = 4
	super._ready()
	
	var ledger := get_node_or_null("LedgerZone")
	if ledger:
		ledger.add_to_group("interactable")
		ledger.body_entered.connect(_on_ledger_body_entered)
	
	# Check if sniff trail should be shown via card effects
	if CardEffects and CardEffects.show_sniff_trail():
		_create_sniff_trail()

func _create_sniff_trail() -> void:
	var trail := Line2D.new()
	trail.points = PackedVector2Array([
		Vector2(100, 600), Vector2(200, 500),
		Vector2(300, 400), Vector2(400, 300),
		Vector2(500, 150)
	])
	trail.width = 4.0
	trail.default_color = Color(0.4, 0.8, 0.4, 0.6)
	add_child(trail)

func _on_ledger_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		ledger_collected = true
		QuestManager.set_objective("Ledger secured. Time to disappear.", mission_id)
		var ledger := get_node_or_null("LedgerZone")
		if ledger:
			ledger.visible = false
		AudioManager.play_sfx("item_pickup")

func complete_level() -> void:
	if not ledger_collected:
		QuestManager.set_objective("The ledger stays. We don't leave witnesses.", mission_id)
		return
	CollectibleManager.collect_polaroid("jazz_club_polaroid")
	super.complete_level()
