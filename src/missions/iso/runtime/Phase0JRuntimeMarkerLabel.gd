@tool
class_name Phase0JRuntimeMarkerLabel
extends Node2D

@export var marker_id: String = ""
@export var category: String = ""
@export_multiline var effect_text: String = ""
@export var prompt_text: String = "E/Q"
@export var icon_color: Color = Color(1.0, 0.9, 0.35, 0.9)
@export var label_offset := Vector2(18, -46)


func _ready() -> void:
	z_index = 4090
	set_meta("generated_by", "Phase0J-C2")
	if get_child_count() == 0:
		_build_label()


func mark_collected() -> void:
	modulate = Color(0.45, 0.45, 0.45, 0.75)
	for child in get_children():
		if child is Label:
			var label := child as Label
			if not label.text.contains("COLLECTED"):
				label.text += "\nCOLLECTED"


func reset_collected() -> void:
	modulate = Color(1, 1, 1, 1)
	for child in get_children():
		if child is Label:
			var label := child as Label
			label.text = label.text.replace("\nCOLLECTED", "")


func _build_label() -> void:
	var icon := Polygon2D.new()
	icon.name = "RuntimeIcon"
	icon.polygon = PackedVector2Array([Vector2(0, -10), Vector2(12, 0), Vector2(0, 10), Vector2(-12, 0)])
	icon.color = icon_color
	icon.z_index = 4090
	add_child(icon)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.position = label_offset + Vector2(-4, -2)
	bg.size = Vector2(190, 54)
	bg.color = Color(0.02, 0.02, 0.02, 0.78)
	bg.z_index = 4090
	add_child(bg)
	var label := Label.new()
	label.name = "Text"
	label.position = label_offset
	label.size = Vector2(184, 60)
	label.text = "%s\n%s - %s\n%s" % [marker_id, category, effect_text, prompt_text]
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 10)
	label.z_index = 4091
	add_child(label)
