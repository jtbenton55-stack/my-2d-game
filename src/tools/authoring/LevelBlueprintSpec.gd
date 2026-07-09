@tool
class_name LevelBlueprintSpec
extends RefCounted
## Shared parsing/validation/coverage helpers for dev-only level blueprint specs.
##
## A blueprint spec is a deterministic JSON layout file under res://docs/blueprints/
## that AuthoringBlueprintLayer renders in-editor and Mission Dock audits against.
## Authoring-only: nothing in this class writes files or mutates scenes.

const BLUEPRINT_DIR := "res://docs/blueprints"
const BLUEPRINT_SUFFIX := ".blueprint.json"

const REGION_KINDS: Array[String] = ["floor", "wall", "cover", "collision_barrier", "marker"]

const PAINT_LAYER_BY_KIND: Dictionary = {
	"floor": "GameplayRoot/LayoutRoot/FloorLayer",
	"wall": "GameplayRoot/LayoutRoot/WallLayer",
	"cover": "GameplayRoot/LayoutRoot/CoverLayer",
	"collision_barrier": "GameplayRoot/LayoutRoot/CollisionBarrierLayer",
	"marker": "GameplayRoot/LayoutRoot/MarkerTileLayer",
}

const REGION_COLORS: Dictionary = {
	"floor": Color(0.5, 0.5, 0.55),
	"wall": Color(0.22, 0.28, 0.45),
	"cover": Color(0.3, 0.68, 0.35),
	"collision_barrier": Color(0.85, 0.25, 0.2),
	"marker": Color(0.9, 0.8, 0.25),
}

## Every Mission Dock MECHANIC_TYPES entry must appear here exactly once.
const CATEGORY_BY_TYPE: Dictionary = {
	"SearchZone": "core",
	"RewardNode": "core",
	"InventoryPickupNode": "core",
	"LockedInteractionNode": "core",
	"TerminalHackNode": "core",
	"InteractiveContainer": "core",
	"ExtractionZone": "core",
	"SideObjectiveNode": "core",
	"TriggerZone": "core",
	"RouteUnlockNode": "core",
	"PowerCircuitNode": "puzzle",
	"TimedSwitchNode": "puzzle",
	"PressurePlateNode": "puzzle",
	"DeadDropNode": "puzzle",
	"ObjectSwapNode": "puzzle",
	"BugPlantNode": "puzzle",
	"EavesdropZone": "puzzle",
	"AuditTrailCleanupNode": "paper_trail",
	"HeatSinkObject": "paper_trail",
	"DoorStateMemoryNode": "paper_trail",
	"InspectionZone": "social",
	"BelievableTaskZone": "social",
	"ProtocolZone": "social",
	"ProfessionalismMeterNode": "social",
	"CleanlinessGate": "social",
	"EncounterController": "encounter",
	"ChallengeObjectiveNode": "encounter",
	"EncounterRouteActionNode": "encounter",
	"DisruptionActionNode": "encounter",
	"SchemeCardTriggerNode": "encounter",
	"HideSpotNode": "stealth",
	"InvestigationPointNode": "stealth",
	"RoutineOverrideNode": "stealth",
	"CompanionCommandPoint": "companion_noise",
	"BentleyCrawlspaceConnector": "companion_noise",
	"BentleyWaitMarker": "companion_noise",
	"NoiseEmitterNode": "companion_noise",
	"DistractionObject": "companion_noise",
	"PresentationSequencePlayer": "presentation",
	"DialogueTriggerZone": "presentation",
	"BarkTrigger": "presentation",
	"PlayerStartMarker": "spawn_movement_audio",
	"TeleportZone": "spawn_movement_audio",
	"TeleportTargetMarker": "spawn_movement_audio",
	"MusicTriggerZone": "spawn_movement_audio",
	"SecurityBeamAuthor": "security",
	"SecurityCameraAuthor": "security",
	"GuardSpawnAuthor": "security",
	"GuardPatrolRouteAuthor": "security",
	"AreaTriggerAuthor": "security",
	"SecurityEffectSetAuthor": "security",
	"PoopBagAuthor": "collectible",
	"CaseCashAuthor": "collectible",
	"ClueAuthor": "collectible",
	"GlowGuyAuthor": "collectible",
}

const CATEGORY_COLORS: Dictionary = {
	"core": Color(1.0, 0.6, 0.1),
	"puzzle": Color(0.6, 0.35, 0.9),
	"paper_trail": Color(0.7, 0.5, 0.3),
	"social": Color(1.0, 0.4, 0.7),
	"encounter": Color(0.9, 0.2, 0.35),
	"stealth": Color(0.2, 0.55, 0.35),
	"companion_noise": Color(0.2, 0.8, 0.9),
	"presentation": Color(0.45, 0.7, 1.0),
	"spawn_movement_audio": Color(0.95, 0.85, 0.2),
	"security": Color(0.95, 0.15, 0.15),
	"collectible": Color(0.6, 0.9, 0.2),
}

