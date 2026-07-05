extends Node

const BLOCKOUT_TILESET := preload("res://assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres")
const MARKER_TILESET := preload("res://assets/tilesets/marker_authoring/MarkerAuthoringTileset.tres")
const PV_FLOOR_TILESET := preload("res://assets/tilesets/pvgames_paintable/PVGamesFloorPaintVisualTileset.tres")
const PV_WALL_TILESET := preload("res://assets/tilesets/pvgames_paintable/PVGamesWallPaintVisualTileset.tres")
const PV_CATALOG_FLOOR_TILESET := preload("res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres")
const PV_CATALOG_WALL_TILESET := preload("res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres")
const PV_SECURITY_WALL_TILESET := preload("res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityWallPaint.tres")

const SOURCE_ID := 0
const TILE_FLOOR := Vector2i(0, 0)
const TILE_WALL := Vector2i(1, 0)
const TILE_COVER := Vector2i(2, 0)
const TILE_MARKER := Vector2i(3, 0)

const PV_FLOOR_STOREFRONT := Vector2i(0, 0)
const PV_FLOOR_AISLE := Vector2i(1, 0)
const PV_FLOOR_BACK_OFFICE := Vector2i(2, 0)
const PV_WALL_PERIMETER := Vector2i(0, 0)
const PV_WALL_SECURITY := Vector2i(1, 0)

@export var paint_on_ready: bool = true
@export var paint_art_pass: bool = true


func _ready() -> void:
	if Engine.is_editor_hint() or not paint_on_ready:
		return
	call_deferred("_paint_layout")


func _paint_layout() -> void:
	var root := get_parent()
	if root == null:
		return
	var layout := root.get_node_or_null("GameplayRoot/LayoutRoot")
	if layout == null:
		return
	var floor_layer := layout.get_node_or_null("FloorLayer") as TileMapLayer
	var wall_layer := layout.get_node_or_null("WallLayer") as TileMapLayer
	var cover_layer := layout.get_node_or_null("CoverLayer") as TileMapLayer
	var barrier_layer := layout.get_node_or_null("CollisionBarrierLayer") as TileMapLayer
	var marker_layer := layout.get_node_or_null("MarkerTileLayer") as TileMapLayer
	if floor_layer == null:
		return
	_assign_blockout_tilesets(floor_layer, wall_layer, cover_layer, barrier_layer, marker_layer)
	_paint_blockout(floor_layer, wall_layer, cover_layer, barrier_layer, marker_layer)
	if paint_art_pass:
		_paint_art_pass(root)


func _assign_blockout_tilesets(
	floor_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	cover_layer: TileMapLayer,
	barrier_layer: TileMapLayer,
	marker_layer: TileMapLayer
) -> void:
	if floor_layer != null and floor_layer.tile_set == null:
		floor_layer.tile_set = BLOCKOUT_TILESET
	if wall_layer != null and wall_layer.tile_set == null:
		wall_layer.tile_set = BLOCKOUT_TILESET
	if cover_layer != null and cover_layer.tile_set == null:
		cover_layer.tile_set = BLOCKOUT_TILESET
	if barrier_layer != null and barrier_layer.tile_set == null:
		barrier_layer.tile_set = BLOCKOUT_TILESET
	if marker_layer != null and marker_layer.tile_set == null:
		marker_layer.tile_set = MARKER_TILESET


