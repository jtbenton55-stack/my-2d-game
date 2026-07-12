extends SceneTree

const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		printerr("PHASE6_RETRY_SMOKE load_failed")
		quit(1)
		return
	var mission := packed.instantiate()
	root.add_child(mission)
	await process_frame
	await physics_frame
	await process_frame
	var proxy := mission.get_node_or_null("GameplayRoot/GeneratedRuntimeCollision/WallCollision/WallCellBody")
	if proxy == null or proxy.get_child_count() != 1420:
		printerr("PHASE6_RETRY_SMOKE runtime_contract_failed")
		mission.queue_free()
		await process_frame
		quit(2)
		return
	mission.queue_free()
	await physics_frame
	await process_frame
	await process_frame
	print("PHASE6_RETRY_SMOKE loaded=1 proxy_shapes=1420 freed=1 clean_quit=1")
	quit(0)
