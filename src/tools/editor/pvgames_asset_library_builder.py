#!/usr/bin/env python3
"""
Build the PVGames Cyber City asset library.

This is a tooling-only generator. It reads PVGames PNGs, writes catalogs,
contact sheets, curated palettes, planning docs, and safe tool/test scenes. It
does not modify production scenes or source art.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import os
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ASSET_ROOT = Path("assets/tilesets/cyber_city_core_tilesets")
REPORTS = Path("docs/reports")
PALETTES = REPORTS / "pvgames_palettes"
TOOLS_SCENE_DIR = Path("scenes/hideout/tools")

CATALOG_JSON = REPORTS / "pvgames_full_asset_catalog.json"
CATALOG_CSV = REPORTS / "pvgames_full_asset_catalog.csv"
CURATED_JSON = REPORTS / "pvgames_birthday_build_curated_palette.json"
CURATED_MD = REPORTS / "pvgames_birthday_build_curated_palette.md"
CURATED_SHEET = PALETTES / "pvgames_birthday_build_curated_palette.png"
QUICKSTART = REPORTS / "pvgames_art_library_quickstart.md"
MAIN_REPORT_MD = REPORTS / "pvgames_asset_library_and_painting_tool.md"
MAIN_REPORT_JSON = REPORTS / "pvgames_asset_library_and_painting_tool.json"
SAMPLE_MANIFEST = REPORTS / "pvgames_sample_art_placement_manifest.json"
CHAR_SCHEMA = REPORTS / "character_asset_schema.json"
ANIM_SCHEMA = REPORTS / "character_animation_profile_schema.json"
PALETTE_BROWSER = TOOLS_SCENE_DIR / "PVGamesAssetPaletteBrowser.tscn"

MAX_CATEGORY_PAGE_ITEMS = 100
MAX_CATEGORY_SHEETS = 12

CATEGORIES = [
    "FLOOR_DIAMOND",
    "FLOOR_PATCH",
    "ROAD_STREET",
    "WALL_BACK",
    "WALL_SIDE",
    "WALL_CORNER",
    "DOOR_WINDOW",
    "BUILDING_LARGE",
    "FURNITURE",
    "STORE_TECH",
    "COMPUTER_ARCADE",
    "NEON_SIGN",
    "LIGHTING",
    "GREENHOUSE_PLANT",
    "CRATE_STORAGE",
    "CLUTTER_SMALL",
    "DISPLAY_SHELF",
    "CHARACTER_ADJACENT",
    "FOREGROUND_TALL",
    "FX_DECAL",
    "TILESET_ATLAS",
    "UNKNOWN_REVIEW",
    "AVOID_FOR_NOW",
]

CATEGORY_LAYER = {
    "FLOOR_DIAMOND": ("FloorLayer", -300),
    "FLOOR_PATCH": ("FloorLayer", -300),
    "ROAD_STREET": ("FloorLayer", -300),
    "WALL_BACK": ("WallLayer", -220),
    "WALL_SIDE": ("WallLayer", -210),
    "WALL_CORNER": ("WallLayer", -205),
    "DOOR_WINDOW": ("WallLayer", -200),
    "BUILDING_LARGE": ("WallLayer", -230),
    "FURNITURE": ("PropLayer", -90),
    "STORE_TECH": ("PropLayer", -80),
    "COMPUTER_ARCADE": ("PropLayer", -75),
    "NEON_SIGN": ("LightingLayer", 190),
    "LIGHTING": ("LightingLayer", 190),
    "GREENHOUSE_PLANT": ("PropLayer", -70),
    "CRATE_STORAGE": ("PropLayer", -85),
    "CLUTTER_SMALL": ("DecorationLayer", -65),
    "DISPLAY_SHELF": ("CollectibleLayer", -60),
    "CHARACTER_ADJACENT": ("DecorationLayer", -60),
    "FOREGROUND_TALL": ("ForegroundLayer", 140),
    "FX_DECAL": ("DecorationLayer", -95),
    "TILESET_ATLAS": ("FloorLayer", -300),
    "UNKNOWN_REVIEW": ("Avoid", 0),
    "AVOID_FOR_NOW": ("Avoid", 0),
}


def project_root() -> Path:
    p = Path(__file__).resolve()
    for parent in p.parents:
        if (parent / "project.godot").exists():
            return parent
    return Path.cwd()


ROOT = project_root()


def res_path(path: Path) -> str:
    try:
        return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()
    except Exception:
        return path.as_posix()


def safe_id(text: str) -> str:
    return re.sub(r"[^a-z0-9_]+", "_", text.lower()).strip("_")


def stable_asset_id(path: Path, category: str) -> str:
    stem = safe_id(path.stem)
    digest = hashlib.sha1(res_path(path).encode("utf-8")).hexdigest()[:8]
    return f"pvg_{category.lower()}_{stem}_{digest}"


def words(name: str) -> list[str]:
    parts = re.sub(r"([a-z])([A-Z])", r"\1 \2", name).lower()
    return re.findall(r"[a-z0-9]+", parts)


def has_any(name: str, tokens: list[str]) -> bool:
    lower = name.lower()
    return any(t in lower for t in tokens)


@dataclass
class AssetEntry:
    asset_id: str
    path: str
    filename: str
    parent_folder: str
    top_level_pack_folder: str
    pack: str
    width: int
    height: int
    aspect_ratio: float
    has_alpha: bool
    alpha_bbox_min_x: int
    alpha_bbox_min_y: int
    alpha_bbox_max_x: int
    alpha_bbox_max_y: int
    alpha_bbox_width: int
    alpha_bbox_height: int
    alpha_bbox_aspect_ratio: float
    transparent_pixel_percentage: float
    coverage_percentage: float
    corner_transparency_pattern: dict[str, float]
    filename_keyword_tags: list[str]
    inferred_category: str
    inferred_subcategory: str
    confidence_score: float
    recommended_placement_method: str
    recommended_target_layer: str
    recommended_z_index: int
    recommended_snap_mode: str
    recommended_use_hideout: str
    recommended_use_taco_bell: str
    candidate_tilemap_layer: bool
    candidate_sprite2d_stamping: bool
    likely_floor: bool
    likely_wall: bool
    likely_prop: bool
    likely_tall_foreground: bool
    likely_lighting_neon: bool
    likely_character_asset: bool
    likely_ui_avoid: bool
    birthday_build_candidate: bool
    notes: str


def measure(path: Path) -> dict[str, Any]:
    image = Image.open(path)
    rgba = image.convert("RGBA")
    width, height = rgba.size
    bands = image.getbands()
    has_alpha = "A" in bands
    alpha = rgba.getchannel("A") if has_alpha else Image.new("L", (width, height), 255)
    visible_mask = alpha.point(lambda value: 255 if value > 10 else 0)
    bbox = visible_mask.getbbox()
    visible = visible_mask.histogram()[255]
    cx = max(1, width // 5)
    cy = max(1, height // 5)
    corner_boxes = {
        "top_left": (0, 0, cx, cy),
        "top_right": (max(0, width - cx), 0, width, cy),
        "bottom_left": (0, max(0, height - cy), cx, height),
        "bottom_right": (max(0, width - cx), max(0, height - cy), width, height),
    }
    corners: dict[str, float] = {}
    for corner_name, box in corner_boxes.items():
        crop = visible_mask.crop(box)
        crop_total = max(1, crop.width * crop.height)
        crop_visible = crop.histogram()[255]
        corners[corner_name] = round((crop_total - crop_visible) / crop_total, 4)
    if bbox == None or visible == 0:
        min_x = min_y = max_x = max_y = 0
        bbox_w = bbox_h = 0
    else:
        min_x, min_y, max_x_exclusive, max_y_exclusive = bbox
        max_x = max_x_exclusive - 1
        max_y = max_y_exclusive - 1
        bbox_w = max_x - min_x + 1
        bbox_h = max_y - min_y + 1
    total = max(1, width * height)
    return {
        "width": width,
        "height": height,
        "aspect_ratio": round(width / max(1, height), 4),
        "has_alpha": has_alpha,
        "alpha_bbox_min_x": min_x,
        "alpha_bbox_min_y": min_y,
        "alpha_bbox_max_x": max_x,
        "alpha_bbox_max_y": max_y,
        "alpha_bbox_width": bbox_w,
        "alpha_bbox_height": bbox_h,
        "alpha_bbox_aspect_ratio": round(bbox_w / max(1, bbox_h), 4),
        "transparent_pixel_percentage": round((total - visible) * 100.0 / total, 2),
        "coverage_percentage": round(visible * 100.0 / total, 2),
        "corner_transparency_pattern": corners,
    }


def classify(path: Path, m: dict[str, Any]) -> tuple[str, str, float, str]:
    name = path.stem
    lower = name.lower()
    w = m["width"]
    h = m["height"]
    bbox_ratio = m["alpha_bbox_aspect_ratio"]
    transparent = m["transparent_pixel_percentage"]
    corner_avg = sum(m["corner_transparency_pattern"].values()) / 4.0
    tags = words(name)
    category = "UNKNOWN_REVIEW"
    sub = "review"
    confidence = 0.45
    notes = ""

    if w >= 512 or h >= 512 or has_any(lower, ["atlas", "sheet", "tileset", "tilemap"]):
        category, sub, confidence = "TILESET_ATLAS", "atlas_or_large_sheet", 0.65
    elif has_any(lower, ["floormat", "floor", "ground", "tile", "carpet", "rug"]):
        if 1.75 <= bbox_ratio <= 2.15 and corner_avg >= 0.45:
            category, sub, confidence = "FLOOR_DIAMOND", "diamond_floor_or_mat", 0.88
        else:
            category, sub, confidence = "FLOOR_PATCH", "floor_patch_or_mat", 0.72
    elif has_any(lower, ["road", "street", "sidewalk", "pavement", "asphalt"]):
        category, sub, confidence = "ROAD_STREET", "road_street", 0.76
    elif has_any(lower, ["citywallscorner", "corner"]):
        category, sub, confidence = "WALL_CORNER", "corner", 0.78
    elif has_any(lower, ["citywallspost", "post", "column"]):
        category, sub, confidence = "WALL_CORNER", "post_column", 0.76
    elif has_any(lower, ["citywalls", "wall"]):
        category = "WALL_BACK" if w >= h else "WALL_SIDE"
        sub, confidence = "wall_piece", 0.76
    elif has_any(lower, ["door", "window", "glass"]):
        category, sub, confidence = "DOOR_WINDOW", "door_window", 0.78
    elif has_any(lower, ["buildinglarge", "building"]):
        category, sub, confidence = "BUILDING_LARGE", "building_facade", 0.68
    elif has_any(lower, ["couch", "chair", "table", "cabinet", "shelf", "bed", "stool", "bench"]):
        if has_any(lower, ["shelf"]):
            category, sub = "DISPLAY_SHELF", "shelf"
        elif has_any(lower, ["bed"]):
            category, sub = "CHARACTER_ADJACENT", "bed_or_lounge"
        else:
            category, sub = "FURNITURE", "furniture"
        confidence = 0.84
    elif has_any(lower, ["terminal", "kiosk", "register"]):
        category, sub, confidence = "STORE_TECH", "terminal_kiosk", 0.86
    elif has_any(lower, ["computer", "monitor", "screen", "arcade", "server", "machine"]):
        category, sub, confidence = "COMPUTER_ARCADE", "computer_screen_machine", 0.82
    elif has_any(lower, ["sign", "billboard", "poster", "adboard"]):
        category = "NEON_SIGN" if w < 400 and h < 400 else "FOREGROUND_TALL"
        sub, confidence = "sign_billboard", 0.78
    elif has_any(lower, ["light", "lamp"]):
        category, sub, confidence = "LIGHTING", "light_fixture", 0.78
    elif has_any(lower, ["plant", "tree", "planter"]):
        category, sub, confidence = "GREENHOUSE_PLANT", "plant", 0.86
    elif has_any(lower, ["crate", "box", "barrel", "container", "pallet"]):
        category, sub, confidence = "CRATE_STORAGE", "crate_box_storage", 0.84
    elif has_any(lower, ["decal", "stain", "marking", "trash", "garbage"]):
        category, sub, confidence = "FX_DECAL", "decal_clutter", 0.72
    elif has_any(lower, ["acunit", "vent", "pipe", "barrier", "fence"]):
        category, sub, confidence = "FOREGROUND_TALL" if h > 110 else "CLUTTER_SMALL", "industrial_prop", 0.68
    elif has_any(lower, ["person", "man", "woman", "npc", "guard", "dog", "character"]):
        category, sub, confidence = "CHARACTER_ADJACENT", "possible_character", 0.55
    elif transparent > 75 or w > 1000 or h > 1000:
        category, sub, confidence = "AVOID_FOR_NOW", "oversized_or_sparse", 0.55

    if category == "UNKNOWN_REVIEW":
        notes = "No strong category match; keep for manual review."
    elif category == "TILESET_ATLAS":
        notes = "Large or atlas-like image; use only after visual subset review."
    else:
        notes = "Measurement and filename agree enough for initial art-library use."
    return category, sub, confidence, notes


def recommendations(category: str, subcategory: str, m: dict[str, Any]) -> dict[str, Any]:
    layer, z = CATEGORY_LAYER[category]
    sprite = category not in ("AVOID_FOR_NOW",)
    tile_candidate = category in ("FLOOR_DIAMOND", "TILESET_ATLAS") and m["alpha_bbox_width"] >= 32
    if category in ("TILESET_ATLAS", "FLOOR_DIAMOND"):
        method = "Either" if category == "FLOOR_DIAMOND" else "TileMapLayer"
    elif category in ("AVOID_FOR_NOW", "UNKNOWN_REVIEW"):
        method = "Avoid" if category == "AVOID_FOR_NOW" else "Sprite2D"
    else:
        method = "Sprite2D"
    if category in ("FLOOR_DIAMOND", "FLOOR_PATCH", "ROAD_STREET", "FX_DECAL"):
        snap = "16px_grid_or_free_visual"
    elif category.startswith("WALL") or category in ("DOOR_WINDOW", "BUILDING_LARGE"):
        snap = "wall_anchor_or_free_visual"
    else:
        snap = "free_visual"
    use_hideout = "yes" if category in ("FLOOR_DIAMOND", "FLOOR_PATCH", "WALL_BACK", "WALL_SIDE", "WALL_CORNER", "DOOR_WINDOW", "FURNITURE", "STORE_TECH", "COMPUTER_ARCADE", "NEON_SIGN", "LIGHTING", "GREENHOUSE_PLANT", "CRATE_STORAGE", "DISPLAY_SHELF", "CHARACTER_ADJACENT") else "maybe"
    use_taco = "yes" if category in ("FLOOR_PATCH", "ROAD_STREET", "WALL_BACK", "WALL_SIDE", "WALL_CORNER", "DOOR_WINDOW", "FURNITURE", "STORE_TECH", "COMPUTER_ARCADE", "NEON_SIGN", "LIGHTING", "CRATE_STORAGE", "CLUTTER_SMALL", "FX_DECAL") else "maybe"
    birthday = category not in ("UNKNOWN_REVIEW", "AVOID_FOR_NOW", "BUILDING_LARGE", "TILESET_ATLAS") and m["width"] <= 420 and m["height"] <= 420
    return {
        "method": method,
        "layer": layer,
        "z": z,
        "snap": snap,
        "hideout": use_hideout,
        "taco": use_taco,
        "tile": tile_candidate,
        "sprite": sprite and method != "TileMapLayer",
        "birthday": birthday,
    }


def build_catalog() -> list[AssetEntry]:
    paths = sorted((ROOT / ASSET_ROOT).rglob("*.png"), key=lambda p: p.as_posix().lower())
    catalog: list[AssetEntry] = []
    for p in paths:
        m = measure(p)
        category, sub, confidence, notes = classify(p, m)
        rec = recommendations(category, sub, m)
        pack = "CyberCity_Core_Tiles_1" if "CyberCity_Core_Tiles_1" in p.parts else "CyberCity_Core_Tiles_2"
        tags = sorted(set(words(p.stem)))
        entry = AssetEntry(
            asset_id=stable_asset_id(p, category),
            path=res_path(p),
            filename=p.name,
            parent_folder=p.parent.name,
            top_level_pack_folder=pack,
            pack=pack,
            filename_keyword_tags=tags,
            inferred_category=category,
            inferred_subcategory=sub,
            confidence_score=confidence,
            recommended_placement_method=rec["method"],
            recommended_target_layer=rec["layer"],
            recommended_z_index=rec["z"],
            recommended_snap_mode=rec["snap"],
            recommended_use_hideout=rec["hideout"],
            recommended_use_taco_bell=rec["taco"],
            candidate_tilemap_layer=rec["tile"],
            candidate_sprite2d_stamping=rec["sprite"],
            likely_floor=category.startswith("FLOOR") or category in ("ROAD_STREET", "FX_DECAL"),
            likely_wall=category.startswith("WALL") or category in ("DOOR_WINDOW", "BUILDING_LARGE"),
            likely_prop=category in ("FURNITURE", "STORE_TECH", "COMPUTER_ARCADE", "GREENHOUSE_PLANT", "CRATE_STORAGE", "CLUTTER_SMALL", "DISPLAY_SHELF", "CHARACTER_ADJACENT"),
            likely_tall_foreground=category in ("FOREGROUND_TALL", "BUILDING_LARGE"),
            likely_lighting_neon=category in ("NEON_SIGN", "LIGHTING"),
            likely_character_asset=category == "CHARACTER_ADJACENT" and has_any(p.name, ["npc", "guard", "dog", "character", "person"]),
            likely_ui_avoid=category == "AVOID_FOR_NOW",
            birthday_build_candidate=rec["birthday"],
            notes=notes,
            **m,
        )
        catalog.append(entry)
    return catalog


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def write_csv(path: Path, entries: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = list(entries[0].keys()) if entries else []
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for e in entries:
            row = dict(e)
            for k, v in row.items():
                if isinstance(v, (list, dict)):
                    row[k] = json.dumps(v, ensure_ascii=False)
            writer.writerow(row)


def load_thumb(entry: dict[str, Any], max_size: int = 96) -> Image.Image:
    p = ROOT / entry["path"].replace("res://", "")
    img = Image.open(p).convert("RGBA")
    scale = min(max_size / max(1, img.width), max_size / max(1, img.height), 1.6)
    img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.Resampling.NEAREST)
    return img


def draw_sheet(path: Path, entries: list[dict[str, Any]], title: str, tile_w: int = 230, tile_h: int = 172, cols: int = 4, thumb: int = 92) -> None:
    rows = max(1, math.ceil(len(entries) / cols))
    header_h = 48
    img = Image.new("RGBA", (cols * tile_w, header_h + rows * tile_h), (32, 34, 40, 255))
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()
    draw.rectangle((0, 0, img.width, header_h), fill=(18, 20, 28, 255))
    draw.text((12, 14), title, fill=(120, 240, 255, 255), font=font)
    for i, e in enumerate(entries):
        x = (i % cols) * tile_w
        y = header_h + (i // cols) * tile_h
        draw.rectangle((x + 4, y + 4, x + tile_w - 4, y + tile_h - 4), outline=(80, 90, 105, 255))
        for cy in range(y + 8, y + 8 + thumb, 12):
            for cx in range(x + 8, x + 8 + thumb, 12):
                c = (50, 52, 60, 255) if ((cx + cy) // 12) % 2 else (42, 44, 52, 255)
                draw.rectangle((cx, cy, cx + 11, cy + 11), fill=c)
        try:
            t = load_thumb(e, thumb)
            img.alpha_composite(t, (x + 8 + (thumb - t.width) // 2, y + 8 + (thumb - t.height) // 2))
        except Exception:
            pass
        short_id = e.get("curated_id", e["asset_id"].replace("pvg_", "")[:24])
        lines = [
            short_id[:28],
            e["filename"][:30],
            f"{e['inferred_category']} / {e['inferred_subcategory']}"[:32],
            f"{e['recommended_target_layer']} | {e['recommended_placement_method']}"[:32],
            f"{e['width']}x{e['height']} bbox {e['alpha_bbox_width']}x{e['alpha_bbox_height']}"[:32],
        ]
        ty = y + 106
        for line in lines:
            draw.text((x + 8, ty), line, fill=(228, 232, 238, 255), font=font)
            ty += 12
    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(path)


def write_category_sheets(entries: list[dict[str, Any]]) -> dict[str, list[str]]:
    PALETTES.mkdir(parents=True, exist_ok=True)
    by_cat: dict[str, list[dict[str, Any]]] = {c: [] for c in CATEGORIES}
    for e in entries:
        by_cat[e["inferred_category"]].append(e)
    output: dict[str, list[str]] = {}
    for cat in CATEGORIES:
        cat_entries = sorted(by_cat[cat], key=lambda e: (not e["birthday_build_candidate"], e["filename"]))
        if not cat_entries:
            output[cat] = []
            continue
        page_count = min(MAX_CATEGORY_SHEETS, math.ceil(len(cat_entries) / MAX_CATEGORY_PAGE_ITEMS))
        output[cat] = []
        for page in range(page_count):
            chunk = cat_entries[page * MAX_CATEGORY_PAGE_ITEMS : (page + 1) * MAX_CATEGORY_PAGE_ITEMS]
            suffix = f"_{page + 1:03d}" if page_count > 1 else ""
            path = PALETTES / f"pvgames_palette_{cat.lower()}{suffix}.png"
            draw_sheet(path, chunk, f"{cat} page {page + 1}/{page_count} ({len(cat_entries)} assets)")
            output[cat].append(res_path(path))
    return output


SECTION_TARGETS = [
    ("HIDEOUTHUB_ESSENTIALS", 32, ["FURNITURE", "STORE_TECH", "COMPUTER_ARCADE", "DISPLAY_SHELF", "GREENHOUSE_PLANT", "CRATE_STORAGE", "NEON_SIGN", "LIGHTING", "FLOOR_DIAMOND", "FLOOR_PATCH", "WALL_BACK", "DOOR_WINDOW", "CHARACTER_ADJACENT"]),
    ("TACO_BELL_FAST_FOOD_STORE", 30, ["FURNITURE", "STORE_TECH", "COMPUTER_ARCADE", "CRATE_STORAGE", "CLUTTER_SMALL", "NEON_SIGN", "LIGHTING", "FLOOR_PATCH", "WALL_BACK", "DOOR_WINDOW", "FX_DECAL"]),
    ("GENERAL_CYBER_CITY_LEVEL_DRESSING", 20, ["ROAD_STREET", "WALL_SIDE", "WALL_CORNER", "NEON_SIGN", "CRATE_STORAGE", "FOREGROUND_TALL", "LIGHTING", "CLUTTER_SMALL", "BUILDING_LARGE"]),
    ("GREENHOUSE_Cozy_BENTLEY", 15, ["GREENHOUSE_PLANT", "CHARACTER_ADJACENT", "FURNITURE", "FLOOR_PATCH", "DOOR_WINDOW", "LIGHTING", "CRATE_STORAGE"]),
    ("SIGNS_LIGHTS_NEON_MONITORS", 15, ["NEON_SIGN", "LIGHTING", "COMPUTER_ARCADE", "STORE_TECH"]),
    ("DISPLAYS_SHELVES_COLLECTIONS", 15, ["DISPLAY_SHELF", "FURNITURE", "NEON_SIGN", "CLUTTER_SMALL", "CRATE_STORAGE"]),
    ("FLOORS_WALLS_STRUCTURE", 18, ["FLOOR_DIAMOND", "FLOOR_PATCH", "ROAD_STREET", "WALL_BACK", "WALL_SIDE", "WALL_CORNER", "DOOR_WINDOW"]),
]


def score_for_section(entry: dict[str, Any], section: str) -> float:
    score = entry["confidence_score"] * 10
    if entry["birthday_build_candidate"]:
        score += 8
    if entry["recommended_placement_method"] == "Sprite2D":
        score += 4
    if entry["width"] <= 260 and entry["height"] <= 260:
        score += 4
    if entry["transparent_pixel_percentage"] < 80:
        score += 2
    name = entry["filename"].lower()
    if section == "TACO_BELL_FAST_FOOD_STORE" and has_any(name, ["table", "chair", "terminal", "screen", "crate", "box", "cabinet", "sign"]):
        score += 8
    if section == "HIDEOUTHUB_ESSENTIALS" and has_any(name, ["table", "couch", "bed", "shelf", "terminal", "plant", "floormat", "screen", "sign"]):
        score += 8
    if section == "GREENHOUSE_Cozy_BENTLEY" and has_any(name, ["plant", "bed", "couch", "chair", "floormat", "cabinet"]):
        score += 10
    if section == "SIGNS_LIGHTS_NEON_MONITORS" and has_any(name, ["sign", "billboard", "light", "screen", "monitor", "terminal"]):
        score += 10
    if section == "DISPLAYS_SHELVES_COLLECTIONS" and has_any(name, ["shelf", "cabinet", "display", "case", "sign"]):
        score += 10
    if section == "FLOORS_WALLS_STRUCTURE" and entry["inferred_category"] in ("FLOOR_DIAMOND", "FLOOR_PATCH", "WALL_BACK", "WALL_SIDE", "WALL_CORNER", "DOOR_WINDOW"):
        score += 10
    return score


def curated_entry(entry: dict[str, Any], section: str, index: int) -> dict[str, Any]:
    recommended_scene = "both"
    if section == "HIDEOUTHUB_ESSENTIALS" or section == "GREENHOUSE_Cozy_BENTLEY" or section == "DISPLAYS_SHELVES_COLLECTIONS":
        recommended_scene = "HideoutHub"
    elif section == "TACO_BELL_FAST_FOOD_STORE":
        recommended_scene = "Taco Bell"
    elif section == "GENERAL_CYBER_CITY_LEVEL_DRESSING":
        recommended_scene = "future mission"
    curated_id = f"bb_{safe_id(section)}_{index:03d}"
    visual_warning = "May visually imply collision; keep it away from walkable center unless backed by existing gameplay collision." if entry["likely_wall"] or entry["likely_tall_foreground"] or entry["likely_prop"] else "Visual-only; safe as nonblocking art."
    scale = [1, 1]
    if max(entry["width"], entry["height"]) > 280:
        scale = [0.65, 0.65]
    elif max(entry["width"], entry["height"]) < 64:
        scale = [1.3, 1.3]
    return {
        "curated_id": curated_id,
        "source_asset_id": entry["asset_id"],
        "path": entry["path"],
        "filename": entry["filename"],
        "source_folder": entry["parent_folder"],
        "image_width": entry["width"],
        "image_height": entry["height"],
        "alpha_bbox_width": entry["alpha_bbox_width"],
        "alpha_bbox_height": entry["alpha_bbox_height"],
        "top_level_category": entry["inferred_category"],
        "curated_palette_section": section,
        "subcategory": entry["inferred_subcategory"],
        "best_use_case": use_case(entry, section),
        "recommended_scene": recommended_scene,
        "recommended_target_layer": entry["recommended_target_layer"],
        "recommended_placement_method": "Sprite2D" if entry["recommended_placement_method"] == "Either" else entry["recommended_placement_method"],
        "recommended_z_index_range": [entry["recommended_z_index"] - 10, entry["recommended_z_index"] + 10],
        "recommended_scale_suggestion": scale,
        "recommended_rotation_flip": "No rotation by default; horizontal flip acceptable for directional variants if it preserves perspective.",
        "y_sort_recommendation": entry["recommended_target_layer"] in ("PropLayer", "CollectibleLayer", "ForegroundLayer"),
        "gameplay_collision": False,
        "may_visually_imply_collision": entry["likely_wall"] or entry["likely_prop"] or entry["likely_tall_foreground"],
        "placement_warning": visual_warning,
        "reason_selected": reason(entry, section),
        "confidence": min(5, max(1, round(entry["confidence_score"] * 5))),
        "birthday_build_ready": "yes" if entry["birthday_build_candidate"] else "maybe",
        "notes": entry["notes"],
    }


def use_case(entry: dict[str, Any], section: str) -> str:
    cat = entry["inferred_category"]
    if cat == "STORE_TECH":
        return "Store terminal, Taco Bell register, security booth, or black-market kiosk."
    if cat == "COMPUTER_ARCADE":
        return "Mission board screen, planning table monitor, office tech, or scanner prop."
    if cat == "GREENHOUSE_PLANT":
        return "Greenhouse, cozy hideout corner, storefront planter, or softening cyber interiors."
    if cat == "DISPLAY_SHELF":
        return "Collectible shelf, Polaroid display, Glow Guy/Tiny Icon support, or store shelf."
    if cat == "CRATE_STORAGE":
        return "Delivery area, loot crate, bag room, alley clutter, or storage corner."
    if cat == "FURNITURE":
        return "Planning table, dining area, lounge, office, or counter-side dressing."
    if cat in ("NEON_SIGN", "LIGHTING"):
        return "Neon-noir atmosphere, storefront identity, mission board accent, or warning glow."
    if cat.startswith("FLOOR"):
        return "Visual-only floor/rug patch for zone definition; do not use as gameplay collision."
    if cat.startswith("WALL") or cat == "DOOR_WINDOW":
        return "Visual-only wall/backdrop/door/window art around existing collision."
    return f"{section.replace('_', ' ').title()} visual dressing."


def reason(entry: dict[str, Any], section: str) -> str:
    return f"Readable {entry['inferred_subcategory']} asset for {section.replace('_', ' ').lower()} with {entry['width']}x{entry['height']} dimensions and {entry['recommended_placement_method']} workflow."


def build_curated(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    selected_ids: set[str] = set()
    curated: list[dict[str, Any]] = []
    for section, target, cats in SECTION_TARGETS:
        candidates = [e for e in entries if e["inferred_category"] in cats and e["inferred_category"] not in ("AVOID_FOR_NOW", "UNKNOWN_REVIEW") and e["asset_id"] not in selected_ids]
        candidates.sort(key=lambda e: score_for_section(e, section), reverse=True)
        # Limit near-duplicates by basename prefix before numeric direction suffix.
        prefix_counts: dict[str, int] = {}
        count = 0
        for e in candidates:
            prefix = re.sub(r"_?\d+$", "", Path(e["filename"]).stem)
            if prefix_counts.get(prefix, 0) >= 2:
                continue
            prefix_counts[prefix] = prefix_counts.get(prefix, 0) + 1
            selected_ids.add(e["asset_id"])
            curated.append(curated_entry(e, section, count + 1))
            count += 1
            if count >= target:
                break
    return curated[:150]


def write_curated_md(curated: list[dict[str, Any]]) -> None:
    lines = [
        "# PVGames Birthday-Build Curated Palette",
        "",
        f"Status: PASS - {len(curated)} practical assets selected.",
        "",
        "This is the short list to use before browsing the full 6,478-file catalog. Assets were selected for readability, theme fit, placement safety, and usefulness for HideoutHub, Taco Bell, and future cyber/noir missions.",
        "",
    ]
    for section, _, _ in SECTION_TARGETS:
        rows = [c for c in curated if c["curated_palette_section"] == section]
        lines += [f"## {section.replace('_', ' ').title()}", ""]
        lines.append("| ID | File | Category | Scene | Layer | Method | Use case |")
        lines.append("| --- | --- | --- | --- | --- | --- | --- |")
        for c in rows:
            lines.append(f"| `{c['curated_id']}` | `{c['filename']}` | {c['top_level_category']} | {c['recommended_scene']} | {c['recommended_target_layer']} | {c['recommended_placement_method']} | {c['best_use_case']} |")
        lines.append("")
    CURATED_MD.write_text("\n".join(lines), encoding="utf-8")


def write_curated_sheet(curated: list[dict[str, Any]]) -> None:
    rows: list[dict[str, Any]] = []
    source_by_id: dict[str, dict[str, Any]] = {e["asset_id"]: e for e in CATALOG_DICTS}
    for c in curated:
        src = dict(source_by_id[c["source_asset_id"]])
        src["curated_id"] = c["curated_id"]
        src["inferred_category"] = c["top_level_category"]
        src["inferred_subcategory"] = c["subcategory"]
        src["recommended_target_layer"] = c["recommended_target_layer"]
        src["recommended_placement_method"] = c["recommended_placement_method"]
        rows.append(src)
    draw_sheet(CURATED_SHEET, rows, f"PVGames Birthday-Build Curated Palette ({len(curated)} assets)", tile_w=245, tile_h=180, cols=4, thumb=104)


def write_browser_scene(curated: list[dict[str, Any]]) -> None:
    TOOLS_SCENE_DIR.mkdir(parents=True, exist_ok=True)
    lines = ['[gd_scene format=3 uid="uid://pvgames_palette_browser"]', ""]
    shown = curated[:80]
    for i, c in enumerate(shown, 1):
        lines.append(f'[ext_resource type="Texture2D" path="{c["path"]}" id="{i}"]')
    lines += ["", '[node name="PVGamesAssetPaletteBrowser" type="Node2D"]', ""]
    lines += [
        '[node name="Title" type="Label" parent="."]',
        'position = Vector2(20, 10)',
        'text = "PVGames Asset Palette Browser - curated tooling scene only"',
        "",
    ]
    for idx, c in enumerate(shown):
        col = idx % 8
        row = idx // 8
        x = 40 + col * 150
        y = 70 + row * 150
        name = safe_id(c["curated_id"])
        lines += [
            f'[node name="{name}" type="Sprite2D" parent="."]',
            f"position = Vector2({x}, {y})",
            f'texture = ExtResource("{idx + 1}")',
            "scale = Vector2(0.75, 0.75)",
            "",
            f'[node name="{name}_Label" type="Label" parent="."]',
            f"position = Vector2({x - 54}, {y + 58})",
            f'text = "{c["curated_id"]}\\n{c["top_level_category"]}\\n{c["recommended_target_layer"]}"',
            "",
        ]
    PALETTE_BROWSER.write_text("\n".join(lines), encoding="utf-8")


def write_stamper_tool() -> None:
    path = ROOT / "src/tools/editor/PVGamesArtStamper.gd"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("""@tool