const SECURITY_PARENT_TYPES: Array[String] = [
	"SecurityBeamAuthor", "SecurityCameraAuthor", "GuardSpawnAuthor",
	"GuardPatrolRouteAuthor", "AreaTriggerAuthor", "SecurityEffectSetAuthor",
	"PoopBagAuthor", "CaseCashAuthor", "ClueAuthor", "GlowGuyAuthor",
]

## Same identity properties Mission Dock scans when suggesting/auditing ids.
const ID_PROPERTIES: Array[String] = [
	"mechanic_id", "beam_id", "camera_id", "spawn_id", "route_id", "trigger_id",
	"effect_id", "collectible_id", "clue_id", "glow_guy_id", "marker_id", "target_id",
]


static func load_spec(path: String) -> Dictionary:
	if path.strip_edges() == "" or not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["Blueprint file not found: %s" % path], "spec": {}}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"ok": false, "errors": ["Blueprint is not a valid JSON object: %s" % path], "spec": {}}
	var spec := parsed as Dictionary
	var errors: Array[String] = []
	_validate_spec(spec, errors)
	return {"ok": errors.is_empty(), "errors": errors, "spec": spec}


static func regions(spec: Dictionary) -> Array:
	var value: Variant = spec.get("regions", [])
	return value if value is Array else []


static func mechanic_slots(spec: Dictionary) -> Array:
	var value: Variant = spec.get("mechanic_slots", [])
	return value if value is Array else []


static func canvas_size(spec: Dictionary) -> Vector2:
	var canvas: Variant = spec.get("canvas", {})
	if canvas is Dictionary:
		return Vector2(float((canvas as Dictionary).get("width", 0.0)), float((canvas as Dictionary).get("height", 0.0)))
	return Vector2.ZERO


static func grid_size(spec: Dictionary) -> float:
	return float(spec.get("grid_size", 64.0))


static func category_for_type(mechanic_type: String) -> String:
	return String(CATEGORY_BY_TYPE.get(mechanic_type, ""))


static func color_for_type(mechanic_type: String) -> Color:
	return CATEGORY_COLORS.get(category_for_type(mechanic_type), Color(1, 1, 1))


static func region_color(kind: String) -> Color:
	return REGION_COLORS.get(kind, Color(1, 1, 1))


static func slot_position(slot: Dictionary) -> Vector2:
	var position: Variant = slot.get("position", [])
	if position is Array and (position as Array).size() >= 2:
		return Vector2(float((position as Array)[0]), float((position as Array)[1]))
	return Vector2.ZERO


static func slot_size(slot: Dictionary) -> Vector2:
	var size: Variant = slot.get("size", [])
	if size is Array and (size as Array).size() >= 2:
		return Vector2(float((size as Array)[0]), float((size as Array)[1]))
	return Vector2.ZERO


static func default_parent_path_for_type(mechanic_type: String) -> String:
	if mechanic_type in SECURITY_PARENT_TYPES:
		return "GameplayRoot/SecurityAuthoringRoot"
	if mechanic_type == "PlayerStartMarker":
		return "GameplayRoot/MarkerRoot/Spawns"
	return "MissionMechanics"


## Diffs blueprint mechanic slots against mechanics already placed in the scene.
## A slot counts as placed when a node carries its suggested_id in a known id
## property AND that node's script file name matches "<mechanic_type>.gd".
static func coverage(spec: Dictionary, scene_root: Node) -> Dictionary:
	var slots := mechanic_slots(spec)
	var placed: Array[String] = []
	var missing: Array[String] = []
	var mismatched: Array[String] = []
	var id_index: Dictionary = {}
	if scene_root != null:
		_collect_id_index(scene_root, id_index)
	for entry: Variant in slots:
		if not (entry is Dictionary):
			continue
		var slot := entry as Dictionary
		var slot_id := String(slot.get("slot_id", ""))
		var suggested_id := String(slot.get("suggested_id", "")).strip_edges()
		var mechanic_type := String(slot.get("mechanic_type", ""))
		if suggested_id == "" or not id_index.has(suggested_id):
			missing.append(slot_id)
			continue
		var script_file_names: Array = id_index.get(suggested_id, [])
		if script_file_names.has("%s.gd" % mechanic_type):
			placed.append(slot_id)
		else:
			mismatched.append(slot_id)
	return {
		"total": slots.size(),
		"placed": placed,
		"missing": missing,
		"mismatched": mismatched,
	}


