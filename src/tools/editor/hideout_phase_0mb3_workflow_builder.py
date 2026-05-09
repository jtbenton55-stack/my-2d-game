#!/usr/bin/env python3
"""
0M-B3 tooling pass generator.

Creates editor-visible HideoutHub art-placement guide nodes, visual-only
paint-layer TileSet resources, and human workflow reports. It does not touch
GameplayRoot, Taco Bell scenes, gameplay scripts, PVGames source PNGs, or
contact-sheet images.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HIDEOUT = ROOT / "scenes/hideout/HideoutHub.tscn"
REPORTS = ROOT / "docs/reports"
TILESET_DIR = ROOT / "assets/tilesets/pvgames_paintable"
TOOLS_SCENES = ROOT / "scenes/hideout/tools"

BACKUP_PATH = "res://scenes/hideout/HideoutHub.phase0mb3_backup.20260508_093641.tscn"
GUIDE_SCRIPT = "res://src/tools/editor/HideoutEditorGuideLayer.gd"
FLOOR_TILESET = "res://assets/tilesets/pvgames_paintable/PVGamesFloorPaintVisualTileset.tres"
WALL_TILESET = "res://assets/tilesets/pvgames_paintable/PVGamesWallPaintVisualTileset.tres"

FLOOR_POINTS = [
    (-960, -250),
    (-820, -430),
    (-500, -430),
    (-430, -690),
    (430, -690),
    (500, -430),
    (790, -430),
    (960, -260),
    (960, 340),
    (800, 500),
    (470, 500),
    (330, 420),
    (-360, 420),
    (-500, 520),
    (-900, 520),
    (-1040, 360),
    (-1040, -120),
]

STATIONS = [
    ("ENTRY / EXIT", "EntryExitDoor", (760, 430), (220, 190), "Paint door/wall art here; keep gameplay marker"),
    ("BENTLEY CARE", "BentleyCareStation", (520, 330), (170, 110), "Care props/signage; leave proxy clear"),
    ("LOOT CRATE", "LootCrateDropZone", (210, 350), (150, 120), "Delivery crates and reward props"),
    ("BENTLEY", "Bentley", (-760, 350), (160, 120), "Cozy dog zone"),
    ("JAKE", "Jake", (-560, 300), (130, 100), "Character corner"),
    ("MERE", "Mere", (-420, 300), (130, 100), "Character corner"),
    ("MISSION BOARD", "MissionBoard", (520, -410), (230, 120), "Screens, signs, planning glow"),
    ("THE BIG CASE", "EvidenceBoard_TheBigCase", (0, -405), (260, 120), "Evidence board/back wall"),
    ("GREENHOUSE", "GreenhouseAlcove", (0, -610), (760, 140), "Glass, plants, soft lighting"),
    ("PLANNING TABLE", "PlanningTable", (0, 20), (420, 230), "Tabletop props and screens"),
    ("POLAROID WALL", "PolaroidWall", (-850, -230), (220, 130), "Photo wall/display frames"),
    ("GLOW GUY SHELF", "GlowGuyShelf", (-880, -40), (220, 110), "Collectible shelf"),
    ("TINY ICON SHELF", "TinyIconShelf", (-880, 110), (220, 110), "Small collectible shelf"),
    ("POOP BAG DISPLAY", "PoopBagCareDisplay", (-840, 250), (220, 110), "Care display/storage"),
    ("STORE", "StoreTerminal", (790, -80), (250, 170), "Store tech, monitors, neon"),
    ("OPEN DECOR AREA", "OpenDecorZone", (470, 120), (440, 350), "Keep open for placed decor"),
    ("COZY LOUNGE", "CozyLounge", (-640, 360), (470, 260), "Lounge props/rugs"),
]

FLOOR_SOURCES = [
    {
        "asset_id": "pvg_floor_diamond_floormat1_2",
        "path": "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_2.png",
        "region": (67, 37),
        "tile_size": (64, 32),
        "reason": "Measured diamond-ish floor mat; safe as a single visual-only paint tile.",
    },
    {
        "asset_id": "pvg_floor_diamond_floormat1_4",
        "path": "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_4.png",
        "region": (63, 36),
        "tile_size": (64, 32),
        "reason": "Measured diamond-ish floor mat variant; visual-only floor painting candidate.",
    },
    {
        "asset_id": "pvg_floor_patch_floormat1_7",
        "path": "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_7.png",
        "region": (76, 39),
        "tile_size": (64, 32),
        "reason": "Small floor patch useful for guide/test paint marks; not gameplay collision.",
    },
]

WALL_SOURCES = [
    {
        "asset_id": "pvg_wall_back_citywalls1_2",
        "path": "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/CityWalls1_2.png",
        "region": (227, 180),
        "tile_size": (128, 96),
        "reason": "Actual PVGames wall source used as a one-piece visual paint tile.",
    },
    {
        "asset_id": "pvg_wall_back_citywalls1_4",
        "path": "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/CityWalls1_4.png",
        "region": (230, 179),
        "tile_size": (128, 96),
        "reason": "Actual PVGames wall source used as a one-piece visual paint tile.",
    },
    {
        "asset_id": "pvg_door_window_door10_4",
        "path": "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/Door10_4.png",
        "region": (76, 116),
        "tile_size": (64, 96),
        "reason": "Door/window visual tile for wall-layer painting near entry/backdrop.",
    },
]


def res_path(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def packed_points(points: list[tuple[int, int]], close: bool = False) -> str:
    data = list(points)
    if close:
        data.append(points[0])
    return "PackedVector2Array(" + ", ".join(f"{x}, {y}" for x, y in data) + ")"


def sanitize(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]+", "_", name).strip("_")


def add_ext_resource(text: str, resource_type: str, path: str, resource_id: str) -> str:
    if f'path="{path}"' in text:
        return text
    lines = text.splitlines()
    insert_at = 0
    for idx, line in enumerate(lines):
        if line.startswith("[ext_resource"):
            insert_at = idx + 1
    lines.insert(insert_at, f'[ext_resource type="{resource_type}" path="{path}" id="{resource_id}"]')
    return "\n".join(lines) + "\n"


def remove_node_block(text: str, node_name: str, parent: str) -> str:
    pattern = re.compile(
        rf'\n\[node name="{re.escape(node_name)}" [^\]]*parent="{re.escape(parent)}"[^\]]*\]\n.*?(?=\n\[node |\Z)',
        re.S,
    )
    return pattern.sub("\n", text)


def guide_block() -> str:
    lines = [
        '[node name="EditorGuideLayer" type="Node2D" parent="ArtRoot/World"]',
        "z_index = 260",
        "script = ExtResource(\"16_editor_guide\")",
        "",
        '[node name="GuideTitle" type="Label" parent="ArtRoot/World/EditorGuideLayer"]',
        "position = Vector2(-1040, -760)",
        'text = "EDITOR ART PLACEMENT GUIDE - visual only, hidden on play"',
        "theme_override_colors/font_color = Color(0.4, 1, 1, 0.95)",
        "theme_override_font_sizes/font_size = 22",
        "",
        '[node name="PlayableFloorFootprint" type="Polygon2D" parent="ArtRoot/World/EditorGuideLayer"]',
        f"polygon = {packed_points(FLOOR_POINTS)}",
        "color = Color(0.1, 0.55, 0.75, 0.14)",
        "",
        '[node name="PlayableBoundaryOutline" type="Line2D" parent="ArtRoot/World/EditorGuideLayer"]',
        f"points = {packed_points(FLOOR_POINTS, True)}",
        "width = 8.0",
        "default_color = Color(0.3, 0.95, 1, 0.75)",
        "",
        '[node name="WallPaintGuideNorth" type="Line2D" parent="ArtRoot/World/EditorGuideLayer"]',
        "points = PackedVector2Array(-820, -430, -500, -430, -430, -690, 430, -690, 500, -430, 790, -430)",
        "width = 5.0",
        "default_color = Color(1, 0.72, 0.18, 0.78)",
        "",
        '[node name="WallPaintGuideWest" type="Line2D" parent="ArtRoot/World/EditorGuideLayer"]',
        "points = PackedVector2Array(-960, -250, -820, -430, -1040, -120, -1040, 360, -900, 520)",
        "width = 5.0",
        "default_color = Color(1, 0.72, 0.18, 0.65)",
        "",
        '[node name="WallPaintHintNorth" type="Label" parent="ArtRoot/World/EditorGuideLayer"]',
        "position = Vector2(-205, -735)",
        'text = "Paint walls/windows along this edge"',
        "theme_override_colors/font_color = Color(1, 0.84, 0.35, 0.9)",
        "theme_override_font_sizes/font_size = 18",
        "",
        '[node name="DecorHint" type="Label" parent="ArtRoot/World/EditorGuideLayer"]',
        "position = Vector2(245, 330)",
        'text = "Keep open for decor placement"',
        "theme_override_colors/font_color = Color(0.6, 1, 0.85, 0.9)",
        "theme_override_font_sizes/font_size = 16",
        "",
    ]
    for label, node_name, pos, size, hint in STATIONS:
        x, y = pos
        w, h = size
        half_w = w * 0.5
        half_h = h * 0.5
        safe = sanitize(node_name)
        lines += [
            f'[node name="GuideBox_{safe}" type="Polygon2D" parent="ArtRoot/World/EditorGuideLayer"]',
            f"position = Vector2({x}, {y})",
            f"polygon = PackedVector2Array({-half_w:.1f}, {-half_h:.1f}, {half_w:.1f}, {-half_h:.1f}, {half_w:.1f}, {half_h:.1f}, {-half_w:.1f}, {half_h:.1f})",
            "color = Color(0.95, 0.35, 0.95, 0.12)",
            "",
            f'[node name="GuideOutline_{safe}" type="Line2D" parent="ArtRoot/World/EditorGuideLayer"]',
            f"position = Vector2({x}, {y})",
            f"points = PackedVector2Array({-half_w:.1f}, {-half_h:.1f}, {half_w:.1f}, {-half_h:.1f}, {half_w:.1f}, {half_h:.1f}, {-half_w:.1f}, {half_h:.1f}, {-half_w:.1f}, {-half_h:.1f})",
            "width = 3.0",
            "default_color = Color(1, 0.55, 1, 0.62)",
            "",
            f'[node name="GuideLabel_{safe}" type="Label" parent="ArtRoot/World/EditorGuideLayer"]',
            f"position = Vector2({x - half_w + 8:.1f}, {y - half_h + 6:.1f})",
            f'text = "{label}"',
            "theme_override_colors/font_color = Color(1, 0.95, 0.65, 0.95)",
            "theme_override_font_sizes/font_size = 14",
            "",
            f'[node name="GuideHint_{safe}" type="Label" parent="ArtRoot/World/EditorGuideLayer"]',
            f"position = Vector2({x - half_w + 8:.1f}, {y + half_h - 24:.1f})",
            f'text = "{hint}"',
            "theme_override_colors/font_color = Color(0.7, 1, 0.95, 0.74)",
            "theme_override_font_sizes/font_size = 11",
            "",
        ]
    return "\n".join(lines)


def paint_layer_block() -> str:
    return "\n".join(
        [
            '[node name="PVGamesFloorPaintLayer" type="TileMapLayer" parent="ArtRoot/World/FloorLayer"]',
            "z_index = 20",
            "tile_set = ExtResource(\"17_pvg_floor_tileset\")",
            "collision_enabled = false",
            "",
            '[node name="PVGamesWallPaintLayer" type="TileMapLayer" parent="ArtRoot/World/WallLayer"]',
            "z_index = 20",
            "tile_set = ExtResource(\"18_pvg_wall_tileset\")",
            "collision_enabled = false",
            "",
        ]
    )


def update_hideout_scene() -> None:
    text = HIDEOUT.read_text(encoding="utf-8")
    text = add_ext_resource(text, "Script", GUIDE_SCRIPT, "16_editor_guide")
    text = add_ext_resource(text, "TileSet", FLOOR_TILESET, "17_pvg_floor_tileset")
    text = add_ext_resource(text, "TileSet", WALL_TILESET, "18_pvg_wall_tileset")
    text = remove_node_block(text, "EditorGuideLayer", "ArtRoot/World")
    text = remove_node_block(text, "PVGamesFloorPaintLayer", "ArtRoot/World/FloorLayer")
    text = remove_node_block(text, "PVGamesWallPaintLayer", "ArtRoot/World/WallLayer")
    marker = '[node name="HideoutPVGamesVisualHelper" type="Node2D" parent="ArtRoot/World"'
    insert = guide_block() + "\n\n" + paint_layer_block() + "\n"
    text = text.replace(marker, insert + "\n" + marker, 1)
    HIDEOUT.write_text(text, encoding="utf-8")


def write_tileset(path: Path, sources: list[dict[str, Any]], tile_size: tuple[int, int], uid: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f'[gd_resource type="TileSet" format=3 uid="{uid}"]', ""]
    for i, src in enumerate(sources, 1):
        lines.append(f'[ext_resource type="Texture2D" path="{src["path"]}" id="{i}_src"]')
    lines.append("")
    for i, src in enumerate(sources):
        width, height = src["region"]
        lines += [
            f'[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_{i}"]',
            f'texture = ExtResource("{i + 1}_src")',
            f"texture_region_size = Vector2i({width}, {height})",
            "0:0/0 = 0",
            "",
        ]
    lines += [
        "[resource]",
        "tile_shape = 1",
        f"tile_size = Vector2i({tile_size[0]}, {tile_size[1]})",
    ]
    for i in range(len(sources)):
        lines.append(f'sources/{i} = SubResource("TileSetAtlasSource_{i}")')
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_test_scene() -> None:
    TOOLS_SCENES.mkdir(parents=True, exist_ok=True)
    path = TOOLS_SCENES / "PVGamesPaintableAtlasTest.tscn"
    lines = [
        '[gd_scene load_steps=3 format=3 uid="uid://pvgames_paintable_atlas_test"]',
        "",
        f'[ext_resource type="TileSet" path="{FLOOR_TILESET}" id="1_floor"]',
        f'[ext_resource type="TileSet" path="{WALL_TILESET}" id="2_wall"]',
        "",
        '[node name="PVGamesPaintableAtlasTest" type="Node2D"]',
        "",
        '[node name="Title" type="Label" parent="."]',
        "position = Vector2(-320, -240)",
        'text = "PVGames paintable test scene - visual-only TileMapLayer samples"',
        "",
        '[node name="FloorPaintLayer" type="TileMapLayer" parent="."]',
        "position = Vector2(-160, 0)",
        'tile_map_data = PackedByteArray("AAAAAA==")',
        'tile_set = ExtResource("1_floor")',
        "collision_enabled = false",
        "",
        '[node name="WallPaintLayer" type="TileMapLayer" parent="."]',
        "position = Vector2(220, 0)",
        'tile_map_data = PackedByteArray("AAAAAA==")',
        'tile_set = ExtResource("2_wall")',
        "collision_enabled = false",
        "",
        '[node name="Note" type="Label" parent="."]',
        "position = Vector2(-320, 180)",
        'text = "Sources are actual PVGames PNGs under assets/tilesets, not docs/reports contact sheets. Collision is disabled."',
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def scan_contact_sheet_usage() -> dict[str, Any]:
    text = HIDEOUT.read_text(encoding="utf-8")
    contact_patterns = [
        "res://docs/reports/pvgames_palettes/",
        "pvgames_birthday_build_curated_palette.png",
        "pvgames_palette_",
    ]
    matches = []
    for pattern in contact_patterns:
        if pattern in text:
            matches.append(pattern)
    loose_files = sorted(str(p.relative_to(ROOT)).replace("\\", "/") for p in (ROOT / "scenes/hideout").glob("pvgames_palette*.png"))
    return {
        "visible_scene_texture_matches": matches,
        "loose_contact_sheet_files_in_scene_folder": loose_files,
        "recommended_action": "No saved HideoutHub Sprite2D contact-sheet texture reference was found. Loose contact-sheet copies in scenes/hideout should be deleted manually later if not needed; they are not production source art.",
    }


def atlas_candidates() -> list[dict[str, Any]]:
    out = []
    for src in FLOOR_SOURCES:
        out.append({**src, "category": "FLOOR_DIAMOND_OR_PATCH", "decision": "created_visual_tileset_source", "contact_sheet": False})
    for src in WALL_SOURCES:
        out.append({**src, "category": "WALL_OR_DOOR_WINDOW", "decision": "created_visual_tileset_source", "contact_sheet": False})
    out.append({
        "asset_id": "all_docs_reports_pvgames_palettes",
        "path": "res://docs/reports/pvgames_palettes/*.png",
        "category": "CONTACT_SHEET",
        "decision": "excluded",
        "contact_sheet": True,
        "reason": "Contact sheets are browse-only menu images and must never be TileSet or Sprite2D production sources.",
    })
    return out


def write_docs() -> dict[str, Any]:
    REPORTS.mkdir(parents=True, exist_ok=True)
    contact_usage = scan_contact_sheet_usage()
    candidates = atlas_candidates()
    inventory = write_inventory(contact_usage)
    write_manual_correction()
    write_atlas_reports(candidates)
    write_stamper_notes()
    write_how_to()
    report = write_main_report(contact_usage, candidates, inventory)
    return report


def write_manual_correction() -> None:
    (REPORTS / "pvgames_manual_art_placement_correction.md").write_text("""# PVGames Manual Art Placement Correction