func _paint_blockout(
	floor_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	cover_layer: TileMapLayer,
	barrier_layer: TileMapLayer,
	marker_layer: TileMapLayer
) -> void:
	for x in range(-8, 14):
		for y in range(-4, 6):
			floor_layer.set_cell(Vector2i(x, y), SOURCE_ID, TILE_FLOOR)
	for x in range(-8, 14):
		_set_wall(wall_layer, barrier_layer, Vector2i(x, -4))
		_set_wall(wall_layer, barrier_layer, Vector2i(x, 5))
	for y in range(-4, 6):
		_set_wall(wall_layer, barrier_layer, Vector2i(-8, y))
		_set_wall(wall_layer, barrier_layer, Vector2i(13, y))
	for y in range(-2, 4):
		_set_cover(cover_layer, Vector2i(-1, y))
	for y in range(-3, 3):
		if y != 0:
			_set_wall(wall_layer, barrier_layer, Vector2i(6, y))
	for x in range(8, 12):
		_set_cover(cover_layer, Vector2i(x, 1))
		_set_cover(cover_layer, Vector2i(x, 2))
	for x in range(1, 5):
		_set_cover(cover_layer, Vector2i(x, 0))
	if marker_layer != null:
		marker_layer.set_cell(Vector2i(-6, 0), SOURCE_ID, TILE_MARKER)
		marker_layer.set_cell(Vector2i(7, -1), SOURCE_ID, TILE_MARKER)
		marker_layer.set_cell(Vector2i(10, 3), SOURCE_ID, TILE_MARKER)
		marker_layer.set_cell(Vector2i(12, 0), SOURCE_ID, TILE_MARKER)


func _paint_art_pass(root: Node) -> void:
	var art_root := root.get_node_or_null("ArtRoot")
	if art_root == null:
		return
	var ground_art := art_root.get_node_or_null("GroundArtLayer") as TileMapLayer
	var wall_art := art_root.get_node_or_null("WallArtLayer") as TileMapLayer
	if ground_art == null:
		return
	if ground_art.tile_set == null:
		ground_art.tile_set = PV_CATALOG_FLOOR_TILESET if PV_CATALOG_FLOOR_TILESET != null else PV_FLOOR_TILESET
	if wall_art != null and wall_art.tile_set == null:
		wall_art.tile_set = PV_CATALOG_WALL_TILESET if PV_CATALOG_WALL_TILESET != null else PV_WALL_TILESET
	for x in range(-8, 14):
		for y in range(-4, 6):
			var cell := Vector2i(x, y)
			var atlas := PV_FLOOR_AISLE
			if x <= 0:
				atlas = PV_FLOOR_STOREFRONT
			elif x >= 7:
				atlas = PV_FLOOR_BACK_OFFICE
			ground_art.set_cell(cell, 2 if x >= 7 else 0, atlas)
	for x in range(-8, 14):
		_paint_art_wall(wall_art, Vector2i(x, -4), false)
		_paint_art_wall(wall_art, Vector2i(x, 5), false)
	for y in range(-4, 6):
		_paint_art_wall(wall_art, Vector2i(-8, y), false)
		_paint_art_wall(wall_art, Vector2i(13, y), false)
	for y in range(-3, 3):
		if y != 0:
			_paint_art_wall(wall_art, Vector2i(6, y), false)
	for x in range(8, 12):
		_paint_art_wall(wall_art, Vector2i(x, 1), true)
		_paint_art_wall(wall_art, Vector2i(x, 2), true)
	var security_wall := art_root.get_node_or_null("DecorAboveLayer") as TileMapLayer
	if security_wall != null and security_wall.tile_set == null and PV_SECURITY_WALL_TILESET != null:
		security_wall.tile_set = PV_SECURITY_WALL_TILESET
		for x in range(9, 11):
			security_wall.set_cell(Vector2i(x, 0), 0, Vector2i(0, 0))


func _paint_art_wall(wall_art: TileMapLayer, cell: Vector2i, security_nook: bool) -> void:
	if wall_art == null:
		return
	var source_id := 1 if security_nook and PV_SECURITY_WALL_TILESET != null else 0
	var atlas := PV_WALL_SECURITY if security_nook else PV_WALL_PERIMETER
	wall_art.set_cell(cell, source_id, atlas)


func _set_wall(wall_layer: TileMapLayer, barrier_layer: TileMapLayer, cell: Vector2i) -> void:
	if wall_layer != null:
		wall_layer.set_cell(cell, SOURCE_ID, TILE_WALL)
	if barrier_layer != null:
		barrier_layer.set_cell(cell, SOURCE_ID, TILE_WALL)


func _set_cover(cover_layer: TileMapLayer, cell: Vector2i) -> void:
	if cover_layer != null:
		cover_layer.set_cell(cell, SOURCE_ID, TILE_COVER)
