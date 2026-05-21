# GdUnit4 tests for Phase 3C/3D/3E runtime debug-label visibility policy.
extends GdUnitTestSuite

const HiderScript := preload("res://src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd")


func test_default_preserves_generated_runtime_marker_labels() -> void:
	var fixture: Dictionary = await _spawn_fixture(false, false, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.labels.visible).is_true()
	_teardown(fixture)


func test_opt_in_hides_generated_runtime_marker_labels() -> void:
	var fixture: Dictionary = await _spawn_fixture(true, false, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.labels.visible).is_false()
	assert_bool(fixture.labels.has_meta("phase_0ja_hidden_at_runtime")).is_true()
	_teardown(fixture)


func test_missing_generated_labels_path_does_not_crash() -> void:
	var fixture: Dictionary = await _spawn_fixture(true, false, false)
	fixture.hider.generated_runtime_marker_labels_path = NodePath("../../MissingGeneratedRuntimeMarkerLabels")
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.pilot.visible).is_true()
	_teardown(fixture)


func test_opt_in_does_not_hide_plug_and_play_or_interactables() -> void:
	var fixture: Dictionary = await _spawn_fixture(true, false, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.pilot.visible).is_true()
	assert_bool(fixture.interactables.visible).is_true()
	_teardown(fixture)


func test_security_author_labels_hidden_when_opt_in() -> void:
	var fixture: Dictionary = await _spawn_fixture(false, true, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.author_label.visible).is_false()
	assert_bool(fixture.security_beam_author.visible).is_true()
	_teardown(fixture)


func test_security_taco_policy_hides_author_and_preserves_proof_door_labels() -> void:
	var fixture: Dictionary = await _spawn_security_label_fixture(true, true, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.author_label.visible).is_false()
	assert_bool(fixture.proof_label.visible).is_true()
	assert_bool(fixture.door_label.visible).is_true()
	_teardown(fixture)


func test_security_author_label_without_residue_flag_leaves_at_label_residue_visible() -> void:
	var fixture: Dictionary = await _spawn_security_label_fixture(true, false, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.author_label.visible).is_false()
	assert_bool(fixture.residue_label.visible).is_true()
	_teardown(fixture)


func test_security_proof_and_door_labels_hidden_when_opt_in() -> void:
	var fixture: Dictionary = await _spawn_security_label_fixture(false, false, true)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.proof_label.visible).is_false()
	assert_bool(fixture.door_label.visible).is_false()
	assert_bool(fixture.readability_visuals.visible).is_true()
	_teardown(fixture)


func test_default_preserves_proof_and_door_labels() -> void:
	var fixture: Dictionary = await _spawn_security_label_fixture(true, true, false)
	await _await_hide_applied(fixture.hider)
	assert_bool(fixture.proof_label.visible).is_true()
	assert_bool(fixture.door_label.visible).is_true()
	_teardown(fixture)


func _spawn_fixture(hide_labels: bool, hide_security: bool, hide_residue: bool = false):
	var root := Node2D.new()
	root.name = "TacoBellIso_Editable"
	var gameplay := Node2D.new()
	gameplay.name = "GameplayRoot"
	var labels := Node2D.new()
	labels.name = "GeneratedRuntimeMarkerLabels"
	var label_child := Label.new()
	label_child.name = "Text"
	labels.add_child(label_child)
	var pilot := Node2D.new()
	pilot.name = "PlugAndPlayPilot"
	var interactables := Node2D.new()
	interactables.name = "GeneratedRuntimeInteractables"
	var security := Node2D.new()
	security.name = "SecurityAuthoringRoot"
	var beam_author := Node2D.new()
	beam_author.name = "AMBUSH_security_beam"
	var author_label := Label.new()
	author_label.name = "AuthorLabel"
	beam_author.add_child(author_label)
	security.add_child(beam_author)
	var helpers := Node.new()
	helpers.name = "RuntimeHelpers"
	var hider: Node = HiderScript.new()
	hider.hide_generated_runtime_marker_labels = hide_labels
	hider.hide_security_author_labels = hide_security
	hider.hide_security_label_residue = hide_residue
	helpers.add_child(hider)
	gameplay.add_child(labels)
	gameplay.add_child(pilot)
	gameplay.add_child(interactables)
	gameplay.add_child(security)
	gameplay.add_child(helpers)
	root.add_child(gameplay)
	add_child(root)
	await get_tree().process_frame
	return {
		"root": root,
		"hider": hider,
		"labels": labels,
		"pilot": pilot,
		"interactables": interactables,
		"author_label": author_label,
		"security_beam_author": beam_author,
	}


func _spawn_security_label_fixture(hide_author: bool, hide_residue: bool, hide_proof_door: bool = false):
	var root := Node2D.new()
	root.name = "TacoBellIso_Editable"
	var gameplay := Node2D.new()
	gameplay.name = "GameplayRoot"
	var readability := Node2D.new()
	readability.name = "SecurityHazardReadabilityVisuals"
	var security := Node2D.new()
	security.name = "SecurityAuthoringRoot"
	var trigger_author := Node2D.new()
	trigger_author.name = "TestAreaGuardTrigger_Author"
	var author_label := Label.new()
	author_label.name = "AuthorLabel"
	var residue_label := Label.new()
	residue_label.name = "@Label@80965"
	var proof_marker := Node2D.new()
	proof_marker.name = "D6_05_ProofMarker"
	var proof_label := Label.new()
	proof_label.name = "ProofLabel"
	var door_proof := Node2D.new()
	door_proof.name = "TestDoorLockProof"
	var door_target := Node2D.new()
	door_target.name = "D6_05A_TestDoorLock_Target"
	var door_label := Label.new()
	door_label.name = "DoorLabel"
	trigger_author.add_child(author_label)
	trigger_author.add_child(residue_label)
	proof_marker.add_child(proof_label)
	door_target.add_child(door_label)
	door_proof.add_child(door_target)
	security.add_child(trigger_author)
	security.add_child(proof_marker)
	security.add_child(door_proof)
	var helpers := Node.new()
	helpers.name = "RuntimeHelpers"
	var hider: Node = HiderScript.new()
	hider.hide_security_author_labels = hide_author
	hider.hide_security_label_residue = hide_residue
	hider.hide_security_proof_and_door_labels = hide_proof_door
	helpers.add_child(hider)
	gameplay.add_child(readability)
	gameplay.add_child(security)
	gameplay.add_child(helpers)
	root.add_child(gameplay)
	add_child(root)
	await get_tree().process_frame
	return {
		"root": root,
		"hider": hider,
		"author_label": author_label,
		"residue_label": residue_label,
		"proof_label": proof_label,
		"door_label": door_label,
		"readability_visuals": readability,
	}


func _await_hide_applied(hider: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if hider.has_method("_apply_runtime_hide"):
		hider.call("_apply_runtime_hide")


func _teardown(fixture: Dictionary) -> void:
	var root: Node = fixture.get("root")
	if root != null and is_instance_valid(root):
		root.queue_free()
	await get_tree().process_frame