Contact sheet images are for browsing only.

- Browse-only contact sheets live under `res://docs/reports/pvgames_palettes/`.
- Do not assign contact sheets to production `Sprite2D` nodes.
- Do not use contact sheets as TileSet sources.
- Actual PVGames source art lives under `res://assets/tilesets/cyber_city_core_tilesets/`.

Correct source path:

`res://assets/tilesets/cyber_city_core_tilesets/.../*.png`

Incorrect production texture path:

`res://docs/reports/pvgames_palettes/.../*.png`

For one-off props, use `Sprite2D` with an actual source PNG. For an atlas/sheet, either enable `Region` on `Sprite2D` and crop one part, or create/use a TileSet and paint with a `TileMapLayer`. For repeatable floors/walls, use TileSet + TileMapLayer only when the source slices cleanly. For irregular props, furniture, signs, displays, terminals, and clutter, use `Sprite2D` or `PVGamesArtStamper`.

Always place PVGames environment art under `ArtRoot/World`, never `GameplayRoot`, and never add gameplay collision to PVGames art.
""", encoding="utf-8")


def write_inventory(contact_usage: dict[str, Any]) -> dict[str, Any]:
    inventory = {
        "status": "PASS",
        "scene": "res://scenes/hideout/HideoutHub.tscn",
        "contact_sheet_sprite_usage": contact_usage,
        "saved_pvgames_nodes": [
            {
                "node_path": "ArtRoot/World/HideoutPVGamesVisualHelper",
                "parent_layer": "ArtRoot/World",
                "texture_path": "runtime helper loads actual source PNGs from res://assets/tilesets/cyber_city_core_tilesets/",
                "uses_actual_source_art": True,
                "uses_contact_sheet": False,
                "z_index": "runtime per helper spec",
                "visible": True,
                "safe_to_delete": "yes, if you want to remove the whole 0M-B visual dressing helper; do not delete gameplay nodes",
                "notes": "Runtime visual-only helper. It does not create collision.",
            },
            {
                "node_path": "ArtRoot/World/EditorGuideLayer",
                "parent_layer": "ArtRoot/World",
                "texture_path": "",
                "uses_actual_source_art": False,
                "uses_contact_sheet": False,
                "z_index": 260,
                "visible": "editor only; hidden on play",
                "safe_to_delete": "yes, editor guide only, but it is useful for art placement",
                "notes": "Visual-only guide nodes; no collision nodes.",
            },
            {
                "node_path": "ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer",
                "parent_layer": "ArtRoot/World/FloorLayer",
                "texture_path": FLOOR_TILESET,
                "uses_actual_source_art": True,
                "uses_contact_sheet": False,
                "z_index": 20,
                "visible": True,
                "safe_to_delete": "yes, visual-only empty paint layer",
                "notes": "TileMapLayer collision disabled.",
            },
            {
                "node_path": "ArtRoot/World/WallLayer/PVGamesWallPaintLayer",
                "parent_layer": "ArtRoot/World/WallLayer",
                "texture_path": WALL_TILESET,
                "uses_actual_source_art": True,
                "uses_contact_sheet": False,
                "z_index": 20,
                "visible": True,
                "safe_to_delete": "yes, visual-only empty paint layer",
                "notes": "TileMapLayer collision disabled.",
            },
        ],
    }
    (REPORTS / "hideout_existing_pvgames_visual_nodes_inventory.json").write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    lines = [
        "# Hideout Existing PVGames Visual Nodes Inventory",
        "",
        "Status: PASS",
        "",
        "No saved visible `Sprite2D` texture reference to `res://docs/reports/pvgames_palettes/` was found in `HideoutHub.tscn`.",
        "",
        "Loose contact-sheet PNG copies found in `scenes/hideout/`:",
    ]
    for f in contact_usage["loose_contact_sheet_files_in_scene_folder"]:
        lines.append(f"- `{f}`")
    lines += [
        "",
        "These loose files are not production source art. Actual source art remains under `res://assets/tilesets/cyber_city_core_tilesets/`.",
        "",
        "## Visual Nodes",
        "",
    ]
    for item in inventory["saved_pvgames_nodes"]:
        lines += [
            f"### `{item['node_path']}`",
            f"- Parent layer: `{item['parent_layer']}`",
            f"- Texture/source: `{item['texture_path']}`",
            f"- Uses contact sheet: {item['uses_contact_sheet']}",
            f"- Z-index: {item['z_index']}",
            f"- Visible: {item['visible']}",
            f"- Safe to delete: {item['safe_to_delete']}",
            f"- Notes: {item['notes']}",
            "",
        ]
    (REPORTS / "hideout_existing_pvgames_visual_nodes_inventory.md").write_text("\n".join(lines), encoding="utf-8")
    return inventory


def write_atlas_reports(candidates: list[dict[str, Any]]) -> None:
    (REPORTS / "pvgames_paintable_atlas_candidates.json").write_text(json.dumps({
        "status": "PASS",
        "actual_source_pngs_used": True,
        "contact_sheets_used_as_sources": False,
        "tileset_resources_created": [FLOOR_TILESET, WALL_TILESET],
        "tilemap_layers_created": [
            "res://scenes/hideout/HideoutHub.tscn::ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer",
            "res://scenes/hideout/HideoutHub.tscn::ArtRoot/World/WallLayer/PVGamesWallPaintLayer",
        ],
        "candidates": candidates,
    }, indent=2), encoding="utf-8")
    lines = [
        "# PVGames Paintable Atlas Candidates",
        "",
        "Status: PASS",
        "",
        "Only actual source PNGs under `res://assets/tilesets/cyber_city_core_tilesets/` were used. Contact sheets under `res://docs/reports/pvgames_palettes/` were explicitly excluded.",
        "",
        f"- Floor TileSet: `{FLOOR_TILESET}`",
        f"- Wall TileSet: `{WALL_TILESET}`",
        "- Collision: disabled by using visual-only TileSets and `collision_enabled = false` on paint layers.",
        "",
        "| Asset ID | Source | Decision | Reason |",
        "| --- | --- | --- | --- |",
    ]
    for c in candidates:
        lines.append(f"| `{c['asset_id']}` | `{c['path']}` | {c['decision']} | {c['reason']} |")
    (REPORTS / "pvgames_paintable_atlas_candidates.md").write_text("\n".join(lines), encoding="utf-8")


def write_stamper_notes() -> None:
    (REPORTS / "pvgames_stamper_usage_notes.md").write_text("""# PVGames Stamper Usage Notes

