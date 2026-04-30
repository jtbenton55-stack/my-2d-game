extends Node2D

var player: Node2D = null
var dog: Node2D = null
var active_camera: Camera2D = null

func _ready() -> void:
	AudioManager.play_music("cozy_hideout")
	_spawn_player_and_dog()
	_setup_camera()
	_setup_interactables()
	_setup_trophy_objects()
	_ensure_common_ui()
	QuestManager.set_objective("Use the mission board to choose the next job.")
	if GameState.failed_attempts.size() > 0:
		DialogueManager.start_simple_dialogue([{ "speaker": "Jake", "text": "Welcome back. I patched up the plan, the alibi, and Bentley's ego." }])

func _spawn_player_and_dog() -> void:
	var spawn := _get_spawn_point()
	var player_scene := preload("res://scenes/characters/player.tscn")
	var dog_scene := preload("res://scenes/characters/dog.tscn")
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = spawn.global_position if spawn else Vector2(400, 300)
	dog = dog_scene.instantiate()
	add_child(dog)
	dog.global_position = player.global_position + Vector2(-60, 40)

func _get_spawn_point() -> Node2D:
	if GameState.next_spawn != "":
		var spawn_points := get_node_or_null("SpawnPoints")
		if spawn_points:
			var named_spawn := spawn_points.get_node_or_null(GameState.next_spawn) as Node2D
			if named_spawn:
				GameState.next_spawn = "default"
				return named_spawn
	return get_node_or_null("PlayerSpawn") as Node2D

func _setup_camera() -> void:
	active_camera = get_node_or_null("Camera2D") as Camera2D
	if active_camera:
		active_camera.make_current()

func _process(_delta: float) -> void:
	if active_camera and player:
		active_camera.global_position = player.global_position

func _setup_interactables() -> void:
	var heist_zone := get_node_or_null("HeistStartZone")
	if heist_zone:
		heist_zone.add_to_group("interactable")
		heist_zone.set_meta("interaction", "mission_board")
		heist_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E at the mission board to choose a job.")
		)
	var crew_members := ["CrewMere", "CrewJake", "CrewLouis", "CrewDom", "CrewYordano"]
	for crew_id in crew_members:
		var crew_node := get_node_or_null(crew_id)
		if crew_node:
			crew_node.add_to_group("interactable")
			crew_node.set_meta("interaction", crew_id.to_lower())
	
	var polaroid_zone := get_node_or_null("PolaroidGalleryZone")
	if polaroid_zone:
		polaroid_zone.add_to_group("interactable")
		polaroid_zone.set_meta("interaction", "polaroid_gallery")
		polaroid_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E to view collected memories.")
		)
	
	var crew_menu_zone := get_node_or_null("CrewMenuZone")
	if crew_menu_zone:
		crew_menu_zone.add_to_group("interactable")
		crew_menu_zone.set_meta("interaction", "crew_menu")
		crew_menu_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E to check on your crew.")
		)
	
	var city_hub_zone := get_node_or_null("CityHubZone")
	if city_hub_zone:
		city_hub_zone.add_to_group("interactable")
		city_hub_zone.set_meta("interaction", "city_hub")
		city_hub_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E to step into Nocturne City.")
			)
	
	var evidence_board_zone := get_node_or_null("EvidenceBoardZone")
	if evidence_board_zone:
		evidence_board_zone.add_to_group("interactable")
		evidence_board_zone.set_meta("interaction", "evidence_board")
		evidence_board_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E to review the evidence board.")
			)
	
	var collectibles_shelf_zone := get_node_or_null("CollectiblesShelfZone")
	if collectibles_shelf_zone:
		collectibles_shelf_zone.add_to_group("interactable")
		collectibles_shelf_zone.set_meta("interaction", "collectibles_shelf")
		collectibles_shelf_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E to browse collected Smiskis.")
			)

