extends Node2D

@export_multiline var clue_text: String = """
STERLING CLUE #1

"The bag is just the beginning. 
The trail leads to the Velvet Paw,
where music hides the truth.

- Your benefactor"
"""

var shown := false

func show_note() -> void:
	if shown:
		return
	shown = true
	
	DialogueManager.show_simple_dialogue([
		{"speaker": "Note Found", "text": clue_text}
	])
	
	AudioManager.play_sfx("paper_rustle")