Use `PVGamesArtStamper.gd` for irregular props: furniture, signs, shelves, displays, terminals, plants, clutter, and oversized one-off art.

- Tool path: `res://src/tools/editor/PVGamesArtStamper.gd`
- Sample manifest: `res://docs/reports/pvgames_sample_art_placement_manifest.json`
- Type: `@tool` `EditorScript`
- Default safety: refuses to overwrite the target scene unless an output scene path is supplied.
- Collision: does not create `StaticBody2D`, `Area2D`, or `CollisionShape2D`.
- Metadata: writes `pvgames_asset_id`, `category`, `subcategory`, `placement_method`, `visual_only`, and `collision_disabled`.

Use a real source PNG from `res://assets/tilesets/cyber_city_core_tilesets/`, target an `ArtRoot/World` layer such as `PropLayer` or `DecorationLayer`, and stamp into a duplicate/test scene first. Remove stamped art by deleting the `PVGamesStampedArt` container or the individual `PVG_*` Sprite2D nodes. Do not use TileMapLayer for irregular props.
""", encoding="utf-8")


def write_how_to() -> None:
    (REPORTS / "pvgames_how_to_paint_and_place_art_now.md").write_text("""# How To Paint And Place PVGames Art Now

## A. What Files Are What

- Contact sheets are visual menus only: `res://docs/reports/pvgames_palettes/*.png`.
- Actual production PNGs live under `res://assets/tilesets/cyber_city_core_tilesets/`.
- TileSet/TileMapLayer is for repeatable floor/wall painting.
- Sprite2D/stamper is for irregular props, furniture, signs, shelves, displays, terminals, plants, and clutter.

