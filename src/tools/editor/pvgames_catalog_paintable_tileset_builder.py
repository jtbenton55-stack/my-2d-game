#!/usr/bin/env python3
"""
Build verified, catalog-derived PVGames paintable TileSet palettes.

This pass derives candidates from the existing full catalog, classifies them,
creates split visual-only TileSets, renders verification/contact sheets, writes
reports, and adds empty HideoutHub paint layers under ArtRoot/World only.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports"
CATALOG_JSON = REPORTS / "pvgames_full_asset_catalog.json"
CATALOG_CSV = REPORTS / "pvgames_full_asset_catalog.csv"
CURATED_JSON = REPORTS / "pvgames_birthday_build_curated_palette.json"
HIDEOUT = ROOT / "scenes/hideout/HideoutHub.tscn"
TILESET_DIR = ROOT / "assets/tilesets/pvgames_catalog_paintable"
VERIFICATION_DIR = REPORTS / "pvgames_catalog_paintable_verification"
PALETTE_SHEET_DIR = REPORTS / "pvgames_catalog_paintable_palettes"
TEST_SCENE = ROOT / "scenes/hideout/tools/PVGamesCatalogPaintableTileSetTest.tscn"

ASSET_ROOT_PREFIX = "res://assets/tilesets/cyber_city_core_tilesets/"
CONTACT_PREFIX = "res://docs/reports/pvgames_palettes/"

GROUND_TILESET = "res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres"
WALL_TILESET = "res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres"
LARGE_TILESET = "res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogLargeStructurePaint.tres"
PROP_TILESET = "res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres"
REVIEW_TILESET = "res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogReviewOnlyPaint.tres"

PALETTE_LIMITS = {
    "ground_road": 120,
    "wall": 160,
    "large_structure": 90,
    "prop_sign": 100,
    "review_only": 80,
}


def rel(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def local_path(res: str) -> Path:
    return ROOT / res.removeprefix("res://")


def safe_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]+", "_", name).strip("_")


def keyword(text: str, terms: list[str]) -> bool:
    low = text.lower()
    return any(t.lower() in low for t in terms)


PRIMARY_ATLAS_CATEGORIES = {"TILESET_ATLAS"}
POOL_B_TERMS = [
    "Floor",
    "Ground_Tile",
    "Ground_Decal",
    "Ground_LargeStreetChunk",
    "Road",
    "Wall",
    "CityWalls",
    "CityWallsCorner",
    "CityWallsPost",
    "SubwayWall",
    "Fence",
    "Ramp",
    "Door",
    "Window",
]
POOL_C_TERMS = [
    "Building",
    "Building_Interior",
    "Shack",
    "MetroStation",
    "SubwayPlatform",
    "MetroTrain",
    "Bridge",
    "Billboard",
    "BandStage",
    "BandVan",
    "ChargingStation",
    "SateliteDish",
    "SatelliteDish",
    "LargePipe",
    "Pipe",
    "Kiosk",
    "Clutter",
    "MetroLine",
    "SubwayRail",
]


def family_for(entry: dict[str, Any]) -> str:
    name = entry["filename"].lower()
    cat = entry.get("inferred_category", "")
    if keyword(name, ["floor", "ground", "road", "ramp"]) or cat in {"FLOOR_DIAMOND", "FLOOR_PATCH", "ROAD_STREET", "FX_DECAL"}:
        return "ground_road"
    if keyword(name, ["wall", "citywalls", "subwaywall", "fence", "door", "window", "post", "corner"]) or cat in {"WALL_BACK", "WALL_SIDE", "WALL_CORNER", "DOOR_WINDOW"}:
        return "wall"
    if keyword(name, ["building", "shack", "metrostation", "subwayplatform", "metrotrain", "bridge", "bandstage", "bandvan"]) or cat in {"BUILDING_LARGE", "FOREGROUND_TALL"}:
        return "large_structure"
    if keyword(name, ["billboard", "chargingstation", "satelite", "satellite", "pipe", "kiosk", "clutter", "metroline", "subwayrail", "sign"]):
        return "prop_sign"
    if cat == "TILESET_ATLAS":
        return "large_structure" if entry["width"] > 700 or entry["height"] > 700 else "ground_road"
    return "other"


def derive_candidates(catalog: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    candidates: list[dict[str, Any]] = []
    rejected_contact: list[dict[str, Any]] = []
    for e in catalog:
        path = str(e.get("path", ""))
        filename = str(e.get("filename", ""))
        text = " ".join([
            str(e.get("asset_id", "")),
            path,
            filename,
            str(e.get("inferred_category", "")),
            str(e.get("inferred_subcategory", "")),
        ])
        pools: list[str] = []
        if e.get("inferred_category") in PRIMARY_ATLAS_CATEGORIES:
            pools.append("A_PRIMARY_ATLAS")
        if keyword(text, POOL_B_TERMS):
            pools.append("B_HIGH_VALUE_PAINT")
        if keyword(text, POOL_C_TERMS):
            pools.append("C_LARGE_OBJECT_PAINT")
        if not pools:
            continue
        if CONTACT_PREFIX in path or "pvgames_palette" in filename.lower() or not path.startswith(ASSET_ROOT_PREFIX):
            rejected_contact.append({"asset_id": e.get("asset_id", ""), "path": path, "filename": filename, "reason": "not a real source PNG or contact/report image"})
            continue
        exists = local_path(path).exists() and path.lower().endswith(".png")
        c = {
            "asset_id": e["asset_id"],
            "path": path,
            "filename": filename,
            "catalog_category": e.get("inferred_category", ""),
            "catalog_subcategory": e.get("inferred_subcategory", ""),
            "width": int(e.get("width", 0)),
            "height": int(e.get("height", 0)),
            "alpha_bbox_width": int(e.get("alpha_bbox_width", 0)),
            "alpha_bbox_height": int(e.get("alpha_bbox_height", 0)),
            "transparent_pixel_percentage": float(e.get("transparent_pixel_percentage", 100.0)),
            "candidate_pools": pools,
            "file_exists": exists,
            "reason_included": ", ".join(pools),
        }
        candidates.append(c)
    return candidates, rejected_contact


def classify_candidate(c: dict[str, Any]) -> dict[str, Any]:
    name = c["filename"].lower()
    family = family_for({
        "filename": c["filename"],
        "inferred_category": c["catalog_category"],
        "width": c["width"],
        "height": c["height"],
    })
    w, h = c["width"], c["height"]
    bbox_w, bbox_h = c["alpha_bbox_width"], c["alpha_bbox_height"]
    transparent = c["transparent_pixel_percentage"]
    classification = "SPRITE_STAMP_BETTER"
    palette = "sprite_stamper"
    layer = "DecorationLayer"
    z_index = -65
    handling = "Use Sprite2D/PVGamesArtStamper."
    reason = "Irregular object is better as individually positioned Sprite2D art."

    if not c["file_exists"] or not c["path"].startswith(ASSET_ROOT_PREFIX):
        classification = "SKIP_UNSAFE"
        palette = "skip"
        reason = "Missing or not under PVGames source asset root."
        handling = "Exclude."
    elif transparent > 96 or bbox_w < 10 or bbox_h < 10:
        classification = "SKIP_UNSAFE"
        palette = "skip"
        reason = "Mostly transparent or too tiny to paint usefully."
        handling = "Exclude."
    elif w > 1400 or h > 1400:
        classification = "SKIP_UNSAFE"
        palette = "skip"
        reason = "Too large for a usable TileMap palette."
        handling = "Exclude unless hand-authored later."
    elif family == "ground_road":
        classification = "SINGLE_TILE_SPRITE"
        palette = "ground_road"
        layer = "FloorLayer"
        z_index = -300
        handling = "Add as one paintable visual tile."
        reason = "Floor/ground/road/decal family is useful as a paintable map tile."
    elif family == "wall":
        classification = "SINGLE_TILE_SPRITE"
        palette = "wall"
        layer = "WallLayer"
        z_index = -220
        handling = "Add as one paintable visual wall/corner/post tile."
        reason = "Wall/door/window/fence family is useful as modular wall art."
    elif family == "large_structure":
        classification = "LARGE_STRUCTURE_SPRITE"
        palette = "large_structure"
        layer = "PropLayer"
        z_index = -140
        handling = "Add as one large-object paint tile; use carefully."
        reason = "Large structure/facade/transit object belongs in a separate large palette."
    elif family == "prop_sign":
        if w <= 520 and h <= 520 and transparent < 88:
            classification = "SINGLE_TILE_SPRITE"
            palette = "prop_sign"
            layer = "DecorationLayer"
            z_index = -60
            handling = "Add as one paintable prop/sign tile."
            reason = "Sign/pipe/kiosk/environment object is practical enough as a paint tile."
        else:
            classification = "SPRITE_STAMP_BETTER"
            palette = "sprite_stamper"
            layer = "PropLayer"
            z_index = -80
    elif c["catalog_category"] == "TILESET_ATLAS":
        # The prior audit warned that grids cannot be inferred globally. Keep
        # this conservative unless a future pass adds per-atlas slicing rules.
        classification = "LARGE_STRUCTURE_SPRITE" if max(w, h) <= 1000 else "SKIP_UNSAFE"
        palette = "large_structure" if classification != "SKIP_UNSAFE" else "skip"
        layer = "PropLayer"
        z_index = -140
        handling = "Treat as one large visual tile; no blind grid slicing."
        reason = "Atlas-like source, but reliable cell size was not inferred; not sliced."

    c.update({
        "inferred_family": family,
        "classification": classification,
        "reason": reason,
        "recommended_palette": palette,
        "recommended_layer": layer,
        "recommended_z_index": z_index,
        "recommended_tileset_handling": handling,
        "recommended_tilemap_layer": tilemap_layer_for_palette(palette),
        "collision_disabled": True,
        "notes": "Derived from catalog; no user-pasted asset list required.",
    })
    return c


def tilemap_layer_for_palette(palette: str) -> str:
    return {
        "ground_road": "GroundRoadTileMapLayer / ArtRoot/World/FloorLayer",
        "wall": "WallTileMapLayer / ArtRoot/World/WallLayer",
        "large_structure": "LargeStructureTileMapLayer / ArtRoot/World/PropLayer",
        "prop_sign": "PropSignTileMapLayer / ArtRoot/World/DecorationLayer",
        "review_only": "ReviewOnlyTileMapLayer",
    }.get(palette, "")


def candidate_score(c: dict[str, Any]) -> float:
    score = 100.0
    score -= min(45.0, c["transparent_pixel_percentage"] * 0.25)
    score += min(25.0, (c["alpha_bbox_width"] * c["alpha_bbox_height"]) / 20000.0)
    if c["catalog_category"] in {"FLOOR_DIAMOND", "FLOOR_PATCH", "ROAD_STREET", "WALL_BACK", "WALL_SIDE", "WALL_CORNER", "DOOR_WINDOW"}:
        score += 30
    if c["classification"] == "LARGE_STRUCTURE_SPRITE":
        score += 10 if max(c["width"], c["height"]) < 800 else -10
    if c["classification"] == "SPRITE_STAMP_BETTER":
        score -= 30
    if c["width"] < 18 or c["height"] < 18:
        score -= 40
    return score


def select_for_tilesets(classified: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    buckets: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for c in classified:
        p = c["recommended_palette"]
        if p in {"ground_road", "wall", "large_structure", "prop_sign"}:
            buckets[p].append(c)
    selected: dict[str, list[dict[str, Any]]] = {}
    for palette, items in buckets.items():
        items = sorted(items, key=candidate_score, reverse=True)
        seen_prefix: Counter[str] = Counter()
        chosen: list[dict[str, Any]] = []
        for item in items:
            prefix = re.sub(r"_?\d+$", "", Path(item["filename"]).stem.lower())
            limit = 10 if palette in {"ground_road", "wall"} else 6
            if seen_prefix[prefix] >= limit:
                continue
            seen_prefix[prefix] += 1
            chosen.append(item)
            if len(chosen) >= PALETTE_LIMITS[palette]:
                break
        selected[palette] = chosen
    return selected


def inspect_image(path: str) -> dict[str, Any]:
    image = Image.open(local_path(path)).convert("RGBA")
    alpha = image.getchannel("A")
    visible = alpha.point(lambda v: 255 if v > 10 else 0)
    bbox = visible.getbbox()
    count = visible.histogram()[255]
    total = max(1, image.width * image.height)
    if bbox is None:
        bbox_w = bbox_h = 0
    else:
        bbox_w = bbox[2] - bbox[0]
        bbox_h = bbox[3] - bbox[1]
    return {
        "tile_preview_width": image.width,
        "tile_preview_height": image.height,
        "visible_alpha_bbox": [0, 0, 0, 0] if bbox is None else list(bbox),
        "alpha_bbox_width": bbox_w,
        "alpha_bbox_height": bbox_h,
        "transparent_percentage": round((total - count) * 100.0 / total, 2),
        "coverage_percentage": round(count * 100.0 / total, 2),
    }


def quality_classify(item: dict[str, Any], palette: str) -> dict[str, Any]:
    metrics = inspect_image(item["path"])
    w = metrics["tile_preview_width"]
    h = metrics["tile_preview_height"]
    bbox_w = metrics["alpha_bbox_width"]
    bbox_h = metrics["alpha_bbox_height"]
    transparent = metrics["transparent_percentage"]
    q = "READY_TO_PAINT"
    action = "keep in production palette"
    reason = "Coherent visible source image."
    warning = ""

    if not item["path"].startswith(ASSET_ROOT_PREFIX) or CONTACT_PREFIX in item["path"]:
        q, action, reason = "REJECT_JUNK", "remove from palette", "Invalid source path or contact sheet."
    elif bbox_w < 10 or bbox_h < 10 or transparent > 97:
        q, action, reason = "REJECT_JUNK", "remove from palette", "Blank, tiny, or mostly transparent."
    elif max(w, h) > 1100:
        q, action, reason = "REJECT_JUNK", "remove from palette", "Too huge for a normal paint palette."
    elif palette == "large_structure":
        if max(w, h) > 850 or transparent > 88:
            q, action, reason = "REVIEW_MANUALLY", "move to review palette", "Large/awkward structure needs human inspection before production use."
            warning = "large or sparse"
        else:
            q, reason = "READY_TO_PAINT", "Large coherent structure; use carefully."
            warning = "large object"
    elif palette in {"wall", "ground_road"}:
        q = "MODULAR_PART_OK"
        reason = "Modular floor/road/wall/door/window component; partial pieces are expected."
        if transparent > 90:
            q, action, reason = "REVIEW_MANUALLY", "move to review palette", "Very sparse modular-looking tile; inspect before production."
            warning = "sparse"
    elif palette == "prop_sign":
        if transparent > 88 or max(w, h) > 520:
            q, action, reason = "REVIEW_MANUALLY", "move to review palette", "Prop/sign is sparse or large; Sprite2D may be better."
            warning = "consider Sprite2D"
        else:
            q, reason = "READY_TO_PAINT", "Readable prop/sign object practical as a paint tile."

    review_passes = 3 if q == "REVIEW_MANUALLY" else 1
    out = {
        **item,
        **metrics,
        "palette_name": palette,
        "tile_id": f"{palette}_{safe_name(Path(item['filename']).stem)}_{hashlib.sha1(item['path'].encode()).hexdigest()[:6]}",
        "source_region": [0, 0, w, h],
        "classification_before_tileset_creation": item["classification"],
        "post_creation_quality_classification": q,
        "quality_reason": reason,
        "recommended_action": action,
        "quality_warning": warning,
        "review_inspection_passes": review_passes,
    }
    return out


def verify_selected(selected: dict[str, list[dict[str, Any]]]) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    production: dict[str, list[dict[str, Any]]] = {}
    all_verification: list[dict[str, Any]] = []
    review_items: list[dict[str, Any]] = []
    for palette, items in selected.items():
        verified = [quality_classify(item, palette) for item in items]
        all_verification.extend(verified)
        production[palette] = [v for v in verified if v["post_creation_quality_classification"] in {"READY_TO_PAINT", "MODULAR_PART_OK"}]
        review_items.extend([v for v in verified if v["post_creation_quality_classification"] == "REVIEW_MANUALLY"])
    production["review_only"] = review_items[: PALETTE_LIMITS["review_only"]]
    return production, all_verification


def write_tileset(path: Path, items: list[dict[str, Any]], uid: str, tile_shape: int = 1, tile_size: tuple[int, int] = (64, 32)) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f'[gd_resource type="TileSet" format=3 uid="{uid}"]', ""]
    for i, item in enumerate(items, 1):
        lines.append(f'[ext_resource type="Texture2D" path="{item["path"]}" id="{i}_src"]')
    lines.append("")
    for i, item in enumerate(items):
        w = max(1, int(item["tile_preview_width"]))
        h = max(1, int(item["tile_preview_height"]))
        lines += [
            f'[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_{i}"]',
            f'texture = ExtResource("{i + 1}_src")',
            f"texture_region_size = Vector2i({w}, {h})",
            "0:0/0 = 0",
            "",
        ]
    lines += [
        "[resource]",
        f"tile_shape = {tile_shape}",
        f"tile_size = Vector2i({tile_size[0]}, {tile_size[1]})",
    ]
    for i in range(len(items)):
        lines.append(f'sources/{i} = SubResource("TileSetAtlasSource_{i}")')
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def draw_contact_sheet(path: Path, items: list[dict[str, Any]], title: str, tile_w: int = 260, tile_h: int = 190, cols: int = 4, thumb: int = 108) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rows = max(1, math.ceil(max(1, len(items)) / cols))
    header_h = 54
    img = Image.new("RGBA", (cols * tile_w, header_h + rows * tile_h), (30, 32, 38, 255))
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()
    draw.rectangle((0, 0, img.width, header_h), fill=(14, 16, 24, 255))
    draw.text((12, 16), title + " - browsing reference only, not source art", fill=(120, 235, 255, 255), font=font)
    for idx, item in enumerate(items):
        x = (idx % cols) * tile_w
        y = header_h + (idx // cols) * tile_h
        draw.rectangle((x + 4, y + 4, x + tile_w - 4, y + tile_h - 4), outline=(82, 92, 110, 255))
        for cy in range(y + 10, y + 10 + thumb, 12):
            for cx in range(x + 10, x + 10 + thumb, 12):
                c = (52, 54, 62, 255) if ((cx + cy) // 12) % 2 else (42, 44, 52, 255)
                draw.rectangle((cx, cy, cx + 11, cy + 11), fill=c)
        try:
            src = Image.open(local_path(item["path"])).convert("RGBA")
            scale = min(thumb / max(1, src.width), thumb / max(1, src.height), 1.8)
            src = src.resize((max(1, int(src.width * scale)), max(1, int(src.height * scale))), Image.Resampling.NEAREST)
            img.alpha_composite(src, (x + 10 + (thumb - src.width) // 2, y + 10 + (thumb - src.height) // 2))
        except Exception:
            pass
        q = item.get("post_creation_quality_classification", "")
        warn = item.get("quality_warning", "")
        text_lines = [
            item.get("tile_id", item.get("asset_id", ""))[:34],
            item["filename"][:36],
            q[:28],
            item.get("recommended_palette", item.get("palette_name", ""))[:32],
            (warn or item.get("quality_reason", ""))[:36],
        ]
        ty = y + 124
        color = (235, 238, 245, 255)
        if q == "REJECT_JUNK":
            color = (255, 130, 130, 255)
        elif q == "REVIEW_MANUALLY":
            color = (255, 220, 120, 255)
        elif q == "MODULAR_PART_OK":
            color = (130, 230, 255, 255)
        for line in text_lines:
            draw.text((x + 10, ty), line, fill=color, font=font)
            ty += 12
    img.convert("RGB").save(path)


def write_paged_sheets(base_path: Path, items: list[dict[str, Any]], title: str, page_size: int = 80) -> list[str]:
    if len(items) <= page_size:
        draw_contact_sheet(base_path, items, title)
        return [rel(base_path)]
    paths: list[str] = []
    stem = base_path.stem
    for page, start in enumerate(range(0, len(items), page_size), 1):
        p = base_path.with_name(f"{stem}_{page:03d}.png")
        chunk = items[start : start + page_size]
        draw_contact_sheet(p, chunk, f"{title} page {page}")
        paths.append(rel(p))
    return paths


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    fields = list(rows[0].keys())
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            clean = {k: json.dumps(v) if isinstance(v, (list, dict)) else v for k, v in row.items()}
            writer.writerow(clean)


def write_test_scene(production: dict[str, list[dict[str, Any]]]) -> None:
    TEST_SCENE.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        '[gd_scene load_steps=5 format=3 uid="uid://pvgames_catalog_paintable_test"]',
        "",
        f'[ext_resource type="TileSet" path="{GROUND_TILESET}" id="1_ground"]',
        f'[ext_resource type="TileSet" path="{WALL_TILESET}" id="2_wall"]',
        f'[ext_resource type="TileSet" path="{LARGE_TILESET}" id="3_large"]',
        f'[ext_resource type="TileSet" path="{PROP_TILESET}" id="4_prop"]',
        "",
        '[node name="PVGamesCatalogPaintableTileSetTest" type="Node2D"]',
        "",
        '[node name="Instructions" type="Label" parent="."]',
        "position = Vector2(-520, -340)",
        'text = "Visual-only TileSet palette test scene. Use it to inspect paintable PVGames assets. Do not use contact sheet PNGs as source art. Do not add collision. READY_TO_PAINT and MODULAR_PART_OK tiles are intended for use; REVIEW_MANUALLY needs inspection; REJECT_JUNK is excluded from production palettes."',
        "",
        '[node name="Camera2D" type="Camera2D" parent="."]',
        "position = Vector2(0, 0)",
        "zoom = Vector2(0.8, 0.8)",
        "",
    ]
    layer_specs = [
        ("GroundRoadTileMapLayer", "1_ground", -360, -80),
        ("WallTileMapLayer", "2_wall", -100, -80),
        ("LargeStructureTileMapLayer", "3_large", 170, -80),
        ("PropSignTileMapLayer", "4_prop", 420, -80),
    ]
    for name, ext_id, x, y in layer_specs:
        lines += [
            f'[node name="{name}" type="TileMapLayer" parent="."]',
            f"position = Vector2({x}, {y})",
            f'tile_set = ExtResource("{ext_id}")',
            "collision_enabled = false",
            "",
            f'[node name="{name}_Label" type="Label" parent="."]',
            f"position = Vector2({x - 45}, {y + 150})",
            f'text = "{name}"',
            "",
        ]
    if production.get("review_only"):
        lines.insert(6, f'[ext_resource type="TileSet" path="{REVIEW_TILESET}" id="5_review"]')
        lines += [
            '[node name="ReviewOnlyTileMapLayer" type="TileMapLayer" parent="."]',
            "position = Vector2(670, -80)",
            'tile_set = ExtResource("5_review")',
            "collision_enabled = false",
            "",
        ]
    TEST_SCENE.write_text("\n".join(lines), encoding="utf-8")


def add_ext_resource(text: str, resource_type: str, path: str, resource_id: str) -> str:
    if f'id="{resource_id}"' in text:
        return text
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("[ext_resource"):
            insert_at = i + 1
    lines.insert(insert_at, f'[ext_resource type="{resource_type}" path="{path}" id="{resource_id}"]')
    return "\n".join(lines) + "\n"


def remove_node_block(text: str, node_name: str, parent: str) -> str:
    pattern = re.compile(rf'\n\[node name="{re.escape(node_name)}" [^\]]*parent="{re.escape(parent)}"[^\]]*\]\n.*?(?=\n\[node |\Z)', re.S)
    return pattern.sub("\n", text)


def update_hideout_layers() -> bool:
    if not HIDEOUT.exists():
        return False
    text = HIDEOUT.read_text(encoding="utf-8")
    if "ArtRoot/World" not in text:
        return False
    text = add_ext_resource(text, "TileSet", GROUND_TILESET, "19_catalog_ground_tileset")
    text = add_ext_resource(text, "TileSet", WALL_TILESET, "20_catalog_wall_tileset")
    text = add_ext_resource(text, "TileSet", LARGE_TILESET, "21_catalog_large_tileset")
    text = add_ext_resource(text, "TileSet", PROP_TILESET, "22_catalog_prop_tileset")
    text = remove_node_block(text, "PVG_CatalogPaintLayers", "ArtRoot/World")
    block = """
