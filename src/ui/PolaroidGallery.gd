extends Control

@onready var grid_container: GridContainer = $Panel/GridContainer
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionPanel/DescriptionLabel

var polaroid_data: Dictionary = {
	"taco_bell_polaroid": {"title": "Bentley Judges the Bag", "description": "Louis's bag, recovered — the first thread in a larger knot.", "color": Color(0.8, 0.6, 0.3), "memory": "The Taco Bell parking lot smelled like crushed dreams and hot sauce. Bentley found the bag under a Honda Civic. Louis hugged it like a newborn. First clue secured."},
	"taco_bell_midnight_market_rain": {"title": "Midnight Market Rain", "description": "Hidden shot near the flickering streetlight.", "color": Color(0.45, 0.55, 0.85), "memory": "Wet pavement, neon halal cart parody, Bentley's nose never clocked out."},
	"jazz_club_polaroid": {"title": "Midnight Jazz", "description": "Yordano's bass still hums with secrets.", "color": Color(0.3, 0.3, 0.5), "memory": "The Velvet Paw basement. Yordano's fingers dancing across bass strings while we crept past sleeping guards. The setlist had more than songs—it had Sterling's blackmail ledger hidden in the margins."},
	"rewrite_room_polaroid": {"title": "The Rewrite", "description": "Mere's documents. Creative theft is still theft.", "color": Color(0.5, 0.4, 0.6), "memory": "Mere's office at midnight. Stacks of contracts written in lawyer-language designed to steal stories. We rewrote the narrative—literally. Took back what belonged to the artists."},
	"car_chase_polaroid": {"title": "Rainy Getaway", "description": "Dom drives. The city blurs. Evidence doesn't.", "color": Color(0.2, 0.3, 0.4), "memory": "Rain hammering the windshield. Dom's hands steady on the wheel. Bentley barking at every black sedan that looked too official. The evidence in the trunk, Sterling's men in the rearview. Family sticks together."},
	"final_crew_polaroid": {"title": "The Full Deck", "description": "Every favor called in. Every friend present.", "color": Color(0.6, 0.5, 0.2), "memory": "Sterling Tower. All of us. Jake with his medical kit, Mere with her legal documents, Dom with his keys, Yordano with his perfect timing. Even Bentley wore a tiny bow tie. We didn't just rob a tower—we proved friendship is stronger than greed."},
	"clean_job_polaroid": {"title": "The Clean Job", "description": "A luxury showroom code revealed by spotless glass.", "color": Color(0.7, 0.8, 0.9), "memory": "The showroom gleamed. Too clean. Jinx's Clorox Wipe Protocol worked—a fingerprint on polished glass revealed the vault code. Sometimes the cleanest jobs leave the biggest messes."},
	"diamond_vault_polaroid": {"title": "Diamond a Year", "description": "The tribute stones lined up by year, each one louder than the last.", "color": Color(0.9, 0.85, 0.95), "memory": "Bryce's Swiss timing clicked down to the millisecond. Fifteen tribute diamonds—one for every year of Sterling's empire. We took them all. Not for the money. For the message."},
	"arm_wrestling_polaroid": {"title": "Arm-Wrestling Underground", "description": "Parmida at the table with Violet watching like a proud coach.", "color": Color(0.8, 0.3, 0.4), "memory": "The underground club smelled like iron and ego. Violet's training paid off—Parmida slammed her opponent's hand down with a grin. 'Counterpunch,' she whispered. 'Never saw it coming.'"},
	"persian_tea_polaroid": {"title": "Persian Tea and Poison Ink", "description": "Sour cherry tea, watercolor clues, and a conservatory saved.", "color": Color(0.9, 0.6, 0.5), "memory": "JC's grandmother's recipe—saffron and sour cherry. The watercolor painting hid the poison ink formula. We saved the conservatory. Saved the tradition. Bentley even approved of the tea."},
	"ellie_polaroid": {"title": "The Elephant in the Room", "description": "Bentley reunited with Ellie, the only creature he respects more than himself.", "color": Color(0.95, 0.7, 0.8), "memory": "The storage unit. Bentley froze. There she was—Ellie, his pink elephant plush, taken by Sterling years ago. The reunion was... emotional. Bentley carried her in his mouth all the way home."},
	"shadow_solo_polaroid": {"title": "Shadow Solo Contract", "description": "Kiro, Jin, neon shadows, and Bentley being unimpressed.", "color": Color(0.2, 0.2, 0.3), "memory": "Neon signs flickering. Kiro's tech disabling cameras, Jin's forgeries ready. The shadow arena. Bentley yawned at the 'stealth challenge.' We cleared the contract. Sterling lost another foothold."},
	"taco_bell_glow_guys": {"title": "Glow Guys (Taco Run)", "description": "Tiny glow figures tucked behind the late-night loading gear.", "color": Color(0.65, 1.0, 0.7), "memory": "Bentley sniffed out a tiny stash of glow figures near the garage route. Louis called them 'delivery mascots' and refused to explain further."},
	"velvet_shelf_goblins": {"title": "Shelf Goblins (Velvet Paw)", "description": "Chunky shelf mascots in the amp-rack shadows.", "color": Color(0.55, 0.45, 0.85), "memory": "Backstage smelled like cables and ego. One shelf goblin was wedged behind a wedge monitor—Bentley approved the hiding spot."},
	"velvet_bar_polaroid": {"title": "Last Call at the Bar", "description": "The rail, the pour, the pause before the bass hits.", "color": Color(0.45, 0.35, 0.55), "memory": "Velvet Paw bar rail—sticky glass, honest pours, Sterling suits pretending they belonged."},
	"persian_tea_hidden": {"title": "Watercolor Conservatory", "description": "Paper blooms where poison ink almost won.", "color": Color(0.85, 0.72, 0.55), "memory": "JC slid you the conservatory polaroid between tea pours—proof the garden remembered its own name."},
	"ellie_hidden_reunion": {"title": "Bentley Serious Mode", "description": "No jokes when Ellie was missing.", "color": Color(0.9, 0.55, 0.65), "memory": "Bentley didn't bark—he tracked. The reunion polaroid still smells like cardboard and regret."},
	"shadow_solo_hidden_pose": {"title": "Shadow Trial Freeze Frame", "description": "Neon caught mid-motion.", "color": Color(0.35, 0.35, 0.55), "memory": "Kiro nodded once. Jin smirked. Bentley judged everyone's footwear."},
	"taco_bell_perfect_ambush": {"title": "Parking Garage Ambush", "description": "Clean entry, clean exit.", "color": Color(0.55, 0.82, 0.62), "memory": "No alarms, no spotlight chase—just tires, receipts, and Bentley acting like he planned it."},
	"louis_tiny_icon_delivery_bag": {"title": "Louis Tiny Icon", "description": "Shelf trophy energy.", "color": Color(0.92, 0.72, 0.38), "memory": "Louis pretends he doesn't collect merch of himself. You have photographic proof."},
	"jazz_club_hidden_bentley_stage": {"title": "Bentley at the Jazz Stage", "description": "Neon sax haze.", "color": Color(0.42, 0.38, 0.72), "memory": "Stage lights made Bentley look cinematic—and somehow still judgmental."},
	"jazz_club_perfect_bass_blackout": {"title": "Bass Drop Blackout", "description": "No wrong-setlist panic.", "color": Color(0.28, 0.55, 0.82), "memory": "You solved the setlist clean—Yordano didn't have to fold feedback into the bridge."},
	"velvet_bathroom_glow_guy": {"title": "Velvet Paw Glow Guy", "description": "Tile gremlin.", "color": Color(0.62, 1.0, 0.78), "memory": "Something tiny glowed behind the stall door. Bentley refused to comment."},
	"yordano_tiny_icon_headphones": {"title": "Yordano Tiny Icon", "description": "Always on beat.", "color": Color(0.62, 0.48, 0.92), "memory": "Even as a shelf figure, Yordano looks ready to drop the house."},
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	description_label.text = "Select a polaroid to view its memory."
	_populate_gallery()

func _populate_gallery() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	for polaroid_id in GameState.collected_polaroids:
		var nid := GameState.normalize_polaroid_id(polaroid_id)
		var data: Dictionary = polaroid_data.get(polaroid_id, polaroid_data.get(nid, {"title": "Unknown", "description": "Memory data corrupted.", "color": Color(0.5, 0.5, 0.5)}))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 220)
		btn.expand_icon = true
		
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(140, 140)
		color_rect.color = data.color
		vbox.add_child(color_rect)
		
		var label := Label.new()
		label.text = data.title
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(label)
		
		btn.add_child(vbox)
		btn.pressed.connect(_on_polaroid_selected.bind(polaroid_id, data))
		grid_container.add_child(btn)
	
	if GameState.collected_polaroids.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No polaroids collected yet.\nComplete missions to collect memories."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid_container.add_child(empty_label)

