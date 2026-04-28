extends Button

var letter := ""

func set_letter(value: String) -> void:
	letter = value
	text = value

func _get_drag_data(_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = letter
	preview.add_theme_font_size_override("font_size", 28)
	set_drag_preview(preview)
	return {"letter": letter}