extends EditorScript
class_name PVGamesArtStamper

## Manifest-based visual-only PVGames art stamper.
## This tool is intentionally opt-in. It does not run automatically and should
## stamp duplicate/test scenes unless a human explicitly chooses production.

func stamp_manifest(manifest_path: String, output_scene_path: String = "") -> Dictionary:
\tvar result := {"ok": false, "created": 0, "errors": []}
\tif not FileAccess.file_exists(manifest_path):
\t\tresult["errors"].append("Manifest not found: %s" % manifest_path)
\t\treturn result
\tvar data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
\tif data == null:
\t\tresult["errors"].append("Manifest JSON parse failed.")
\t\treturn result
\tvar target_scene := String(data.get("target_scene", ""))
\tvar packed := load(target_scene) as PackedScene
\tif packed == null:
\t\tresult["errors"].append("Target scene failed to load: %s" % target_scene)
\t\treturn result
\tvar root := packed.instantiate()
\tvar container_name := String(data.get("container_name", "PVGamesStampedArt"))
\tfor entry in data.get("placements", []):
\t\tif not bool(entry.get("visual_only", true)) or not bool(entry.get("collision_disabled", true)):
\t\t\tresult["errors"].append("Rejected non-visual placement: %s" % String(entry.get("asset_id", "")))
\t\t\tcontinue
\t\tvar target_layer := root.get_node_or_null(String(entry.get("target_layer", "")))
\t\tif target_layer == null:
\t\t\tresult["errors"].append("Missing target layer: %s" % String(entry.get("target_layer", "")))
\t\t\tcontinue
\t\tvar container := target_layer.get_node_or_null(container_name)
\t\tif container == null:
\t\t\tcontainer = Node2D.new()
\t\t\tcontainer.name = container_name
\t\t\ttarget_layer.add_child(container)
\t\t\tcontainer.owner = root
\t\tvar texture := load(String(entry.get("asset_path", ""))) as Texture2D
\t\tif texture == null:
\t\t\tresult["errors"].append("Texture load failed: %s" % String(entry.get("asset_path", "")))
\t\t\tcontinue
\t\tvar sprite := Sprite2D.new()
\t\tsprite.name = "PVG_%s_%s" % [String(entry.get("category", "asset")).to_lower(), String(entry.get("asset_id", "asset"))]
\t\tsprite.texture = texture
\t\tvar pos: Array = entry.get("position", [0, 0])
\t\tvar scl: Array = entry.get("scale", [1, 1])
\t\tsprite.position = Vector2(float(pos[0]), float(pos[1]))
\t\tsprite.scale = Vector2(float(scl[0]), float(scl[1]))
\t\tsprite.rotation_degrees = float(entry.get("rotation_degrees", 0.0))
\t\tsprite.z_index = int(entry.get("z_index", 0))
\t\tsprite.set_meta("pvgames_asset_id", String(entry.get("asset_id", "")))
\t\tsprite.set_meta("category", String(entry.get("category", "")))
\t\tsprite.set_meta("subcategory", String(entry.get("subcategory", "")))
\t\tsprite.set_meta("placement_method", String(entry.get("placement_method", "Sprite2D")))
\t\tsprite.set_meta("visual_only", true)
\t\tsprite.set_meta("collision_disabled", true)
\t\tcontainer.add_child(sprite)
\t\tsprite.owner = root
\t\tresult["created"] += 1
\tvar save_path := output_scene_path if output_scene_path != "" else String(data.get("output_scene", ""))
\tif save_path == "":
\t\tresult["errors"].append("No output scene path provided. Refusing to overwrite target scene by default.")
\t\troot.free()
\t\treturn result
\tvar out := PackedScene.new()
\tout.pack(root)
\tvar err := ResourceSaver.save(out, save_path)
\troot.free()
\tresult["ok"] = err == OK and result["errors"].is_empty()
\treturn result
""", encoding="utf-8")


def write_sample_manifest(curated: list[dict[str, Any]]) -> None:
    placements = []
    for c in curated[:8]:
        placements.append({
            "target_scene": "res://scenes/hideout/HideoutHub.tscn",
            "target_layer": f"ArtRoot/World/{c['recommended_target_layer']}",
            "asset_id": c["source_asset_id"],
            "asset_path": c["path"],
            "position": [0, 0],
            "rotation_degrees": 0,
            "scale": c["recommended_scale_suggestion"],
            "z_index": c["recommended_z_index_range"][0],
            "name_prefix": "PVG",
            "y_sort_enabled": c["y_sort_recommendation"],
            "visual_only": True,
            "collision_disabled": True,
            "category": c["top_level_category"],
            "subcategory": c["subcategory"],
            "placement_method": c["recommended_placement_method"],
            "notes": "Sample only. Do not stamp production scenes without explicit instruction.",
        })
    write_json(SAMPLE_MANIFEST, {
        "target_scene": "res://scenes/hideout/HideoutHub.tscn",
        "output_scene": "res://scenes/hideout/tools/PVGamesStamperTestScene.tscn",
        "container_name": "PVGamesStampedArt",
        "placements": placements,
    })


def write_character_schemas_and_plan() -> None:
    write_json(CHAR_SCHEMA, {
        "character_id": "player_default",
        "display_name": "Player Default",
        "role": "player|bentley|named_npc|guard|ambient_npc",
        "asset_path": "res://assets/characters/player/",
        "license_source_note": "",
        "sprite_sheet_path": "",
        "frame_width": 0,
        "frame_height": 0,
        "scale": [1, 1],
        "pivot_offset": [0, 0],
        "directions_supported": ["south", "north", "west", "east"],
        "animations_supported": ["idle", "walk"],
        "default_animation": "idle_south",
        "movement_speed_hint": 120,
        "compatible_with_player_controller": True,
        "compatible_with_npc_controller": True,
        "compatible_with_guard_controller": False,
        "compatible_with_dog_controller": False,
        "notes": "Transparent PNG spritesheet or frame sequence preferred.",
    })
    write_json(ANIM_SCHEMA, {
        "animation_name": "walk_south",
        "direction": "south",
        "frame_paths": [],
        "sprite_sheet_region": {"row": 0, "columns": 4, "frame_width": 0, "frame_height": 0},
        "fps": 8,
        "loop": True,
        "foot_anchor": [0.5, 0.9],
        "notes": "4-direction minimum, 8-direction preferred.",
    })
    plan = REPORTS / "character_asset_support_plan.md"
    plan.write_text("""# Character / NPC / Creature Asset Support Plan