var vignette_panel: Control = null

func _on_polaroid_selected(polaroid_id: String, data: Dictionary) -> void:
	AudioManager.play_sfx("ui_select")
	_show_vignette(polaroid_id, data)

func _show_vignette(_polaroid_id: String, data: Dictionary) -> void:
	if vignette_panel != null:
		vignette_panel.queue_free()
		vignette_panel = null
	
	vignette_panel = Control.new()
	vignette_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette_panel)
	
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.85)
	vignette_panel.add_child(dim)
	
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 400)
	panel.size = Vector2(500, 400)
	panel.position = Vector2(get_viewport_rect().size.x / 2 - 250, get_viewport_rect().size.y / 2 - 200)
	vignette_panel.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	panel.add_child(vbox)
	
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(200, 200)
	color_rect.color = data.get("color", Color(0.5, 0.5, 0.5))
	color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(color_rect)
	
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer1)
	
	var title := Label.new()
	title.text = data.get("title", "Unknown Memory")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.4, 1, 1))
	vbox.add_child(title)
	
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	var desc := Label.new()
	desc.text = data.get("description", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	
	var memory := Label.new()
	memory.text = data.get("memory", "A fragment of the past, preserved.")
	memory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	memory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1))
	vbox.add_child(memory)
	
	var spacer4 := Control.new()
	spacer4.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer4)
	
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_close_vignette)
	vbox.add_child(close_btn)
	
	description_label.text = "Viewing: " + data.get("title", "Unknown")

func _close_vignette() -> void:
	if vignette_panel != null:
		vignette_panel.queue_free()
		vignette_panel = null
	description_label.text = "Select a polaroid to view its memory."

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if vignette_panel != null:
			_close_vignette()
		else:
			_on_back_pressed()

func _on_back_pressed() -> void:
	if vignette_panel != null:
		_close_vignette()
		return
	SceneManager.return_to_hideout()
