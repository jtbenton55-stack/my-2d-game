extends Control

@onready var grid_container: GridContainer = $Panel/GridContainer
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel
@onready var description_label: Label = $DescriptionPanel/DescriptionLabel

var polaroid_data: Dictionary = {
	"taco_bell_polaroid": {"title": "The Drop", "description": "Louis's bag, recovered. The first thread in a larger knot.", "color": Color(0.8, 0.6, 0.3)},
	"jazz_club_polaroid": {"title": "Midnight Jazz", "description": "Yordano's bass still hums with secrets.", "color": Color(0.3, 0.3, 0.5)},
	"rewrite_room_polaroid": {"title": "The Rewrite", "description": "Mere's documents. Creative theft is still theft.", "color": Color(0.5, 0.4, 0.6)},
	"car_chase_polaroid": {"title": "Rainy Getaway", "description": "Dom drives. The city blurs. Evidence doesn't.", "color": Color(0.2, 0.3, 0.4)},
	"final_crew_polaroid": {"title": "The Full Deck", "description": "Every favor called in. Every friend present.", "color": Color(0.6, 0.5, 0.2)}
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	description_label.text = "Select a polaroid to view its memory."
	_populate_gallery()

func _populate_gallery() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	for polaroid_id in GameState.collected_polaroids:
		var data: Dictionary = polaroid_data.get(polaroid_id, {"title": "Unknown", "description": "Memory data corrupted.", "color": Color(0.5, 0.5, 0.5)})
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

func _on_polaroid_selected(_polaroid_id: String, data: Dictionary) -> void:
	description_label.text = "[b]" + data.title + "[/b]\n\n" + data.description
	AudioManager.play_sfx("ui_select")

func _on_back_pressed() -> void:
	SceneManager.return_to_hideout()