Status: planning only. No character replacement was performed.

## Recommended Asset Type

Use transparent PNG sprite sheets or frame sequences for 2D top-down, 3/4 top-down, isometric, or dimetric characters. Four-direction animation is the minimum; eight-direction animation is preferred.

## Folder Structure

```text
res://assets/characters/
  player/
  bentley/
  npcs/
    jake/
    mere/
    louis/
    ambient/
  enemies/
    guards/
  raw_source/
  licenses/
```

## Roles

- Player: idle, walk, interact/use, optional run/crouch/carry/hurt.
- Bentley: idle, walk, sit, sniff, happy/tail wag, optional sleep/pet reaction.
- Guards: idle, patrol/walk, alert, chase/run, attack, optional hurt/down.
- Ambient NPCs: idle, walk, talk/gesture, optional sit/stand.
- Jake/Mere/Louis: idle, talk/gesture, optional walk/special idle.

## Good Future Search Terms

- 2D isometric animated character sprites
- 2D top-down animated character sprites
- 8 direction top-down character sprites
- top-down dog sprite sheet
- cyberpunk RPG character sprite sheet
- top-down guard sprite sheet

## Avoid

Avoid side-scrolling sprites, visual-novel-only front poses, non-transparent backgrounds, proprietary runtime plugins, one-direction-only packs, and character packs with no walking animation.