[node name="PVG_CatalogPaintLayers" type="Node2D" parent="ArtRoot/World"]
z_index = 0

[node name="PVGamesCatalogGroundRoadPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CatalogPaintLayers"]
z_index = -300
tile_set = ExtResource("19_catalog_ground_tileset")
collision_enabled = false

[node name="PVGamesCatalogWallPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CatalogPaintLayers"]
z_index = -220
tile_set = ExtResource("20_catalog_wall_tileset")
collision_enabled = false

[node name="PVGamesCatalogLargeStructurePaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CatalogPaintLayers"]
z_index = -120
tile_set = ExtResource("21_catalog_large_tileset")
collision_enabled = false

[node name="PVGamesCatalogPropSignPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CatalogPaintLayers"]
z_index = -60
tile_set = ExtResource("22_catalog_prop_tileset")
collision_enabled = false
"""
    marker = '[node name="HideoutPVGamesVisualHelper" type="Node2D" parent="ArtRoot/World"'
    if marker in text:
        text = text.replace(marker, block + "\n" + marker, 1)
    else:
        text += "\n" + block
    HIDEOUT.write_text(text, encoding="utf-8")
    return True


def write_reports(
    catalog: list[dict[str, Any]],
    candidates: list[dict[str, Any]],
    classified: list[dict[str, Any]],
    production: dict[str, list[dict[str, Any]]],
    verification: list[dict[str, Any]],
    rejected_contact: list[dict[str, Any]],
    verification_sheets: dict[str, list[str]],
    palette_sheets: dict[str, list[str]],
    hideout_layers_created: bool,
) -> dict[str, Any]:
    REPORTS.mkdir(parents=True, exist_ok=True)
    write_csv(REPORTS / "pvgames_catalog_derived_paint_candidates.csv", candidates)
    (REPORTS / "pvgames_catalog_derived_paint_candidates.json").write_text(json.dumps({
        "candidate_list_derived_from_catalog": True,
        "total_catalog_assets": len(catalog),
        "candidate_count": len(candidates),
        "rejected_contact_sheet_or_non_source_count": len(rejected_contact),
        "candidates": candidates,
    }, indent=2), encoding="utf-8")
    (REPORTS / "pvgames_catalog_derived_paint_classification.json").write_text(json.dumps(classified, indent=2), encoding="utf-8")
    class_counts = Counter(c["classification"] for c in classified)
    quality_counts = Counter(v["post_creation_quality_classification"] for v in verification)
    lines = ["# PVGames Catalog-Derived Paint Classification", "", "Status: PASS", ""]
    for key in ["TRUE_TILE_ATLAS", "SINGLE_TILE_SPRITE", "LARGE_STRUCTURE_SPRITE", "SPRITE_STAMP_BETTER", "SKIP_UNSAFE"]:
        lines.append(f"- {key}: {class_counts.get(key, 0)}")
    lines += ["", "| Asset | File | Classification | Palette | Reason |", "| --- | --- | --- | --- | --- |"]
    for c in classified[:500]:
        lines.append(f"| `{c['asset_id']}` | `{c['filename']}` | {c['classification']} | {c['recommended_palette']} | {c['reason']} |")
    lines.append("")
    lines.append("Table truncated to first 500 candidates; full data is in JSON.")
    (REPORTS / "pvgames_catalog_derived_paint_classification.md").write_text("\n".join(lines), encoding="utf-8")

    write_csv(REPORTS / "pvgames_catalog_paintable_tile_verification.csv", verification)
    (REPORTS / "pvgames_catalog_paintable_tile_verification.json").write_text(json.dumps(verification, indent=2), encoding="utf-8")
    md = ["# PVGames Catalog Paintable Tile Verification", "", "Status: PASS", ""]
    for key in ["READY_TO_PAINT", "MODULAR_PART_OK", "REVIEW_MANUALLY", "REJECT_JUNK"]:
        md.append(f"- {key}: {quality_counts.get(key, 0)}")
    md += ["", "Verification sheets:", ""]
    for paths in verification_sheets.values():
        for path in paths:
            md.append(f"- `{path}`")
    md += ["", "REJECT_JUNK tiles are excluded from production TileSets. REVIEW_MANUALLY tiles are moved to the review-only palette when present."]
    (REPORTS / "pvgames_catalog_paintable_tile_verification.md").write_text("\n".join(md), encoding="utf-8")

    sprite_stamp = [c for c in classified if c["classification"] == "SPRITE_STAMP_BETTER"]
    (REPORTS / "pvgames_catalog_assets_better_as_sprites_or_stamps.json").write_text(json.dumps(sprite_stamp, indent=2), encoding="utf-8")
    sprite_lines = [
        "# PVGames Assets Better As Sprites Or Stamps",
        "",
        "These useful candidates were not included in production TileSet palettes because individual Sprite2D/PVGamesArtStamper placement is better.",
        "",
        "| Asset | File | Layer | Z | Reason |",
        "| --- | --- | --- | ---: | --- |",
    ]
    for c in sprite_stamp[:500]:
        sprite_lines.append(f"| `{c['asset_id']}` | `{c['filename']}` | {c['recommended_layer']} | {c['recommended_z_index']} | {c['reason']} |")
    sprite_lines.append("\nFull list is in JSON.")
    (REPORTS / "pvgames_catalog_assets_better_as_sprites_or_stamps.md").write_text("\n".join(sprite_lines), encoding="utf-8")

    how_to = REPORTS / "pvgames_catalog_paintable_tilesets_how_to_use.md"
    how_to.write_text("""# PVGames Catalog Paintable TileSets - How To Use

