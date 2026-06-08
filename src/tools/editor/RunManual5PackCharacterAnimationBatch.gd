@tool
extends EditorScript

const EXPORTER := preload("res://addons/character_animation_mapper/CharacterAnimationSpriteFramesExporter.gd")
const PREVIEW_DIR := "res://resources/character_animation_maps/generated_preview/"

const TARGETS: Array[Dictionary] = [
	{
		"map": "res://resources/character_animation_maps/character__working_manual_map.json",
		"spriteframes": PREVIEW_DIR + "character_01_parmida_reference_variant_preview_spriteframes.tres",
	},
	{
		"map": "res://resources/character_animation_maps/character_02_neon_runner_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_02_neon_runner_preview_spriteframes.tres",
	},
	{
		"map": "res://resources/character_animation_maps/character_03_cyber_tech_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_03_cyber_tech_preview_spriteframes.tres",
	},
	{
		"map": "res://resources/character_animation_maps/character_04_street_bruiser_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_04_street_bruiser_preview_spriteframes.tres",
	},
	{
		"map": "res://resources/character_animation_maps/character_05_nocturne_guard_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_05_nocturne_guard_preview_spriteframes.tres",
	},
]


func _run() -> void:
	var results: Array[Dictionary] = []
	for target in TARGETS:
		var result: Dictionary = EXPORTER.save_spriteframes_from_map(
			String(target.get("map", "")),
			String(target.get("spriteframes", ""))
		)
		results.append(result)
		print(JSON.stringify(result, "\t"))
	print(JSON.stringify({"results": results}, "\t"))