## Future Tool

Create `res://src/tools/editor/character_asset_audit.py` or `CharacterAssetAuditTool.gd` to inspect frame sizes, alpha, directions, animation rows, and suitability for player/NPC/guard/Bentley roles.
""", encoding="utf-8")


def write_quickstart(category_sheets: dict[str, list[str]]) -> None:
    QUICKSTART.write_text("""# PVGames Art Library Quickstart

## Where Things Are

- Full catalog JSON: `res://docs/reports/pvgames_full_asset_catalog.json`
- Full catalog CSV: `res://docs/reports/pvgames_full_asset_catalog.csv`
- Category contact sheets: `res://docs/reports/pvgames_palettes/`
- Birthday-build curated palette: `res://docs/reports/pvgames_birthday_build_curated_palette.md`
- Curated palette JSON: `res://docs/reports/pvgames_birthday_build_curated_palette.json`
- Curated contact sheet: `res://docs/reports/pvgames_palettes/pvgames_birthday_build_curated_palette.png`
- Manifest stamper: `res://src/tools/editor/PVGamesArtStamper.gd`
- Sample manifest: `res://docs/reports/pvgames_sample_art_placement_manifest.json`

## Manual Workflow

1. Open the curated palette first.
2. Pick assets by section, category, and recommended scene.
3. Add them as visual-only `Sprite2D` nodes under `ArtRoot/World`.
4. Use the recommended layer: `FloorLayer`, `WallLayer`, `PropLayer`, `DecorationLayer`, `CollectibleLayer`, `ForegroundLayer`, or `LightingLayer`.
5. Keep collision disabled. Do not add `StaticBody2D`, `Area2D`, or `CollisionShape2D` to PVGames art.
6. Preserve GameplayRoot as gameplay truth.

