@tool
extends EditorScript

const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIsoBlockout.tscn"
const OUTPUT_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const OUTPUT_TEST_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_Test.tscn"


func _run() -> void:
	var source := load(SOURCE_SCENE) as PackedScene
	if source == null:
		push_error("BakeIsoMissionToEditableScene: failed loading source scene: " + SOURCE_SCENE)
		return
	var instance := source.instantiate() as Node2D
	if instance == null:
		push_error("BakeIsoMissionToEditableScene: failed instantiating source scene.")
		return
	if not instance.has_method("bake_to_editable_scene"):
		push_error("BakeIsoMissionToEditableScene: source scene root does not support bake_to_editable_scene().")
		return
	var baked: Dictionary = instance.call("bake_to_editable_scene", OUTPUT_SCENE, true)
	if baked.get("ok", false) != true:
		push_error("BakeIsoMissionToEditableScene: bake failed: " + str(baked))
		return
	if instance.has_method("bake_hand_edit_test_scene"):
		var test: Dictionary = instance.call("bake_hand_edit_test_scene", OUTPUT_SCENE, OUTPUT_TEST_SCENE, true)
		if test.get("ok", false) != true:
			push_warning("BakeIsoMissionToEditableScene: test-scene bake failed: " + str(test))
	print("BakeIsoMissionToEditableScene: wrote " + OUTPUT_SCENE)