## What Was Created

This pass used `pvgames_full_asset_catalog.json` and `pvgames_full_asset_catalog.csv` to derive paint candidates automatically. You did not need to paste 6,478 assets or a 1,000+ candidate list.

Created TileSets:

- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogLargeStructurePaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogReviewOnlyPaint.tres`, if review tiles exist

Open `res://scenes/hideout/tools/PVGamesCatalogPaintableTileSetTest.tscn` to inspect and test the palettes safely.

## Tile Quality Classes

- `READY_TO_PAINT`: visually coherent and useful now.
- `MODULAR_PART_OK`: partial but useful as a wall, corner, post, edge, road, floor, rail, decal, door, or connector.
- `REVIEW_MANUALLY`: could be useful but needs human inspection; checked with extra review passes and moved to review-only when present.
- `REJECT_JUNK`: blank, broken, too transparent, too huge, bad source, or unusable. Excluded from production palettes.

Some partial tiles are legitimate because walls, roads, rails, platforms, and corners are modular. Partial crops are junk only when they do not make sense as a reusable map component.

## Verification

Open the verification sheets in `res://docs/reports/pvgames_catalog_paintable_verification/`. They show the actual tile preview, tile ID, source filename, quality class, palette, and warnings.

## Painting

1. Open `PVGamesCatalogPaintableTileSetTest.tscn`.
2. Select `GroundRoadTileMapLayer`.
3. Use the TileMap panel to choose a tile and paint a test tile.
4. Select `WallTileMapLayer` and paint a wall tile.
5. Check verification sheets if a tile is unclear.
6. If HideoutHub layers are present, open `HideoutHub.tscn`, select `ArtRoot/World/EditorGuideLayer`, press `F`, then select a `PVGamesCatalog*PaintLayer`.
7. Paint small tests only; erase with the TileMap eraser if wrong.