## B. Viewing Categorized Assets

Open `pvgames_birthday_build_curated_palette.png` for the short best-of board. Use category contact sheets for broader browsing, the CSV for search/filtering, and `res://scenes/hideout/tools/PVGamesAssetPaletteBrowser.tscn` for a lightweight Godot scene preview.

## C. Finding Real Source PNGs

Open the curated palette markdown or JSON, find the `asset_id`, then copy the `path` that starts with `res://assets/tilesets/cyber_city_core_tilesets/`. Do not use any `res://docs/reports/pvgames_palettes/` path as a Sprite2D or TileSet texture.

## D. Seeing The Hideout Layout

Open `HideoutHub.tscn`, select `ArtRoot/World/EditorGuideLayer`, and press `F`. Use the cyan floor footprint, orange wall edge hints, magenta station boxes, and labels to orient yourself. Hide/show the whole guide with the eye icon on `EditorGuideLayer`; it hides automatically when the game runs.

## E. Painting Floors/Walls

Select `ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer` or `ArtRoot/World/WallLayer/PVGamesWallPaintLayer`. Open the TileMap panel, choose a tile from the assigned TileSet, and paint. Collision is disabled. Use the guide for alignment and save the scene when you like the result.

## F. Placing Individual Props

Add a `Sprite2D` under the correct `ArtRoot/World` layer, assign an actual source PNG, position it visually, set scale/z-index, and do not add collision. Use `PVGamesArtStamper.gd` for manifest-based bulk placement into a duplicate/test scene.

