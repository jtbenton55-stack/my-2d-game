extends Node2D
class_name HideoutPVGamesVisualHelper

const ASSET_ROOT := "res://assets/tilesets/cyber_city_core_tilesets"
const CORE_1 := ASSET_ROOT + "/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1"
const CORE_2 := ASSET_ROOT + "/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2"

const GROUP_NAME := "hideout_pvgames_visual_only"
const CONTAINER_NAMES := [
	"PVGamesFloorDressing",
	"PVGamesWallDressing",
	"PVGamesPropDressing",
	"PVGamesCollectibleDressing",
	"PVGamesForegroundDressing",
	"PVGamesLightingDressing",
]

@export var enabled := false

func _ready() -> void:
	if enabled:
		call_deferred("apply_visual_dressing")

func apply_visual_dressing() -> void:
	var world := _world()
	if world == null:
		return
	_ensure_layer(world, "LightingLayer", 200)
	_tone_down_runtime_graybox(world)
	var containers := {
		"floor": _reset_container(_layer(world, "FloorLayer"), "PVGamesFloorDressing"),
		"wall": _reset_container(_layer(world, "WallLayer"), "PVGamesWallDressing"),
		"prop": _reset_container(_layer(world, "PropLayer"), "PVGamesPropDressing"),
		"collectible": _reset_container(_layer(world, "CollectibleLayer"), "PVGamesCollectibleDressing"),
		"foreground": _reset_container(_layer(world, "ForegroundLayer"), "PVGamesForegroundDressing"),
		"lighting": _reset_container(_layer(world, "LightingLayer"), "PVGamesLightingDressing"),
	}
	_add_floor_tint(containers["floor"])
	for spec in _sprite_specs():
		var layer_key := String(spec.get("layer", "prop"))
		var parent := containers.get(layer_key, containers["prop"]) as Node2D
		_add_sprite(parent, spec)
	for glow in _glow_specs():
		_add_glow(containers["lighting"], glow)
	for label in _label_specs():
		_add_label(containers["lighting"], label)

func _world() -> Node2D:
	var node: Node = self
	while node != null:
		if node.name == "World" and node is Node2D:
			return node as Node2D
		node = node.get_parent()
	return null

func _layer(world: Node2D, layer_name: String) -> Node2D:
	return world.get_node_or_null(layer_name) as Node2D

func _ensure_layer(world: Node2D, layer_name: String, layer_z_index: int) -> Node2D:
	var layer := _layer(world, layer_name)
	if layer == null:
		layer = Node2D.new()
		layer.name = layer_name
		world.add_child(layer)
	layer.z_index = layer_z_index
	return layer

func _reset_container(layer: Node2D, container_name: String) -> Node2D:
	if layer == null:
		return null
	var existing := layer.get_node_or_null(container_name)
	if existing != null:
		existing.name = "%s_Removing" % container_name
		existing.queue_free()
	var container := Node2D.new()
	container.name = container_name
	container.add_to_group(GROUP_NAME)
	container.set_meta("pvgames_visual_only", true)
	layer.add_child(container)
	return container

func _tone_down_runtime_graybox(world: Node2D) -> void:
	var base_floor := world.get_node_or_null("FloorLayer/IrregularGarageGreenhouseFloor") as Polygon2D
	if base_floor != null:
		base_floor.color = Color(0.055, 0.06, 0.075, 1.0)
	var guide := world.get_node_or_null("FloorLayer/DashedCirculationPath") as Line2D
	if guide != null:
		guide.default_color = Color(0.2, 0.9, 1.0, 0.14)
		guide.width = 2.0
	var prop_layer := _layer(world, "PropLayer")
	if prop_layer == null:
		return
	for child in prop_layer.get_children():
		var box := child.get_node_or_null("ReplaceableGrayboxProp") as Polygon2D
		if box != null:
			box.visible = false
		for grandchild in child.get_children():
			if grandchild is Label and String(grandchild.name).begins_with("Label_"):
				(grandchild as Label).modulate = Color(1, 1, 1, 0.42)
	var decoration_layer := _layer(world, "DecorationLayer")
	if decoration_layer == null:
		return
	for child in decoration_layer.get_children():
		if child.name == "PlacedDecor":
			continue
		var decor_box := child.get_node_or_null("ReplaceableGraybox") as Polygon2D
		if decor_box != null:
			decor_box.color.a = 0.12
		for grandchild in child.get_children():
			if grandchild is Label and String(grandchild.name).begins_with("Label_"):
				(grandchild as Label).modulate = Color(1, 1, 1, 0.35)