static func find_slot(spec: Dictionary, slot_id: String) -> Dictionary:
	for entry: Variant in mechanic_slots(spec):
		if entry is Dictionary and String((entry as Dictionary).get("slot_id", "")) == slot_id:
			return entry as Dictionary
	return {}


static func _collect_id_index(node: Node, id_index: Dictionary) -> void:
	var script: Variant = node.get_script()
	if script is Script:
		var script_file := String((script as Script).resource_path).get_file()
		for property: String in ID_PROPERTIES:
			if property in node:
				var id_text := String(node.get(property)).strip_edges()
				if id_text != "":
					if not id_index.has(id_text):
						id_index[id_text] = []
					var bucket: Array = id_index[id_text]
					if not bucket.has(script_file):
						bucket.append(script_file)
	for child: Node in node.get_children():
		_collect_id_index(child, id_index)


static func _validate_spec(spec: Dictionary, errors: Array[String]) -> void:
	if String(spec.get("blueprint_id", "")).strip_edges() == "":
		errors.append("blueprint_id is required.")
	var canvas := canvas_size(spec)
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		errors.append("canvas.width and canvas.height must be positive numbers.")
	if grid_size(spec) <= 0.0:
		errors.append("grid_size must be a positive number.")
	var region_index := 0
	for entry: Variant in regions(spec):
		if not (entry is Dictionary):
			errors.append("regions[%d] must be an object." % region_index)
			region_index += 1
			continue
		var region := entry as Dictionary
		var kind := String(region.get("kind", ""))
		if kind not in REGION_KINDS:
			errors.append("regions[%d] has unknown kind '%s'." % [region_index, kind])
		var shape := String(region.get("shape", ""))
		match shape:
			"rect":
				var rect: Variant = region.get("rect", [])
				if not (rect is Array) or (rect as Array).size() != 4:
					errors.append("regions[%d] rect shape needs rect: [x, y, w, h]." % region_index)
			"polyline":
				var points: Variant = region.get("points", [])
				if not (points is Array) or (points as Array).size() < 2:
					errors.append("regions[%d] polyline shape needs points: [[x, y], ...] with 2+ entries." % region_index)
			"circle":
				var center: Variant = region.get("center", [])
				if not (center is Array) or (center as Array).size() != 2 or float(region.get("radius", 0.0)) <= 0.0:
					errors.append("regions[%d] circle shape needs center: [x, y] and positive radius." % region_index)
			_:
				errors.append("regions[%d] has unknown shape '%s' (expected rect, polyline, or circle)." % [region_index, shape])
		region_index += 1
	var slot_ids: Dictionary = {}
	var suggested_ids: Dictionary = {}
	var slot_index := 0
	for entry: Variant in mechanic_slots(spec):
		if not (entry is Dictionary):
			errors.append("mechanic_slots[%d] must be an object." % slot_index)
			slot_index += 1
			continue
		var slot := entry as Dictionary
		var slot_id := String(slot.get("slot_id", "")).strip_edges()
		if slot_id == "":
			errors.append("mechanic_slots[%d] is missing slot_id." % slot_index)
		elif slot_ids.has(slot_id):
			errors.append("Duplicate slot_id '%s'." % slot_id)
		else:
			slot_ids[slot_id] = true
		var mechanic_type := String(slot.get("mechanic_type", ""))
		if not CATEGORY_BY_TYPE.has(mechanic_type):
			errors.append("mechanic_slots[%d] ('%s') has unknown mechanic_type '%s'." % [slot_index, slot_id, mechanic_type])
		var position: Variant = slot.get("position", [])
		if not (position is Array) or (position as Array).size() != 2:
			errors.append("mechanic_slots[%d] ('%s') needs position: [x, y]." % [slot_index, slot_id])
		var suggested_id := String(slot.get("suggested_id", "")).strip_edges()
		if suggested_id == "":
			errors.append("mechanic_slots[%d] ('%s') is missing suggested_id." % [slot_index, slot_id])
		elif suggested_ids.has(suggested_id):
			errors.append("Duplicate suggested_id '%s'." % suggested_id)
		else:
			suggested_ids[suggested_id] = true
		slot_index += 1
	for entry: Variant in mechanic_slots(spec):
		if not (entry is Dictionary):
			continue
		var slot := entry as Dictionary
		var depends: Variant = slot.get("depends_on", [])
		if not (depends is Array):
			errors.append("Slot '%s' depends_on must be an array of slot_ids." % String(slot.get("slot_id", "")))
			continue
		for dependency: Variant in (depends as Array):
			if not slot_ids.has(String(dependency)):
				errors.append("Slot '%s' depends_on unknown slot_id '%s'." % [String(slot.get("slot_id", "")), String(dependency)])