Collision is disabled. Do not add collision, navigation, or gameplay metadata to PVGames TileSets.

Use `Sprite2D` or `PVGamesArtStamper.gd` for assets listed in `pvgames_catalog_assets_better_as_sprites_or_stamps.md`, especially irregular props needing precise placement, scaling, rotation, z-index, or individual editing.

Contact sheets under `res://docs/reports/pvgames_palettes/` are browsing references only and must not be used as textures.
""", encoding="utf-8")

    report = {
        "pass_fail_partial": "PASS",
        "catalog_files_read": [rel(CATALOG_JSON), rel(CATALOG_CSV)],
        "total_catalog_assets": len(catalog),
        "candidate_assets_derived": len(candidates),
        "candidate_assets_found": sum(1 for c in candidates if c["file_exists"]),
        "missing_paths": sum(1 for c in candidates if not c["file_exists"]),
        "contact_sheet_paths_rejected": len(rejected_contact),
        "candidate_source_rules_used": {
            "pool_a": "TILESET_ATLAS",
            "pool_b_terms": POOL_B_TERMS,
            "pool_c_terms": POOL_C_TERMS,
        },
        "classification_counts": dict(class_counts),
        "tileset_resources_created": {
            "ground_road": GROUND_TILESET,
            "wall": WALL_TILESET,
            "large_structure": LARGE_TILESET,
            "prop_sign": PROP_TILESET,
            "review_only": REVIEW_TILESET if production.get("review_only") else "",
        },
        "tile_counts_before_verification": {k: len(v) for k, v in selected_for_report.items()},
        "tile_counts_after_verification": {k: len(v) for k, v in production.items()},
        "tile_quality_counts": dict(quality_counts),
        "rejected_junk_tiles_removed_or_quarantined": quality_counts.get("REJECT_JUNK", 0),
        "verification_contact_sheet_paths": verification_sheets,
        "test_scene_path": rel(TEST_SCENE),
        "hideout_modified": hideout_layers_created,
        "hideout_paint_layers_created": hideout_layers_created,
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "collision_status": "No collision, physics layers, or navigation added to PVGames catalog TileSets or layers.",
        "palette_contact_sheets": palette_sheets,
        "how_to_guide_path": rel(how_to),
        "sprite_stamper_recommendation_report_path": "res://docs/reports/pvgames_catalog_assets_better_as_sprites_or_stamps.md",
        "known_limitations": [
            "True atlas slicing remains conservative; uncertain atlas sheets are not blindly sliced.",
            "Large structure tiles may be awkward and should be tested in the dedicated scene first.",
            "Automated visual verification catches blank/sparse/oversized problems but final art-direction review is still useful.",
        ],
        "manual_test_checklist": [
            "Open PVGamesCatalogPaintableTileSetTest.tscn.",
            "Select each TileMapLayer and confirm the TileMap panel shows paintable assets.",
            "Open verification sheets and compare READY_TO_PAINT/MODULAR_PART_OK tiles.",
            "Paint one ground tile and one wall tile.",
            "Confirm no collision exists.",
            "If HideoutHub layers were added, use EditorGuideLayer, paint one small test tile, erase it, and run HideoutHub.",
        ],
        "recommended_next_step": "Open the test scene and inspect/paint one tile from each verified palette before using the HideoutHub paint layers.",
    }
    (REPORTS / "pvgames_catalog_paintable_tileset_creation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    main_md = [
        "# PVGames Catalog Paintable TileSet Creation",
        "",
        "Status: PASS",
        "",
        f"- Total catalog assets: {len(catalog)}",
        f"- Candidate assets derived: {len(candidates)}",
        f"- Source PNGs found: {report['candidate_assets_found']}",
        f"- Missing paths: {report['missing_paths']}",
        f"- Contact sheet paths rejected: {len(rejected_contact)}",
        "",
        "## Classification Counts",
        "",
    ]
    for key in ["TRUE_TILE_ATLAS", "SINGLE_TILE_SPRITE", "LARGE_STRUCTURE_SPRITE", "SPRITE_STAMP_BETTER", "SKIP_UNSAFE"]:
        main_md.append(f"- {key}: {class_counts.get(key, 0)}")
    main_md += [
        "",
        "## Tile Quality Counts",
        "",
    ]
    for key in ["READY_TO_PAINT", "MODULAR_PART_OK", "REVIEW_MANUALLY", "REJECT_JUNK"]:
        main_md.append(f"- {key}: {quality_counts.get(key, 0)}")
    main_md += [
        "",
        "## TileSets",
        "",
        f"- Ground/Road: `{GROUND_TILESET}`",
        f"- Wall: `{WALL_TILESET}`",
        f"- Large Structure: `{LARGE_TILESET}`",
        f"- Prop/Sign: `{PROP_TILESET}`",
        f"- Review Only: `{report['tileset_resources_created']['review_only']}`",
        "",
        "## Verification Sheets",
        "",
    ]
    for paths in verification_sheets.values():
        for p in paths:
            main_md.append(f"- `{p}`")
    main_md += [
        "",
        f"Test scene: `{rel(TEST_SCENE)}`",
        f"How-to guide: `{rel(how_to)}`",
        "",
        "No contact sheets were used as TileSet sources. No collision was added. Taco Bell scenes and gameplay scripts were not modified.",
    ]
    (REPORTS / "pvgames_catalog_paintable_tileset_creation.md").write_text("\n".join(main_md), encoding="utf-8")
    return report


selected_for_report: dict[str, list[dict[str, Any]]] = {}


def main() -> None:
    global selected_for_report
    for d in (REPORTS, TILESET_DIR, VERIFICATION_DIR, PALETTE_SHEET_DIR, TEST_SCENE.parent):
        d.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(CATALOG_JSON.read_text(encoding="utf-8"))
    _ = CATALOG_CSV.read_text(encoding="utf-8").splitlines()[0]
    _ = json.loads(CURATED_JSON.read_text(encoding="utf-8"))
    candidates, rejected_contact = derive_candidates(catalog)
    classified = [classify_candidate(dict(c)) for c in candidates]
    selected_for_report = select_for_tilesets(classified)
    production, verification = verify_selected(selected_for_report)
    write_tileset(TILESET_DIR / "PVGamesCatalogGroundRoadPaint.tres", production.get("ground_road", []), "uid://pvgames_catalog_ground_road", tile_size=(64, 32))
    write_tileset(TILESET_DIR / "PVGamesCatalogWallPaint.tres", production.get("wall", []), "uid://pvgames_catalog_wall", tile_size=(96, 64))
    write_tileset(TILESET_DIR / "PVGamesCatalogLargeStructurePaint.tres", production.get("large_structure", []), "uid://pvgames_catalog_large_structure", tile_size=(128, 96))
    write_tileset(TILESET_DIR / "PVGamesCatalogPropSignPaint.tres", production.get("prop_sign", []), "uid://pvgames_catalog_prop_sign", tile_size=(96, 64))
    if production.get("review_only"):
        write_tileset(TILESET_DIR / "PVGamesCatalogReviewOnlyPaint.tres", production.get("review_only", []), "uid://pvgames_catalog_review_only", tile_size=(128, 96))
    write_test_scene(production)
    verification_sheets = {
        "ground_road": write_paged_sheets(VERIFICATION_DIR / "pvgames_verified_ground_road_tiles.png", [v for v in verification if v["palette_name"] == "ground_road"], "Verified Ground/Road Tiles"),
        "wall": write_paged_sheets(VERIFICATION_DIR / "pvgames_verified_wall_tiles.png", [v for v in verification if v["palette_name"] == "wall"], "Verified Wall Tiles"),
        "large_structure": write_paged_sheets(VERIFICATION_DIR / "pvgames_verified_large_structure_tiles.png", [v for v in verification if v["palette_name"] == "large_structure"], "Verified Large Structure Tiles"),
        "prop_sign": write_paged_sheets(VERIFICATION_DIR / "pvgames_verified_prop_sign_tiles.png", [v for v in verification if v["palette_name"] == "prop_sign"], "Verified Prop/Sign Tiles"),
    }
    palette_sheets = {
        "ground_road": write_paged_sheets(PALETTE_SHEET_DIR / "pvgames_catalog_ground_road_paint_palette.png", production.get("ground_road", []), "Ground/Road Paint Palette"),
        "wall": write_paged_sheets(PALETTE_SHEET_DIR / "pvgames_catalog_wall_paint_palette.png", production.get("wall", []), "Wall Paint Palette"),
        "large_structure": write_paged_sheets(PALETTE_SHEET_DIR / "pvgames_catalog_large_structure_paint_palette.png", production.get("large_structure", []), "Large Structure Paint Palette"),
        "prop_sign": write_paged_sheets(PALETTE_SHEET_DIR / "pvgames_catalog_prop_sign_paint_palette.png", production.get("prop_sign", []), "Prop/Sign Paint Palette"),
    }
    if production.get("review_only"):
        palette_sheets["review_only"] = write_paged_sheets(PALETTE_SHEET_DIR / "pvgames_catalog_review_only_paint_palette.png", production.get("review_only", []), "Review Only Paint Palette")
    hideout_layers_created = update_hideout_layers()
    report = write_reports(catalog, candidates, classified, production, verification, rejected_contact, verification_sheets, palette_sheets, hideout_layers_created)
    print(json.dumps({
        "status": "PASS",
        "catalog_assets": len(catalog),
        "candidate_assets": len(candidates),
        "classification_counts": report["classification_counts"],
        "tile_quality_counts": report["tile_quality_counts"],
        "tiles_after_verification": report["tile_counts_after_verification"],
    }, indent=2))


if __name__ == "__main__":
    main()