func _add_floor_tint(parent: Node2D) -> void:
	if parent == null:
		return
	var zones := [
		{"name": "GarageFloorWash", "position": Vector2(0, 20), "size": Vector2(1660, 880), "color": Color(0.035, 0.055, 0.075, 0.72)},
		{"name": "GreenhouseSoftFloor", "position": Vector2(0, -575), "size": Vector2(760, 120), "color": Color(0.08, 0.22, 0.18, 0.42)},
		{"name": "CozyLoungeWarmth", "position": Vector2(-670, 350), "size": Vector2(470, 250), "color": Color(0.24, 0.13, 0.09, 0.36)},
		{"name": "OpenDecorBreathingRoom", "position": Vector2(470, 145), "size": Vector2(430, 330), "color": Color(0.02, 0.14, 0.15, 0.23)},
	]
	for zone in zones:
		var half: Vector2 = zone["size"] * 0.5
		var poly := Polygon2D.new()
		poly.name = String(zone["name"])
		poly.position = zone["position"]
		poly.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		poly.color = zone["color"]
		poly.z_index = -30
		poly.add_to_group(GROUP_NAME)
		poly.set_meta("pvgames_visual_only", true)
		parent.add_child(poly)

func _add_sprite(parent: Node2D, spec: Dictionary) -> void:
	if parent == null:
		return
	var path := String(spec.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		push_warning("[HideoutPVGamesVisualHelper] Missing PVGames asset: %s" % path)
		return
	var sprite := Sprite2D.new()
	sprite.name = String(spec.get("name", "PVGamesSprite"))
	sprite.texture = load(path)
	sprite.position = spec.get("position", Vector2.ZERO)
	sprite.scale = spec.get("scale", Vector2.ONE)
	sprite.rotation_degrees = float(spec.get("rotation", 0.0))
	sprite.z_index = int(spec.get("z_index", 0))
	sprite.modulate = spec.get("modulate", Color.WHITE)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.add_to_group(GROUP_NAME)
	sprite.set_meta("pvgames_visual_only", true)
	sprite.set_meta("asset_path", path)
	sprite.set_meta("area", String(spec.get("area", "")))
	parent.add_child(sprite)

func _add_glow(parent: Node2D, spec: Dictionary) -> void:
	if parent == null:
		return
	var half: Vector2 = spec.get("size", Vector2(120, 40)) * 0.5
	var poly := Polygon2D.new()
	poly.name = String(spec.get("name", "PVGamesGlow"))
	poly.position = spec.get("position", Vector2.ZERO)
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	poly.color = spec.get("color", Color(0.2, 0.9, 1.0, 0.18))
	poly.z_index = int(spec.get("z_index", 0))
	poly.add_to_group(GROUP_NAME)
	poly.set_meta("pvgames_visual_only", true)
	parent.add_child(poly)

func _add_label(parent: Node2D, spec: Dictionary) -> void:
	if parent == null:
		return
	var label := Label.new()
	label.name = String(spec.get("name", "PVGamesZoneLabel"))
	label.position = spec.get("position", Vector2.ZERO)
	label.text = String(spec.get("text", ""))
	label.z_index = int(spec.get("z_index", 0))
	label.modulate = spec.get("modulate", Color(0.75, 1.0, 1.0, 0.88))
	label.add_theme_color_override("font_color", spec.get("font_color", Color(0.8, 1.0, 1.0, 1.0)))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", int(spec.get("font_size", 18)))
	label.add_to_group(GROUP_NAME)
	label.set_meta("pvgames_visual_only", true)
	parent.add_child(label)

func _sprite_specs() -> Array[Dictionary]:
	return [
		# Floor and zone-defining mats.
		_s("Floor_GreenhouseDiamond_A", CORE_2 + "/FloorMat1_2.png", "floor", Vector2(-140, -590), Vector2(2.6, 2.2), -6, "greenhouse"),
		_s("Floor_GreenhouseDiamond_B", CORE_2 + "/FloorMat1_4.png", "floor", Vector2(130, -590), Vector2(2.6, 2.2), -6, "greenhouse"),
		_s("Floor_PlanningMat_A", CORE_2 + "/FloorMat1_5.png", "floor", Vector2(-80, 70), Vector2(3.2, 2.8), -5, "planning"),
		_s("Floor_PlanningMat_B", CORE_2 + "/FloorMat1_6.png", "floor", Vector2(92, 70), Vector2(3.1, 2.7), -5, "planning"),
		_s("Floor_CozyMat_A", CORE_2 + "/FloorMat1_1.png", "floor", Vector2(-735, 370), Vector2(3.4, 2.7), -5, "cozy_lounge"),
		_s("Floor_CozyMat_B", CORE_2 + "/FloorMat1_3.png", "floor", Vector2(-600, 355), Vector2(3.2, 2.6), -5, "cozy_lounge"),
		_s("Floor_OpenDecorMarker_A", CORE_2 + "/FloorMat1_2.png", "floor", Vector2(390, 115), Vector2(1.6, 1.35), -4, "open_decor"),
		_s("Floor_OpenDecorMarker_B", CORE_2 + "/FloorMat1_4.png", "floor", Vector2(590, 250), Vector2(1.55, 1.3), -4, "open_decor"),
		_s("Floor_LootDeliveryPad", CORE_2 + "/FloorMat1_8.png", "floor", Vector2(210, 350), Vector2(2.0, 1.7), -4, "loot_crate"),
		_s("Floor_EntryWarningStripe", CORE_2 + "/FloorMat1_7.png", "floor", Vector2(755, 420), Vector2(2.1, 1.5), -4, "entry"),

		# Structure, garage edges, and greenhouse backdrop.
		_s("Wall_NorthGlassPanel_A", CORE_2 + "/CityWalls1_2.png", "wall", Vector2(-280, -610), Vector2(1.35, 1.1), -8, "greenhouse"),
		_s("Wall_NorthGlassPanel_B", CORE_2 + "/CityWalls1_4.png", "wall", Vector2(20, -612), Vector2(1.35, 1.1), -8, "greenhouse"),
		_s("Wall_NorthGlassPanel_C", CORE_2 + "/CityWalls1_6.png", "wall", Vector2(320, -610), Vector2(1.35, 1.1), -8, "greenhouse"),
		_s("Wall_WestDisplayBacker_A", CORE_2 + "/CityWalls1_1.png", "wall", Vector2(-875, -210), Vector2(1.0, 1.15), -7, "collectibles"),
		_s("Wall_WestDisplayBacker_B", CORE_2 + "/CityWalls1_3.png", "wall", Vector2(-885, 40), Vector2(1.0, 1.15), -7, "collectibles"),
		_s("Wall_BigCaseBacker", CORE_2 + "/CityWalls1_8.png", "wall", Vector2(-90, -470), Vector2(1.2, 1.05), -7, "big_case"),
		_s("Wall_MissionBacker", CORE_2 + "/CityWalls1_7.png", "wall", Vector2(470, -470), Vector2(1.15, 1.05), -7, "mission_board"),
		_s("Entry_CyberDoor", CORE_2 + "/Door10_4.png", "wall", Vector2(785, 420), Vector2(1.2, 1.2), -4, "entry"),

		# Planning and board focal points.
		_s("Planning_MainTable", CORE_2 + "/Table2_2.png", "prop", Vector2(0, 25), Vector2(1.45, 1.45), 2, "planning"),
		_s("Planning_LeftChair", CORE_2 + "/Chair10_1.png", "prop", Vector2(-155, 70), Vector2(1.05, 1.05), 3, "planning"),
		_s("Planning_RightChair", CORE_2 + "/Chair10_5.png", "prop", Vector2(150, 74), Vector2(1.05, 1.05), 3, "planning"),
		_s("Planning_Monitor", CORE_2 + "/ComputerMonitor1_1.png", "prop", Vector2(15, -30), Vector2(1.1, 1.1), 4, "planning"),
		_s("MissionBoard_ScreenBank", CORE_2 + "/ComputerScreen1_4.png", "prop", Vector2(470, -452), Vector2(1.9, 1.55), 4, "mission_board"),
		_s("MissionBoard_NeonHeader", CORE_2 + "/BuildingLargeSign10_2.png", "prop", Vector2(470, -535), Vector2(1.0, 0.9), 5, "mission_board"),
		_s("BigCase_MysteryScreen", CORE_2 + "/ComputerScreen1_7.png", "prop", Vector2(-90, -455), Vector2(1.8, 1.45), 4, "big_case"),
		_s("BigCase_EvidenceLight", CORE_2 + "/BuildingLights1_3.png", "prop", Vector2(-90, -525), Vector2(1.1, 0.9), 5, "big_case"),

		# Entry, Bentley care, loot, and store.
		_s("Care_UtilityCabinet", CORE_2 + "/KitchenCabinet1_2.png", "prop", Vector2(520, 325), Vector2(1.05, 1.05), 2, "bentley_care"),
		_s("Care_TreatBox", CORE_2 + "/CardboardBox1_3.png", "prop", Vector2(575, 375), Vector2(0.85, 0.85), 3, "bentley_care"),
		_s("Care_CleaningCrate", CORE_2 + "/Crate1_2.png", "prop", Vector2(475, 375), Vector2(0.85, 0.85), 3, "bentley_care"),
		_s("Loot_MainCrate", CORE_2 + "/Crate1_4.png", "prop", Vector2(210, 350), Vector2(1.25, 1.25), 3, "loot_crate"),
		_s("Loot_DeliveryBox_A", CORE_2 + "/CardboardBox1_1.png", "prop", Vector2(150, 385), Vector2(0.9, 0.9), 3, "loot_crate"),
		_s("Loot_DeliveryBox_B", CORE_2 + "/CardboardBox1_5.png", "prop", Vector2(260, 390), Vector2(0.9, 0.9), 3, "loot_crate"),
		_s("Store_Terminal", CORE_2 + "/Terminal1_2.png", "prop", Vector2(710, -80), Vector2(1.3, 1.3), 4, "store"),
		_s("Store_CounterCabinet", CORE_2 + "/KitchenCabinet1_5.png", "prop", Vector2(745, 5), Vector2(1.1, 1.1), 3, "store"),
		_s("Store_Sign", CORE_2 + "/BuildingLargeSign12_2.png", "prop", Vector2(705, -180), Vector2(0.9, 0.9), 5, "store"),

		# Cozy lounge and characters.
		_s("Cozy_BentleyBed", CORE_1 + "/Bed1_4.png", "prop", Vector2(-800, 390), Vector2(1.15, 1.15), 2, "cozy_lounge"),
		_s("Cozy_Couch", CORE_2 + "/Couch1_2.png", "prop", Vector2(-625, 330), Vector2(1.2, 1.2), 2, "cozy_lounge"),
		_s("Cozy_SideChairJake", CORE_2 + "/Chair10_3.png", "prop", Vector2(-535, 250), Vector2(0.9, 0.9), 3, "jake"),
		_s("Cozy_SideChairMere", CORE_2 + "/Chair10_7.png", "prop", Vector2(-455, 250), Vector2(0.9, 0.9), 3, "mere"),
		_s("Cozy_BarrelTable", CORE_1 + "/Barrel1_2.png", "prop", Vector2(-710, 280), Vector2(0.8, 0.8), 3, "cozy_lounge"),

		# West-side collectible displays.
		_s("Polaroid_DisplayShelf", CORE_2 + "/ConvenienceStoreShelf1_2.png", "collectible", Vector2(-850, -230), Vector2(1.0, 1.0), 3, "polaroid_wall"),
		_s("GlowGuy_DisplayShelf", CORE_2 + "/ConvenienceStoreShelf1_4.png", "collectible", Vector2(-880, -40), Vector2(1.0, 1.0), 3, "glow_guy_shelf"),
		_s("TinyIcon_DisplayShelf", CORE_2 + "/ConvenienceStoreShelf1_6.png", "collectible", Vector2(-880, 110), Vector2(1.0, 1.0), 3, "tiny_icon_shelf"),
		_s("PoopBag_UtilityShelf", CORE_2 + "/KitchenCabinet1_7.png", "collectible", Vector2(-840, 250), Vector2(0.95, 0.95), 3, "poop_bag_display"),
		_s("West_NoirBillboard", CORE_1 + "/Billboard10_5.png", "collectible", Vector2(-780, -305), Vector2(0.85, 0.85), 4, "collectibles"),

		# Greenhouse, heat scanner, and atmosphere props.
		_s("Greenhouse_Plant_A", CORE_2 + "/Plant1_1.png", "prop", Vector2(-270, -555), Vector2(1.05, 1.05), 3, "greenhouse"),
		_s("Greenhouse_Plant_B", CORE_2 + "/Plant1_5.png", "prop", Vector2(260, -555), Vector2(1.05, 1.05), 3, "greenhouse"),
		_s("Greenhouse_Plant_C", CORE_2 + "/Plant2_3.png", "prop", Vector2(30, -565), Vector2(0.95, 0.95), 3, "greenhouse"),
		_s("HeatScanner_Machine", CORE_2 + "/Computer1_6.png", "prop", Vector2(0, -310), Vector2(1.1, 1.1), 3, "heat_scanner"),
		_s("HeatScanner_WarningScreen", CORE_2 + "/ComputerScreen1_2.png", "prop", Vector2(45, -360), Vector2(0.9, 0.9), 4, "heat_scanner"),
		_s("Foreground_RooftopAC_A", CORE_1 + "/ACUnit1_2.png", "foreground", Vector2(-940, 420), Vector2(0.75, 0.75), 1, "foreground"),
		_s("Foreground_RooftopAC_B", CORE_1 + "/ACUnit2_6.png", "foreground", Vector2(860, 380), Vector2(0.75, 0.75), 1, "foreground"),
	]

func _s(sprite_name: String, path: String, layer: String, sprite_position: Vector2, sprite_scale: Vector2, sprite_z_index: int, area: String) -> Dictionary:
	return {
		"name": sprite_name,
		"path": path,
		"layer": layer,
		"position": sprite_position,
		"scale": sprite_scale,
		"z_index": sprite_z_index,
		"area": area,
	}

func _glow_specs() -> Array[Dictionary]:
	return [
		{"name": "Glow_MissionBoard", "position": Vector2(470, -452), "size": Vector2(270, 130), "color": Color(0.15, 0.9, 1.0, 0.14), "z_index": 0},
		{"name": "Glow_BigCase", "position": Vector2(-90, -455), "size": Vector2(300, 145), "color": Color(0.95, 0.55, 0.1, 0.13), "z_index": 0},
		{"name": "Glow_Store", "position": Vector2(710, -70), "size": Vector2(240, 190), "color": Color(0.9, 0.15, 1.0, 0.13), "z_index": 0},
		{"name": "Glow_Greenhouse", "position": Vector2(0, -590), "size": Vector2(780, 130), "color": Color(0.15, 1.0, 0.55, 0.10), "z_index": 0},
		{"name": "Glow_CozyLounge", "position": Vector2(-675, 350), "size": Vector2(430, 230), "color": Color(1.0, 0.55, 0.18, 0.10), "z_index": 0},
		{"name": "Glow_EntryCare", "position": Vector2(615, 365), "size": Vector2(330, 170), "color": Color(0.1, 0.85, 1.0, 0.10), "z_index": 0},
	]

func _label_specs() -> Array[Dictionary]:
	return [
		{"name": "Label_MissionBoardNeon", "position": Vector2(395, -545), "text": "NEXT JOB", "font_color": Color(0.35, 1.0, 1.0, 1.0), "font_size": 18, "z_index": 3},
		{"name": "Label_BigCaseNeon", "position": Vector2(-162, -540), "text": "THE BIG CASE", "font_color": Color(1.0, 0.78, 0.28, 1.0), "font_size": 18, "z_index": 3},
		{"name": "Label_StoreNeon", "position": Vector2(650, -205), "text": "AFTER-HOURS STORE", "font_color": Color(1.0, 0.35, 1.0, 1.0), "font_size": 16, "z_index": 3},
		{"name": "Label_OpenDecor", "position": Vector2(344, -65), "text": "OPEN DECOR FLOOR", "font_color": Color(0.6, 1.0, 0.95, 0.8), "font_size": 14, "z_index": 2},
		{"name": "Label_BentleyCare", "position": Vector2(455, 255), "text": "BENTLEY CARE", "font_color": Color(0.8, 1.0, 0.75, 0.92), "font_size": 16, "z_index": 3},
	]