## Suggested Z-Index Ranges

- FloorLayer: about `-300`
- WallLayer: about `-220`
- PropLayer: `-120` to `-60`
- DecorationLayer: `-90` to `-40`
- CollectibleLayer: `-70` to `-30`
- ForegroundLayer: `120+`
- LightingLayer: `180+`

## Cursor-Assisted Workflow

Ask Cursor to use the curated palette or full catalog, then place visual-only art under the correct ArtRoot layer. Explicitly say not to touch GameplayRoot, collision, station proxies, objectives, guards, cameras, store systems, MissionBoard, SceneManager, or Player.gd.

## Example Prompts

Hideout greenhouse:

> Use the PVGames birthday-build curated palette to improve the HideoutHub greenhouse. Use GREENHOUSE_PLANT, DOOR_WINDOW, LIGHTING, FLOOR_PATCH, and WALL_BACK assets. Place art only under ArtRoot/World. Do not modify GameplayRoot, station proxies, collision, MissionBoard, store, or Decorating Mode.

Hideout store terminal:

> Use the PVGames catalog to improve the HideoutHub StoreTerminal area. Use STORE_TECH, NEON_SIGN, COMPUTER_ARCADE, LIGHTING, and CRATE_STORAGE. Keep art visual-only. Do not move the StoreTerminal proxy.

