extends RefCounted

## Spawns authored collectibles as Phase0J-style interactables (E to collect).

const INTERACTABLE_SCRIPT := preload("res://src/missions/iso/runtime/AuthoredPhase0JInteractablePickup.gd")
const RUNTIME_PARENT_NAME := "AuthoredGeneratedInteractables"
const DEFAULT_PICKUP_RADIUS := 40.0

const CATEGORY_TO_VISUAL := {
	"poop_bag": "bag",
	"polaroid": "photo",
	"tiny_icon": "tiny",
	"glow_guy": "glow",
	"money": "item",
	"case_cash": "item",
	"evidence_clue": "clue",
}


static func setup(mission: Node, authoring_root: Node2D) -> int:
	if mission == null or authoring_root == null:
		return 0
	if not authoring_root.has_method("collect_collectible_authors"):
		return 0
	var authors: Array = authoring_root.call("collect_collectible_authors")
	var parent := _ensure_runtime_parent(mission)
	_clear_runtime_children(parent)
	var spawned := 0
	var poop_n := 0
	var money_n := 0
	var polaroid_n := 0
	var tiny_n := 0
	var glow_n := 0
	var clue_n := 0
	var case_cash_n := 0
	var seen_ids: Dictionary = {}
	var duplicate_ids: Array[String] = []
	for author in authors:
		if author == null or not (author is Node2D):
			continue
		if author.get("enabled") != null and not bool(author.get("enabled")):
			continue
		if not author.has_method("build_runtime_config"):
			continue
		var cfg_v: Variant = author.call("build_runtime_config")
		if not (cfg_v is Dictionary):
			continue
		var cfg: Dictionary = cfg_v as Dictionary
		var collectible_id := String(cfg.get("collectible_id", "")).strip_edges()
		if collectible_id == "":
			continue
		if not bool(cfg.get("enabled", true)):
			continue
		if seen_ids.has(collectible_id):
			duplicate_ids.append(collectible_id)
			continue
		seen_ids[collectible_id] = true
		cfg["global_position"] = (author as Node2D).global_position
		if cfg.get("pickup_radius", null) == null:
			cfg["pickup_radius"] = DEFAULT_PICKUP_RADIUS
		if _spawn_interactable(mission, parent, cfg):
			spawned += 1
			match String(cfg.get("collectible_type", "")):
				"poop_bag":
					poop_n += 1
				"money":
					money_n += 1
				"case_cash":
					case_cash_n += 1
				"polaroid":
					polaroid_n += 1
				"tiny_icon":
					tiny_n += 1
				"glow_guy":
					glow_n += 1
				"evidence_clue", "clue":
					clue_n += 1
	_store_counts(mission, authoring_root, spawned, poop_n, money_n, polaroid_n, tiny_n, glow_n, clue_n, case_cash_n, duplicate_ids)
	if mission.has_method("store_d6_06_runtime_path"):
		mission.call("store_d6_06_runtime_path", "phase0j_interactable", str(parent.get_path()))
	return spawned


static func _ensure_runtime_parent(mission: Node) -> Node2D:
	var gri := mission.get_node_or_null("GameplayRoot/GeneratedRuntimeInteractables") as Node2D
	if gri == null:
		gri = mission.get_node_or_null("GameplayRoot/RuntimeSystems/GeneratedRuntimeInteractables") as Node2D
	if gri == null:
		var systems := mission.get_node_or_null("GameplayRoot/RuntimeSystems")
		if systems == null:
			systems = mission
		gri = Node2D.new()
		gri.name = "GeneratedRuntimeInteractables"
		systems.add_child(gri)
	var parent := gri.get_node_or_null(RUNTIME_PARENT_NAME) as Node2D
	if parent == null:
		parent = Node2D.new()
		parent.name = RUNTIME_PARENT_NAME
		parent.set_meta("generated_by", "D6-06-Authored")
		gri.add_child(parent)
	return parent


static func _clear_runtime_children(parent: Node) -> void:
	for child in parent.get_children():
		if child is Node:
			(child as Node).queue_free()