func _unhandled_input(event: InputEvent) -> void:
	if not (InputMap.has_action("interact") and event.is_action_pressed("interact")):
		return
	if player == null:
		return
	var heist_zone := get_node_or_null("HeistStartZone") as Node2D
	if heist_zone and player.global_position.distance_to(heist_zone.global_position) < 90.0:
		SceneManager.open_mission_select()
		return
	var mere := get_node_or_null("CrewMere") as Node2D
	if mere and player.global_position.distance_to(mere.global_position) < 72.0:
		_show_crew_dialogue("mere")
		return
	
	var jake := get_node_or_null("CrewJake") as Node2D
	if jake and player.global_position.distance_to(jake.global_position) < 72.0:
		_show_crew_dialogue("jake")
		return
	
	var louis := get_node_or_null("CrewLouis") as Node2D
	if louis and player.global_position.distance_to(louis.global_position) < 72.0:
		_show_crew_dialogue("louis")
		return
	
	var dom := get_node_or_null("CrewDom") as Node2D
	if dom and player.global_position.distance_to(dom.global_position) < 72.0:
		_show_crew_dialogue("dom")
		return
	
	var yordano := get_node_or_null("CrewYordano") as Node2D
	if yordano and player.global_position.distance_to(yordano.global_position) < 72.0:
		_show_crew_dialogue("yordano")
		return
	
	var polaroid_zone := get_node_or_null("PolaroidGalleryZone") as Node2D
	if polaroid_zone and player.global_position.distance_to(polaroid_zone.global_position) < 72.0:
		SceneManager.open_polaroid_gallery()
		return
	var crew_menu_zone := get_node_or_null("CrewMenuZone") as Node2D
	if crew_menu_zone and player.global_position.distance_to(crew_menu_zone.global_position) < 72.0:
		SceneManager.open_crew_menu()
		return
	var city_hub_zone := get_node_or_null("CityHubZone") as Node2D
	if city_hub_zone and player.global_position.distance_to(city_hub_zone.global_position) < 72.0:
		SceneManager.open_city_hub()
		return
	var evidence_board_zone := get_node_or_null("EvidenceBoardZone") as Node2D
	if evidence_board_zone and player.global_position.distance_to(evidence_board_zone.global_position) < 72.0:
		SceneManager.open_evidence_board()
		return
	var collectibles_shelf_zone := get_node_or_null("CollectiblesShelfZone") as Node2D
	if collectibles_shelf_zone and player.global_position.distance_to(collectibles_shelf_zone.global_position) < 90.0:
		SceneManager.open_smiski_shelf()
		return

func _ensure_common_ui() -> void:
	if get_node_or_null("HUD") == null:
		var hud := preload("res://scenes/ui/hud.tscn").instantiate()
		hud.name = "HUD"
		add_child(hud)
	if get_node_or_null("DialogueBox") == null:
		var dialogue := preload("res://scenes/ui/DialogueBox.tscn").instantiate()
		dialogue.name = "DialogueBox"
		add_child(dialogue)
	if get_node_or_null("PauseMenu") == null:
		var pause := preload("res://scenes/ui/pause_menu.tscn").instantiate()
		pause.name = "PauseMenu"
		add_child(pause)