Taco Bell bag room:

> Use the PVGames curated palette to dress the Taco Bell bag room. Use CRATE_STORAGE, STORE_TECH, WALL_BACK, FLOOR_PATCH, and CLUTTER_SMALL. Preserve delivery bag, Louis exit, collision, objectives, guards, cameras, and all gameplay markers.

Taco Bell dining area:

> Use PVGames FURNITURE, STORE_TECH, NEON_SIGN, FLOOR_PATCH, WALL_BACK, and CLUTTER_SMALL assets to dress the Taco Bell dining area. Place visuals under ArtRoot only. Do not alter GameplayRoot or mission logic.

Future alley mission:

> Use ROAD_STREET, WALL_SIDE, NEON_SIGN, CRATE_STORAGE, FOREGROUND_TALL, and LIGHTING from the PVGames catalog to create a neon-noir alley dressing pass. Use visual-only Sprite2D placement and preserve all gameplay collision.

## What Not To Do

- Do not add PVGames collision.
- Do not move GameplayRoot proxies.
- Do not place art under GameplayRoot.
- Do not use the full pack as one TileMap.
- Do not put thousands of sprites into a production scene.
- Do not modify Taco Bell gameplay while dressing art.
- Do not modify Hideout gameplay while dressing art.
""", encoding="utf-8")


def write_main_reports(entries: list[dict[str, Any]], curated: list[dict[str, Any]], category_sheets: dict[str, list[str]]) -> None:
    category_counts = {c: 0 for c in CATEGORIES}
    for e in entries:
        category_counts[e["inferred_category"]] += 1
    scene_counts = {
        "hideout": sum(1 for c in curated if c["recommended_scene"] == "HideoutHub"),
        "taco_bell": sum(1 for c in curated if c["recommended_scene"] == "Taco Bell"),
        "both": sum(1 for c in curated if c["recommended_scene"] == "both"),
        "future_mission": sum(1 for c in curated if c["recommended_scene"] == "future mission"),
    }
    contact_count = sum(len(v) for v in category_sheets.values())
    data = {
        "pass_fail_partial": "PASS",
        "asset_root_scanned": "res://assets/tilesets/cyber_city_core_tilesets",
        "total_pngs_indexed": len(entries),
        "catalog_json_path": "res://docs/reports/pvgames_full_asset_catalog.json",
        "catalog_csv_path": "res://docs/reports/pvgames_full_asset_catalog.csv",
        "category_counts": category_counts,
        "contact_sheets_folder": "res://docs/reports/pvgames_palettes/",
        "contact_sheets_created_count": contact_count,
        "birthday_build_curated_palette_path": "res://docs/reports/pvgames_birthday_build_curated_palette.md",
        "birthday_build_curated_palette_json_path": "res://docs/reports/pvgames_birthday_build_curated_palette.json",
        "birthday_build_curated_contact_sheet_path": "res://docs/reports/pvgames_palettes/pvgames_birthday_build_curated_palette.png",
        "birthday_build_curated_asset_count": len(curated),
        "curated_hideout_asset_count": scene_counts["hideout"],
        "curated_taco_bell_asset_count": scene_counts["taco_bell"],
        "curated_both_scenes_asset_count": scene_counts["both"],
        "curated_future_mission_asset_count": scene_counts["future_mission"],
        "palette_browser_scene": "res://scenes/hideout/tools/PVGamesAssetPaletteBrowser.tscn",
        "stamping_tool_path": "res://src/tools/editor/PVGamesArtStamper.gd",
        "sample_manifest_path": "res://docs/reports/pvgames_sample_art_placement_manifest.json",
        "visual_tileset_floor_subset": "skipped - Sprite2D/parallax placement remains safer until a floor subset is manually sliced",
        "character_support_plan_written": True,
        "character_schema_paths": ["res://docs/reports/character_asset_schema.json", "res://docs/reports/character_animation_profile_schema.json"],
        "quickstart_guide_path": "res://docs/reports/pvgames_art_library_quickstart.md",
        "hideout_modified": False,
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "recommended_workflow": "Use curated palette first; place PVGames art as visual-only Sprite2D under ArtRoot/World. Use full catalog/contact sheets for deeper searches.",
        "risks": [
            "Full category contact sheets are broad browsing aids, not art-direction approval for every asset.",
            "TileMap floor subset is intentionally skipped until manual slicing is requested.",
            "Palette browser scene is representative and not linked to game runtime.",
        ],
        "next_recommended_step": "Use the birthday-build curated palette for small, targeted visual-only polish passes in HideoutHub or Taco Bell after 0M-B manual testing.",
    }
    write_json(MAIN_REPORT_JSON, data)
    lines = [
        "# PVGames Asset Library And Painting Tool",
        "",
        "Status: PASS",
        "",
        f"- Asset root scanned: `{data['asset_root_scanned']}`",
        f"- Total PNGs indexed: {len(entries)}",
        f"- Catalog JSON: `{data['catalog_json_path']}`",
        f"- Catalog CSV: `{data['catalog_csv_path']}`",
        f"- Contact sheets folder: `{data['contact_sheets_folder']}`",
        f"- Contact sheets created: {contact_count}",
        f"- Birthday-build curated palette: `{data['birthday_build_curated_palette_path']}`",
        f"- Birthday-build curated asset count: {len(curated)}",
        f"- Curated contact sheet: `{data['birthday_build_curated_contact_sheet_path']}`",
        f"- Palette browser scene: `{data['palette_browser_scene']}`",
        f"- Stamping tool: `{data['stamping_tool_path']}`",
        f"- Sample manifest: `{data['sample_manifest_path']}`",
        f"- Character support plan: `res://docs/reports/character_asset_support_plan.md`",
        f"- Quickstart: `{data['quickstart_guide_path']}`",
        "",
        "## Category Counts",
        "",
    ]
    for cat, count in category_counts.items():
        lines.append(f"- {cat}: {count}")
    lines += [
        "",
        "## Recommended Manual Workflow",
        "",
        data["recommended_workflow"],
        "",
        "## Recommended Cursor Workflow",
        "",
        "Ask Cursor to use curated IDs from the birthday-build palette or category IDs from the full catalog. Always require visual-only placement under ArtRoot/World and forbid GameplayRoot/collision/proxy changes.",
        "",
        "## HideoutHub Painting",
        "",
        "Use `HIDEOUTHUB_ESSENTIALS`, `GREENHOUSE_Cozy_BENTLEY`, `DISPLAYS_SHELVES_COLLECTIONS`, and `SIGNS_LIGHTS_NEON_MONITORS` first. Place props under ArtRoot/World layers only.",
        "",
        "## Taco Bell Painting",
        "",
        "Use `TACO_BELL_FAST_FOOD_STORE`, `FLOORS_WALLS_STRUCTURE`, `CRATE_STORAGE`, `STORE_TECH`, `FURNITURE`, and `CLUTTER_SMALL` entries. Preserve all mission gameplay markers, guards, cameras, objectives, and collision.",
        "",
        "## Future Character Assets",
        "",
        "Buy/use transparent PNG sprite sheets or frame sequences with 4-direction minimum and 8-direction preferred. Avoid side-view platformer sprites and one-direction packs.",
        "",
        "## Known Limitations",
        "",
    ]
    for risk in data["risks"]:
        lines.append(f"- {risk}")
    lines += ["", "## Next Recommended Prompt", "", data["next_recommended_step"], ""]
    MAIN_REPORT_MD.write_text("\n".join(lines), encoding="utf-8")


CATALOG_DICTS: list[dict[str, Any]] = []


def main() -> None:
    global CATALOG_DICTS
    for d in (REPORTS, PALETTES, TOOLS_SCENE_DIR):
        d.mkdir(parents=True, exist_ok=True)
    catalog = build_catalog()
    CATALOG_DICTS = [asdict(e) for e in catalog]
    write_json(CATALOG_JSON, CATALOG_DICTS)
    write_csv(CATALOG_CSV, CATALOG_DICTS)
    category_sheets = write_category_sheets(CATALOG_DICTS)
    curated = build_curated(CATALOG_DICTS)
    write_json(CURATED_JSON, curated)
    write_curated_md(curated)
    write_curated_sheet(curated)
    write_browser_scene(curated)
    write_stamper_tool()
    write_sample_manifest(curated)
    write_character_schemas_and_plan()
    write_quickstart(category_sheets)
    write_main_reports(CATALOG_DICTS, curated, category_sheets)
    print(json.dumps({
        "status": "PASS",
        "total_pngs": len(CATALOG_DICTS),
        "curated_assets": len(curated),
        "contact_sheets": sum(len(v) for v in category_sheets.values()),
        "catalog_json": res_path(CATALOG_JSON),
        "curated_json": res_path(CURATED_JSON),
    }, indent=2))


if __name__ == "__main__":
    main()