static func _spawn_interactable(mission: Node, parent: Node2D, config: Dictionary) -> bool:
	var collectible_id := String(config.get("collectible_id", "")).strip_edges()
	var collectible_type := String(config.get("collectible_type", "")).strip_edges()
	var category := _phase0j_category(collectible_type)
	var pickup := Area2D.new()
	pickup.name = "AuthoredInteractable_%s" % collectible_id
	pickup.set_script(INTERACTABLE_SCRIPT)
	var radius := maxf(float(config.get("pickup_radius", DEFAULT_PICKUP_RADIUS)), 16.0)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	pickup.add_child(shape)
	var half := radius * 0.45
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.offset_left = -half
	visual.offset_top = -half
	visual.offset_right = half
	visual.offset_bottom = half
	var color_v: Variant = config.get("preview_color", Color(0.8, 0.8, 0.8, 0.85))
	if color_v is Color:
		visual.color = color_v as Color
	pickup.add_child(visual)
	var label := Label.new()
	label.name = "Label"
	label.offset_left = -14.0
	label.offset_top = -26.0
	label.offset_right = 14.0
	label.offset_bottom = -10.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var display_name := String(config.get("display_name", collectible_id.capitalize()))
	label.text = display_name.substr(0, 1).to_upper()
	pickup.add_child(label)
	parent.add_child(pickup)
	var pos_v: Variant = config.get("global_position", Vector2.ZERO)
	if pos_v is Vector2:
		pickup.global_position = pos_v as Vector2
	pickup.set("candidate_id", collectible_id)
	pickup.set("category", category)
	pickup.set("prompt_text", "Press E: " + display_name)
	pickup.set("one_shot", bool(config.get("one_shot", true)))
	pickup.set("visual_type", CATEGORY_TO_VISUAL.get(collectible_type, "item"))
	pickup.set("interaction_priority", 620)
	pickup.set("debug_enabled", true)
	pickup.set_meta("generated_by", "D6-06-Authored")
	pickup.set_meta("source", "collectible_authoring")
	pickup.set_meta("collectible_type", collectible_type)
	pickup.set_meta("hideout_collection_key", String(config.get("hideout_collection_key", "")))
	if collectible_type in ["money", "case_cash"]:
		pickup.set_meta("money_amount", int(config.get("amount", 1)))
		pickup.set_meta("currency_type", String(config.get("currency_type", "cash")))
		pickup.set_meta("commits_as_case_cash", bool(config.get("commits_as_case_cash", collectible_type == "case_cash")))
	if collectible_type == "evidence_clue" or collectible_type == "clue":
		pickup.set_meta("clue_id", String(config.get("clue_id", collectible_id)))
		pickup.set_meta("clue_title", String(config.get("clue_title", display_name)))
		pickup.set_meta("clue_text", String(config.get("clue_text", "")))
		pickup.set_meta("case_id", String(config.get("case_id", "")))
	if collectible_type == "glow_guy":
		var gid := String(config.get("glow_guy_id", collectible_id)).strip_edges()
		pickup.set_meta("glow_guy_id", gid)
		if gid != "":
			pickup.set("candidate_id", gid)
	if collectible_type == "poop_bag":
		pickup.set_meta("poop_count", int(config.get("poop_count", 1)))
	if collectible_type == "polaroid":
		var pid := String(config.get("polaroid_id", collectible_id)).strip_edges()
		pickup.set_meta("polaroid_id", pid)
		pickup.set("candidate_id", pid)
	if collectible_type == "tiny_icon":
		var iid := String(config.get("icon_id", collectible_id)).strip_edges()
		pickup.set_meta("icon_id", iid)
		pickup.set("candidate_id", iid)
	if mission != null and mission.has_method("_on_authored_collectible_collected_signal"):
		var cb := Callable(mission, "_on_authored_collectible_collected_signal")
		if pickup.has_signal("collected_signal") and not pickup.collected_signal.is_connected(cb):
			pickup.collected_signal.connect(cb)
	return true


static func _phase0j_category(collectible_type: String) -> String:
	match collectible_type.strip_edges().to_lower():
		"poop_bag":
			return "poop_bag"
		"polaroid":
			return "polaroid"
		"tiny_icon":
			return "tiny_icon"
		"glow_guy":
			return "glow_guy"
		"money":
			return "money"
		"case_cash":
			return "case_cash"
		"evidence_clue", "clue":
			return "evidence_clue"
		_:
			return collectible_type


static func _store_counts(
	mission: Node,
	authoring_root: Node2D,
	spawned: int,
	poop_n: int,
	money_n: int,
	polaroid_n: int,
	tiny_n: int,
	glow_n: int = 0,
	clue_n: int = 0,
	case_cash_n: int = 0,
	duplicate_ids: Array[String] = []
) -> void:
	if mission == null or not mission.has_method("store_d6_06_collectible_author_counts"):
		return
	var author_count := 0
	if authoring_root.has_method("collect_collectible_authors"):
		author_count = authoring_root.call("collect_collectible_authors").size()
	mission.call(
		"store_d6_06_collectible_author_counts",
		author_count,
		spawned,
		poop_n,
		money_n,
		polaroid_n,
		tiny_n,
		authoring_root != null,
		glow_n,
		clue_n,
		case_cash_n,
		duplicate_ids
	)