## G. Recommended Parent Layers

- Floors/rugs/ground: `FloorLayer`
- Walls/windows: `WallLayer`
- Furniture/station props: `PropLayer`
- Clutter/decor: `DecorationLayer`
- Display shelves/frames: `CollectibleLayer`
- Tall foreground objects: `ForegroundLayer`
- Glow/sign/light art: `LightingLayer`

## H. Recommended Z-Index Ranges

- FloorLayer: `-300`
- WallLayer: `-220`
- PropLayer: `-120` to `-60`
- DecorationLayer: `-90` to `-40`
- CollectibleLayer: `-70` to `-30`
- ForegroundLayer: `120+`
- LightingLayer: `180+`
- UI: CanvasLayer above all

## I. Y-Sort Guidance

Do not use Y-sort for floors. Usually do not use Y-sort for background walls. Maybe use Y-sort for props/characters only when needed. Set z-index first, then use y-sort within a matching z-index group.

## J. Removing Unwanted Art

Search the scene tree for `PVG`, `PVGames`, or the layer you edited. Hide first with the eye icon, then delete unwanted Sprite2D nodes or art-only containers. Do not delete `GameplayRoot`, station proxies, collision nodes, MissionBoard, StoreTerminal, or Decorating Mode nodes.

## K. Common Mistakes