func _get_crew_dialogue(crew_id: String) -> Array[Dictionary]:
	var completed := GameState.completed_missions
	var failed := GameState.failed_attempts
	
	match crew_id:
		"mere":
			if failed.size() > completed.size():
				return [{"speaker": "Mere", "text": "The paperwork of failure is lengthy, but I've annotated every clause for next time."}]
			elif completed.has("sterling_tower_heist"):
				return [{"speaker": "Mere", "text": "Sterling's legal team is drafting counter-suits as we speak. Let them. Friendship isn't litigable."}]
			elif completed.has("rewrite_room"):
				return [{"speaker": "Mere", "text": "My creative clients are safe. You should have seen their faces when the rights returned to them."}]
			elif completed.has("taco_bell_drop"):
				return [{"speaker": "Mere", "text": "A real plan is just friendship with a calendar invite. Louis appreciated the punctuality."}]
			else:
				return [{"speaker": "Mere", "text": "A real plan is just friendship with a calendar invite."}]
		
		"jake":
			if failed.size() >= 3:
				return [{"speaker": "Jake", "text": "You've taken some hits. I've upgraded your med kit—max health increased. Try not to test it immediately."}]
			elif completed.has("sterling_tower_heist"):
				return [{"speaker": "Jake", "text": "The crew's all here, healthy and whole. That's the only victory that matters to a medic."}]
			elif completed.has("fast_family_getaway"):
				return [{"speaker": "Jake", "text": "Dom drove you hard out there. Good thing I stocked extra motion-sickness tablets."}]
			elif completed.has("taco_bell_drop"):
				return [{"speaker": "Jake", "text": "Bentley's still sniffing around for more bags. I think he's developed a taste for fast food justice."}]
			else:
				return [{"speaker": "Jake", "text": "Welcome back. If anyone needs patching up, my medical supplies are fully stocked."}]
		
		"louis":
			if completed.has("sterling_tower_heist"):
				return [{"speaker": "Louis", "text": "We did it. We actually did it. Sterling's empire has a hole the size of our friendship in it."}]
			elif completed.has("fast_family_getaway"):
				return [{"speaker": "Louis", "text": "Dom's driving scared me more than Sterling's guards. And I've seen both up close."}]
			elif completed.has("taco_bell_drop"):
				return [{"speaker": "Louis", "text": "You saved my delivery route—and my reputation. The bag had more than receipts in it."}]
			else:
				return [{"speaker": "Louis", "text": "I've mapped out new shortcuts through the alleys. Just say the word."}]
		
		"dom":
			if completed.has("sterling_tower_heist"):
				return [{"speaker": "Dom", "text": "The getaway from Sterling Tower was poetry. Every light green, every intersection clear. Family makes its own luck."}]
			elif completed.has("fast_family_getaway"):
				return [{"speaker": "Dom", "text": "Rain or shine, we move as one. You kept up well back there."}]
			elif failed.has("fast_family_getaway"):
				return [{"speaker": "Dom", "text": "The rain won that round, but my engine's still warm. We'll get 'em next time."}]
			else:
				return [{"speaker": "Dom", "text": "Keys are in the ignition whenever you need a ride."}]
		
		"yordano":
			if completed.has("sterling_tower_heist"):
				return [{"speaker": "Yordano", "text": "I composed a bass line for the Sterling Tower heist. Four-four time, minor key, triumphant resolve."}]
			elif completed.has("velvet_paw_jazz_club"):
				return [{"speaker": "Yordano", "text": "The club owner asked why my bass hummed differently that night. I told him: justice has its own frequency."}]
			else:
				return [{"speaker": "Yordano", "text": "The bass is tuned, the setlist is ready. When you need rhythm, you know where to find me."}]
		
		"bentley":
			if completed.has("elephant_in_the_room"):
				return [{"speaker": "Bentley", "text": "*contented woof, gently holding a pink elephant plush in his mouth*"}]
			elif completed.has("sterling_tower_heist"):
				return [{"speaker": "Bentley", "text": "*proud bark, tail wagging with the satisfaction of a job well done*"}]
			elif completed.has("persian_tea_poison_ink"):
				return [{"speaker": "Bentley", "text": "*sophisticated woof, clearly approving of sour cherry tea*"}]
			elif failed.size() > 0:
				return [{"speaker": "Bentley", "text": "*judgmental stare, followed by a forgiving nose-boop*"}]
			else:
				return [{"speaker": "Bentley", "text": "*expectant woof, ready for the next adventure*"}]
		
		_:
			return [{"speaker": crew_id.capitalize(), "text": "Ready when you are, boss."}]

func _show_crew_dialogue(crew_id: String) -> void:
	var lines := _get_crew_dialogue(crew_id)
	DialogueManager.start_simple_dialogue(lines)

func _setup_trophy_objects() -> void:
	var completed := GameState.completed_missions
	
	var plant_shelf := get_node_or_null("TrophyPlantShelf")
	if plant_shelf:
		plant_shelf.visible = completed.has("persian_tea_poison_ink")
	
	var tea_station := get_node_or_null("TrophyTeaStation")
	if tea_station:
		tea_station.visible = completed.has("persian_tea_poison_ink")
	
	var diamond_shelf := get_node_or_null("TrophyDiamondShelf")
	if diamond_shelf:
		diamond_shelf.visible = completed.has("diamond_a_year_job")
	
	var stationery_desk := get_node_or_null("TrophyStationeryDesk")
	if stationery_desk:
		stationery_desk.visible = completed.has("rewrite_room")
	
	var ellie_corner := get_node_or_null("TrophyEllieCorner")
	if ellie_corner:
		ellie_corner.visible = completed.has("elephant_in_the_room")
	
	var arm_wrestling_trophy := get_node_or_null("TrophyArmWrestling")
	if arm_wrestling_trophy:
		arm_wrestling_trophy.visible = completed.has("arm_wrestling_underground")
	
	var shadow_poster := get_node_or_null("TrophyShadowPoster")
	if shadow_poster:
		shadow_poster.visible = completed.has("shadow_solo_contract")
