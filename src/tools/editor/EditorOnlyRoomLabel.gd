@tool
class_name EditorOnlyRoomLabel
extends Node2D
## Phase 0J — Editor-only black/dark room label.
##
## Renders a high-contrast room name in the Godot editor on top of all map
## layers, hidden at runtime. Uses _draw() with the default theme font so we
## do not need to ship a font resource.
##
## Phase 0J rules (per user):
##   - editor helper under res://src/tools/editor/.
##   - hidden at runtime (player never sees it).
##   - not a gameplay node: no groups, no collision, no marker fields.

@export var label_text: String = "Room"
@export var font_size: int = 32
@export var label_color: Color = Color(0, 0, 0, 1.0)
@export var outline_color: Color = Color(1, 1, 1, 0.8)
@export var outline_size: int = 6
@export var hide_at_runtime: bool = true


func _ready() -> void:
	z_index = 4096
	z_as_relative = false
	if hide_at_runtime and not Engine.is_editor_hint():
		visible = false
	queue_redraw()


func _set(property: StringName, _value: Variant) -> bool:
	# Repaint when any export property changes inside the editor.
	if Engine.is_editor_hint():
		queue_redraw()
	return false


func _draw() -> void:
	if not Engine.is_editor_hint() and hide_at_runtime:
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var size := Vector2.ZERO
	if font.has_method("get_string_size"):
		size = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var top_left := Vector2(-size.x * 0.5, -size.y * 0.5)
	# Draw outline first by drawing the label offset 8 directions in outline_color.
	if outline_size > 0:
		for dx in [-outline_size, 0, outline_size]:
			for dy in [-outline_size, 0, outline_size]:
				if dx == 0 and dy == 0:
					continue
				draw_string(
					font,
					top_left + Vector2(dx, dy + size.y * 0.8),
					label_text,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_size,
					outline_color,
				)
	draw_string(
		font,
		top_left + Vector2(0, size.y * 0.8),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		label_color,
	)