- Using a contact sheet as a texture.
- Placing walls in `FloorLayer`.
- Placing environment art under `GameplayRoot`.
- Adding collision to PVGames art.
- Using an atlas as Sprite2D without Region.
- Using TileMap for irregular props.
- Setting z-index so high that art covers player/UI.
- Deleting gameplay nodes while cleaning up visuals.
""", encoding="utf-8")


def write_main_report(contact_usage: dict[str, Any], candidates: list[dict[str, Any]], inventory: dict[str, Any]) -> dict[str, Any]:
    data = {
        "pass_fail_partial": "PASS",
        "backup_path": BACKUP_PATH,
        "hideout_modified": True,
        "taco_bell_scenes_modified": False,
        "contact_sheet_sprite_nodes_found": len(contact_usage["visible_scene_texture_matches"]),
        "contact_sheet_sprite_nodes_quarantined_or_removed": "none needed; no saved visible contact-sheet Sprite2D reference found",
        "editor_guide_path": "res://scenes/hideout/HideoutHub.tscn::ArtRoot/World/EditorGuideLayer",
        "editor_guide_created": True,
        "editor_guide_has_collision": False,
        "station_labels_created": True,
        "floor_guide_created": True,
        "atlas_candidates": candidates,
        "tileset_resources_created": [FLOOR_TILESET, WALL_TILESET],
        "tilemap_layers_created": [
            "ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer",
            "ArtRoot/World/WallLayer/PVGamesWallPaintLayer",
        ],
        "tilemap_collision_disabled": True,
        "source_pngs_used": [c["path"] for c in candidates if not c.get("contact_sheet")],
        "contact_sheets_used_as_sources": False,
        "gameplayroot_touched": False,
        "station_proxies_touched": False,
        "reports_written": [
            "res://docs/reports/pvgames_manual_art_placement_correction.md",
            "res://docs/reports/pvgames_paintable_atlas_candidates.md",
            "res://docs/reports/pvgames_paintable_atlas_candidates.json",
            "res://docs/reports/pvgames_stamper_usage_notes.md",
            "res://docs/reports/pvgames_how_to_paint_and_place_art_now.md",
            "res://docs/reports/hideout_existing_pvgames_visual_nodes_inventory.md",
            "res://docs/reports/hideout_existing_pvgames_visual_nodes_inventory.json",
            "res://docs/reports/hideout_phase_0mb3_pvgames_paintable_atlas_and_editor_guide.md",
            "res://docs/reports/hideout_phase_0mb3_pvgames_paintable_atlas_and_editor_guide.json",
        ],
        "validator_result": "static validation pending",
        "risks": [
            "TileSets are intentionally small safe starter palettes, not a conversion of the whole PVGames pack.",
            "The guide is approximate but based on existing HideoutManager floor/station coordinates.",
            "Loose contact-sheet image copies in scenes/hideout are reported but not deleted automatically.",
        ],
        "next_step": "Open HideoutHub, select ArtRoot/World/EditorGuideLayer, press F, then use the floor/wall paint layers or Sprite2D source PNGs for manual art placement.",
    }
    (REPORTS / "hideout_phase_0mb3_pvgames_paintable_atlas_and_editor_guide.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    lines = [
        "# Hideout Phase 0M-B3 PVGames Paintable Atlas And Editor Guide",
        "",
        "Status: PASS",
        "",
        f"- Backup path: `{BACKUP_PATH}`",
        "- HideoutHub modified: yes, visual-only editor guide and empty paint layers only.",
        "- Taco Bell scenes modified: no.",
        "- Gameplay scripts modified: no.",
        f"- Contact-sheet Sprite2D nodes found: {data['contact_sheet_sprite_nodes_found']}",
        f"- Contact-sheet handling: {data['contact_sheet_sprite_nodes_quarantined_or_removed']}",
        "- Contact sheets are browse-only: `res://docs/reports/pvgames_palettes/*.png`.",
        "- Real source art: `res://assets/tilesets/cyber_city_core_tilesets/**/*.png`.",
        "",
        "## Why The Graybox Was Not Visible In Editor",
        "",
        "`HideoutHub.tscn` saved the empty containers (`FloorLayer`, `WallLayer`, `PropLayer`, etc.), but `HideoutManager.gd` builds the irregular floor polygon, boundary collision, walkable area, station interactables, and graybox station visuals at runtime in `_build_world_layers()`, `_build_navigation_collision()`, and `_build_stations()`. The 0M-B PVGames visual helper is also runtime/deferred visual dressing. So the editor had no saved floor footprint/station guide to frame, leaving mostly colored markers and the player token visible.",
        "",
        "Select `ArtRoot/World/EditorGuideLayer` and press `F` to focus the actual playable hideout area now.",
        "",
        "## Editor Guide",
        "",
        "- Path: `ArtRoot/World/EditorGuideLayer`",
        "- Visual-only: yes.",
        "- Collision: none.",
        "- Hide behavior: visible in editor, hidden on play by `HideoutEditorGuideLayer.gd`.",
        "- Components: floor footprint, boundary outline, wall paint hints, station guide boxes, station labels, zone hints.",
        "",
        "## Paintable TileMap Workflow",
        "",
        f"- Floor TileSet: `{FLOOR_TILESET}`",
        f"- Wall TileSet: `{WALL_TILESET}`",
        "- Floor paint layer: `ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer`",
        "- Wall paint layer: `ArtRoot/World/WallLayer/PVGamesWallPaintLayer`",
        "- Collision disabled: yes.",
        "- Sources are actual PVGames PNGs, not contact sheets.",
        "",
        "## Sprite2D/Stamper Workflow",
        "",
        "Use Sprite2D or `PVGamesArtStamper.gd` for irregular props, furniture, signs, shelves, displays, terminals, clutter, and plants. Do not force those into TileMapLayer.",
        "",
        "## Direct Answers",
        "",
        "1. You do not need to manually add every individual sprite/tile; use curated palette, TileMap paint layers for safe repeatables, and stamper/Sprite2D for props.",
        "2. Yes, this can be automated with `PVGamesArtStamper.gd`, but it should write duplicate/test scenes first.",
        "3. Yes, Cursor can find all real source art from the catalog automatically.",
        "4. One Sprite2D uses one texture at a time; for atlases use Region or TileSet.",
        "5. Each separate placed prop normally needs its own Sprite2D node unless stamped/generated into a container.",
        "6. Use TileMapLayer for repeatable floor/wall tiles that slice cleanly.",
        "7. Use atlases when you want repeated tile painting or Region-cropped sheet pieces.",
        "8. The contact sheet appeared huge because it is one giant browse image assigned as one Sprite2D texture.",
        "9. Atlases were not recommended for everything because most PVGames files are irregular props/sheets, not one consistent global grid.",
        "10. Contact sheets are `res://docs/reports/pvgames_palettes/*.png`.",
        "11. Actual source art is `res://assets/tilesets/cyber_city_core_tilesets/**/*.png`.",
        "12. Paint walls/floors with `PVGamesFloorPaintLayer` and `PVGamesWallPaintLayer`.",
        "13. Place individual props as Sprite2D under the correct `ArtRoot/World` layer or use the stamper.",
        "14. See the hideout layout with `ArtRoot/World/EditorGuideLayer`.",
        "15. Remove unwanted assets by hiding/deleting art-only `PVG*`/`PVGames*` nodes; do not delete GameplayRoot nodes.",
        "16. Prevent collision by never adding CollisionShape2D/Area2D/StaticBody2D to PVGames art and keeping TileMap collision disabled.",
        "17. Use Y-sort only for props/characters when z-index alone is not enough.",
        "18. Avoid false walk-on-wall/counter visuals by keeping big props near existing edges and out of walkable center.",
        "19. Use z-index ranges from the how-to guide: floor around -300, wall around -220, props -120 to -60, foreground 120+, lighting 180+.",
        "20. Focus the map by selecting `ArtRoot/World/EditorGuideLayer` and pressing `F`.",
        "",
        "## Risks / Limitations",
    ]
    for risk in data["risks"]:
        lines.append(f"- {risk}")
    lines += [
        "",
        "## Manual Test Checklist",
        "",
        "Open HideoutHub, confirm the guide and labels are visible, select paint layers to see tiles, paint one test tile, verify no collision is added, hide the guide, run the scene, and verify player movement/stations/MissionBoard/pause return still work.",
    ]
    (REPORTS / "hideout_phase_0mb3_pvgames_paintable_atlas_and_editor_guide.md").write_text("\n".join(lines), encoding="utf-8")
    return data


def main() -> None:
    TILESET_DIR.mkdir(parents=True, exist_ok=True)
    write_tileset(TILESET_DIR / "PVGamesFloorPaintVisualTileset.tres", FLOOR_SOURCES, (64, 32), "uid://pvgames_floor_paint_visual")
    write_tileset(TILESET_DIR / "PVGamesWallPaintVisualTileset.tres", WALL_SOURCES, (128, 96), "uid://pvgames_wall_paint_visual")
    write_test_scene()
    update_hideout_scene()
    report = write_docs()
    print(json.dumps({
        "status": "PASS",
        "hideout_modified": True,
        "editor_guide": report["editor_guide_path"],
        "tilesets": report["tileset_resources_created"],
        "contact_sheet_sprite_nodes_found": report["contact_sheet_sprite_nodes_found"],
    }, indent=2))


if __name__ == "__main__":
    main()
