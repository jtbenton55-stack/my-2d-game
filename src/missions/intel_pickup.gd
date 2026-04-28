extends Area2D

@export var intel_id: String = ""
@export var intel_title: String = "Intel"
@export var intel_description: String = "Valuable information found."
@export var grants_polaroid: String = ""

signal intel_collected(intel_id: String)

var collected := false

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	if collected:
		return
	
	collected = true
	
	# Show intel discovery
	DialogueManager.show_simple_dialogue([
		{"speaker": "Intel", "text": intel_title + ": " + intel_description}
	])
	
	# Grant polaroid if specified
	if grants_polaroid != "":
		CollectibleManager.collect_polaroid(grants_polaroid)
	
	# Emit signal
	intel_collected.emit(intel_id)
	AudioManager.play_sfx("intel_pickup")
	
	# Visual feedback
	visible = false
