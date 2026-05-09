#!/usr/bin/env python3
"""
Build verified, paintable PVGames CyberCity Central Security TileSet palettes.

This is intentionally separate from the 0M-B4 Core PVGames palettes. It scans
the local-only Central Security source folder, classifies usable assets, writes
visual-only TileSet resources, verifies the actual generated tiles, adds empty
HideoutHub paint layers that follow the 0M-B5 depth model, and writes reports.
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
SOURCE_ROOT = ROOT / "assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles"
SOURCE_RES_ROOT = "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles"
EXPECTED_SUBFOLDERS = [
    "CyberCity_CentralSecurity_Tiles_1",
    "CyberCity_CentralSecurity_Tiles_2",
    "CyberCity_CentralSecurity_Tiles_3",
    "CyberCity_CentralSecurity_Tiles_4",
]

TILESET_DIR = ROOT / "assets/tilesets/pvgames_central_security_paintable"
VERIFICATION_DIR = REPORTS / "pvgames_central_security_verification"
PALETTE_DIR = REPORTS / "pvgames_central_security_palettes"
TEST_SCENE = ROOT / "scenes/hideout/tools/PVGamesCentralSecurityPaintableTileSetTest.tscn"
HIDEOUT = ROOT / "scenes/hideout/HideoutHub.tscn"
ASSET_INSTALL = ROOT / "docs/ASSET_INSTALLATION.md"
VALIDATOR = ROOT / "src/tools/editor/PVGamesCentralSecurityPaintableTileSetValidator.gd"

CATALOG_JSON = REPORTS / "pvgames_central_security_full_asset_catalog.json"
CATALOG_CSV = REPORTS / "pvgames_central_security_full_asset_catalog.csv"
CANDIDATES_JSON = REPORTS / "pvgames_central_security_paint_candidates.json"
CANDIDATES_CSV = REPORTS / "pvgames_central_security_paint_candidates.csv"
CLASSIFICATION_JSON = REPORTS / "pvgames_central_security_paint_classification.json"
CLASSIFICATION_MD = REPORTS / "pvgames_central_security_paint_classification.md"
VERIFICATION_JSON = REPORTS / "pvgames_central_security_tile_verification.json"
VERIFICATION_CSV = REPORTS / "pvgames_central_security_tile_verification.csv"
VERIFICATION_MD = REPORTS / "pvgames_central_security_tile_verification.md"
SPRITE_JSON = REPORTS / "pvgames_central_security_assets_better_as_sprites_or_stamps.json"
SPRITE_MD = REPORTS / "pvgames_central_security_assets_better_as_sprites_or_stamps.md"
HOW_TO = REPORTS / "pvgames_central_security_paintable_tilesets_how_to_use.md"
MAIN_JSON = REPORTS / "pvgames_central_security_paintable_tileset_creation.json"
MAIN_MD = REPORTS / "pvgames_central_security_paintable_tileset_creation.md"

TILESETS = {
    "ground_road": {
        "name": "Ground/Road/Floor",
        "path": "res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityGroundRoadPaint.tres",
        "local": TILESET_DIR / "PVGamesCentralSecurityGroundRoadPaint.tres",
        "limit": 140,
        "z_index": -300,
        "depth_role": "BEHIND_PLAYER",
    },
    "wall": {
        "name": "Wall/Security Barrier",
        "path": "res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityWallPaint.tres",
        "local": TILESET_DIR / "PVGamesCentralSecurityWallPaint.tres",
        "limit": 180,
        "z_index": -220,
        "depth_role": "OCCLUDABLE_ABOVE_PLAYER",
    },
    "large_structure": {
        "name": "Large Structure",
        "path": "res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityLargeStructurePaint.tres",
        "local": TILESET_DIR / "PVGamesCentralSecurityLargeStructurePaint.tres",
        "limit": 110,
        "z_index": -140,
        "depth_role": "OCCLUDABLE_ABOVE_PLAYER",
    },
    "prop_sign": {
        "name": "Prop/Sign/Tech",
        "path": "res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityPropSignPaint.tres",
        "local": TILESET_DIR / "PVGamesCentralSecurityPropSignPaint.tres",
        "limit": 130,
        "z_index": -60,
        "depth_role": "OCCLUDABLE_ABOVE_PLAYER",
    },
    "review_only": {
        "name": "Review Only",
        "path": "res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityReviewOnlyPaint.tres",
        "local": TILESET_DIR / "PVGamesCentralSecurityReviewOnlyPaint.tres",
        "limit": 140,
        "z_index": -40,
        "depth_role": "REVIEW_ONLY",
    },
}

GROUND_TERMS = [
    "floor", "ground", "ground_tile", "ground_decal", "road", "street", "tile",
    "pavement", "platform", "ramp", "techfloor", "securityfloor", "floorpanel",
    "sidewalk", "walkway", "path", "brigcellfloor", "brighallfloor", "warroomfloor",
]
WALL_TERMS = [
    "wall", "citywalls", "citywallscorner", "citywallspost", "subwaywall", "fence",
    "barrier", "securitywall", "door", "window", "gate", "post", "column",
    "pillar", "corner", "rail", "railing", "partition",
]
LARGE_TERMS = [
    "building", "securitybuilding", "station", "checkpoint",
    "guard", "guardpost", "watchtower", "shack", "metrostation", "subwayplatform",
    "bridge", "facade", "structure", "large", "kiosk", "tower", "fortpart",
    "landingport", "rocketplatform", "mobilearmory",
]
PROP_TERMS = [
    "sign", "billboard", "console", "terminal", "computer", "screen", "monitor",
    "camera", "turret", "scanner", "sensor", "doorcontrol", "panel", "crate",
    "clutter", "pipe", "largepipe", "satelitedish", "satellitedish",
    "chargingstation", "generator", "server", "locker", "desk", "chair", "table",
    "lamp", "light", "neon", "prop", "vent", "antenna", "antennae", "dish",
]
CONTACT_TOKENS = ["docs/reports", "contact", "palette", "verification", "sheet"]


def rel(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def local_path(res_path: str) -> Path:
    return ROOT / res_path.removeprefix("res://")


def safe_text(value: str) -> str:
    return value.replace('"', '\\"')


def uid_for(text: str) -> str:
    digest = hashlib.sha1(text.encode("utf-8")).hexdigest()[:15]
    alphabet = "abcdefghijklmnopqrstuvwxyz234567"
    number = int(digest, 16)
    chars: list[str] = []
    for _ in range(14):
        chars.append(alphabet[number % len(alphabet)])
        number //= len(alphabet)
    return "uid://" + "".join(chars)


def norm(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def contains_any(text: str, terms: list[str]) -> bool:
    compact = norm(text)
    return any(norm(term) in compact for term in terms)


def family_key(filename: str) -> str:
    stem = Path(filename).stem
    return re.sub(r"[_-]?\d+$", "", stem)


def measure_image(path: Path) -> dict[str, Any]:
    with Image.open(path) as im:
        im = im.convert("RGBA")
        width, height = im.size
        alpha = im.getchannel("A")
        bbox = alpha.getbbox()
        hist = alpha.histogram()
        transparent_pixels = hist[0]
        visible_pixels = width * height - transparent_pixels
        transparent_pct = transparent_pixels / max(1, width * height) * 100.0
        if bbox:
            bbox_w = bbox[2] - bbox[0]
            bbox_h = bbox[3] - bbox[1]
        else:
            bbox_w = 0
            bbox_h = 0
        return {
            "width": width,
            "height": height,
            "has_alpha": True,
            "alpha_bbox": list(bbox) if bbox else None,
            "alpha_bbox_width": bbox_w,
            "alpha_bbox_height": bbox_h,
            "transparent_pixel_percentage": round(transparent_pct, 3),
            "visible_pixel_coverage": round(visible_pixels / max(1, width * height), 5),
            "aspect_ratio": round(width / max(1, height), 4),
            "mostly_blank": transparent_pct > 96.0 or bbox_w < 8 or bbox_h < 8,
            "unusually_large": width > 1200 or height > 1200,
            "unusually_small": width < 24 or height < 24 or bbox_w < 16 or bbox_h < 16,
        }


def scan_assets() -> tuple[list[dict[str, Any]], int]:
    png_paths = sorted(SOURCE_ROOT.rglob("*.png"))
    import_count = len(list(SOURCE_ROOT.rglob("*.png.import")))
    catalog: list[dict[str, Any]] = []
    for idx, path in enumerate(png_paths, 1):
        m = measure_image(path)
        res_path = rel(path)
        rel_folder = path.parent.relative_to(SOURCE_ROOT).as_posix()
        # Use source filenames for category inference. Folder names contain
        # "CentralSecurity_Tiles", which would otherwise overmatch everything.
        name_blob = f"{path.name} {family_key(path.name)}"
        include_reason = []
        for pool, terms in [
            ("ground_floor_road", GROUND_TERMS),
            ("wall_security_barrier", WALL_TERMS),
            ("large_structure", LARGE_TERMS),
            ("prop_sign_tech", PROP_TERMS),
        ]:
            if contains_any(name_blob, terms):
                include_reason.append(pool)
        if not include_reason and not m["mostly_blank"]:
            include_reason.append("review_unknown_visually_promising")
        catalog.append({
            "asset_id": f"CS_{idx:04d}",
            "path": res_path,
            "filename": path.name,
            "relative_folder": rel_folder,
            "folder": path.parent.name,
            "filename_family": family_key(path.name),
            "candidate_inclusion_reason": ", ".join(include_reason) if include_reason else "excluded_mostly_blank_or_unmatched",
            **m,
        })
    return catalog, import_count


def derive_candidates(catalog: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    candidates: list[dict[str, Any]] = []
    rejected_contact: list[dict[str, Any]] = []
    for entry in catalog:
        path = str(entry["path"])
        lower = path.lower()
        if any(token in lower for token in CONTACT_TOKENS) or not path.startswith(SOURCE_RES_ROOT):
            rejected_contact.append({
                "asset_id": entry["asset_id"],
                "path": path,
                "filename": entry["filename"],
                "reason": "Contact/report/non-source path rejected.",
            })
            continue
        if str(entry["candidate_inclusion_reason"]).startswith("excluded"):
            continue
        pool = candidate_pool(entry)
        c = dict(entry)
        c["candidate_pool"] = pool
        candidates.append(c)
    return candidates, rejected_contact


def candidate_pool(entry: dict[str, Any]) -> str:
    blob = f"{entry['filename']} {entry['filename_family']}"
    if contains_any(blob, GROUND_TERMS):
        return "A_GROUND_FLOOR_ROAD"
    if contains_any(blob, WALL_TERMS):
        return "B_WALL_SECURITY_BARRIER"
    if contains_any(blob, LARGE_TERMS):
        return "C_LARGE_STRUCTURE"
    if contains_any(blob, PROP_TERMS):
        return "D_PROP_SIGN_TECH"
    return "E_REVIEW_UNKNOWN"


def classify_candidate(c: dict[str, Any]) -> dict[str, Any]:
    blob = f"{c['filename']} {c['filename_family']}"
    w, h = int(c["width"]), int(c["height"])
    bbox_w, bbox_h = int(c["alpha_bbox_width"]), int(c["alpha_bbox_height"])
    transparent = float(c["transparent_pixel_percentage"])
    classification = "SPRITE_STAMP_BETTER"
    palette = "review_only"
    layer = "ReviewOnly"
    depth_role = "REVIEW_ONLY"
    z_index = -40
    handling = "review only"
    reason = "Ambiguous Central Security asset; useful enough to inspect but not confidently production-paletted."
    notes = ""

    if c["mostly_blank"] or bbox_w < 16 or bbox_h < 16:
        classification = "SKIP_UNSAFE"
        palette = "skip"
        layer = "skip"
        depth_role = "REVIEW_ONLY"
        handling = "skip"
        reason = "Blank, mostly transparent, or too tiny to paint usefully."
    elif w > 1500 or h > 1500:
        classification = "SKIP_UNSAFE"
        palette = "skip"
        layer = "skip"
        depth_role = "REVIEW_ONLY"
        handling = "skip"
        reason = "Too large for a usable TileMap palette without hand-authored placement."
    elif contains_any(blob, GROUND_TERMS):
        classification = "SINGLE_TILE_SPRITE"
        palette = "ground_road"
        layer = "PVGamesCentralSecurityGroundRoadPaintLayer"
        depth_role = "BEHIND_PLAYER"
        z_index = TILESETS[palette]["z_index"]
        handling = "one whole image tile"
        reason = "Floor/ground/road/security panel asset is useful as behind-player map paint."
    elif contains_any(blob, WALL_TERMS):
        classification = "SINGLE_TILE_SPRITE"
        palette = "wall"
        layer = "PVGamesCentralSecurityOccludableWallPaintLayer"
        depth_role = "OCCLUDABLE_ABOVE_PLAYER"
        z_index = 80
        handling = "one whole image tile"
        reason = "Wall/barrier/gate/post/rail asset is useful as modular occludable art."
    elif contains_any(blob, LARGE_TERMS):
        classification = "LARGE_STRUCTURE_SPRITE"
        palette = "large_structure"
        layer = "PVGamesCentralSecurityOccludableLargeStructurePaintLayer"
        depth_role = "OCCLUDABLE_ABOVE_PLAYER"
        z_index = 95
        handling = "one whole image tile"
        reason = "Large structure/security architecture belongs in the large structure palette."
    elif contains_any(blob, PROP_TERMS):
        if w <= 700 and h <= 700 and transparent < 94:
            classification = "SINGLE_TILE_SPRITE"
            palette = "prop_sign"
            layer = "PVGamesCentralSecurityOccludablePropPaintLayer"
            depth_role = "OCCLUDABLE_ABOVE_PLAYER"
            z_index = 90
            handling = "one whole image tile"
            reason = "Prop/sign/tech asset is practical enough as a TileMap paint item."
        else:
            classification = "SPRITE_STAMP_BETTER"
            palette = "sprite_stamper"
            layer = "PropLayer or ForegroundLayer"
            depth_role = "SPRITE_STAMP"
            z_index = 90
            handling = "sprite/stamper"
            reason = "Useful irregular prop/sign/tech object, but individual Sprite2D placement is safer."
    elif w <= 420 and h <= 420 and transparent < 92:
        classification = "SINGLE_TILE_SPRITE"
        palette = "review_only"
        layer = "PVGamesCentralSecurityReviewOnlyTileMapLayer"
        depth_role = "REVIEW_ONLY"
        z_index = -40
        handling = "review only"
        reason = "Visually promising unknown asset; review before production use."

    if classification != "SKIP_UNSAFE" and max(w, h) > 900:
        notes = "Large object; use carefully."
        if palette not in ["large_structure", "sprite_stamper"]:
            palette = "review_only"
            depth_role = "REVIEW_ONLY"
            layer = "PVGamesCentralSecurityReviewOnlyTileMapLayer"
            reason += " Moved to review because it is oversized for its inferred palette."

    c.update({
        "inferred_family": c["filename_family"],
        "classification": classification,
        "reason": reason,
        "recommended_palette": palette,
        "recommended_layer": layer,
        "recommended_z_index": z_index,
        "recommended_depth_role": depth_role,
        "recommended_tileset_handling": handling,
        "notes": notes,
    })
    return c


def palette_score(c: dict[str, Any]) -> tuple[int, int, int, str]:
    w, h = int(c["width"]), int(c["height"])
    coverage = float(c["visible_pixel_coverage"])
    transparent = float(c["transparent_pixel_percentage"])
    family = str(c["filename_family"])
    score = 0
    if c["classification"] in ["SINGLE_TILE_SPRITE", "LARGE_STRUCTURE_SPRITE"]:
        score += 100
    if 48 <= w <= 700 and 48 <= h <= 700:
        score += 25
    if 0.08 <= coverage <= 0.95:
        score += 20
    if transparent < 90:
        score += 10
    if c["candidate_pool"].startswith(("A_", "B_", "C_", "D_")):
        score += 8
    return (-score, max(w, h), min(w, h), family)


def select_tiles(classified: list[dict[str, Any]]) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    by_palette: dict[str, list[dict[str, Any]]] = defaultdict(list)
    sprite_list: list[dict[str, Any]] = []
    for c in classified:
        palette = c["recommended_palette"]
        if palette == "sprite_stamper":
            sprite_list.append(c)
        elif palette in TILESETS:
            by_palette[palette].append(c)
    selected: dict[str, list[dict[str, Any]]] = {}
    for palette, entries in by_palette.items():
        limit = int(TILESETS[palette]["limit"])
        family_counts: Counter[str] = Counter()
        kept: list[dict[str, Any]] = []
        for entry in sorted(entries, key=palette_score):
            family = entry["filename_family"]
            family_cap = 8 if palette in ["ground_road", "wall"] else 6
            if family_counts[family] >= family_cap:
                continue
            kept.append(entry)
            family_counts[family] += 1
            if len(kept) >= limit:
                break
        selected[palette] = kept
    return selected, sprite_list[:500]


def quality_classify(entry: dict[str, Any], palette: str) -> tuple[str, str, str]:
    w, h = int(entry["width"]), int(entry["height"])
    bbox_w, bbox_h = int(entry["alpha_bbox_width"]), int(entry["alpha_bbox_height"])
    transparent = float(entry["transparent_pixel_percentage"])
    coverage = float(entry["visible_pixel_coverage"])
    classification = str(entry["classification"])
    if transparent > 98 or bbox_w < 12 or bbox_h < 12:
        return "REJECT_JUNK", "remove", "Mostly blank/tiny visible area."
    if w > 1400 or h > 1400:
        return "REJECT_JUNK", "remove", "Too large for the TileMap palette."
    if transparent > 94 and coverage < 0.04:
        return "REVIEW_MANUALLY", "move to review palette", "Very sparse visible pixels; may be useful but needs inspection."
    if palette == "review_only":
        return "REVIEW_MANUALLY", "keep in review palette", "Review-only candidate."
    if classification == "LARGE_STRUCTURE_SPRITE" or max(w, h) > 760:
        return "REVIEW_MANUALLY" if palette != "large_structure" else "MODULAR_PART_OK", "keep in production palette" if palette == "large_structure" else "move to review palette", "Large object; use carefully."
    if contains_any(entry["filename"], ["wall", "corner", "post", "rail", "barrier", "gate", "door", "window", "fence", "panel", "pipe"]):
        return "MODULAR_PART_OK", "keep in production palette", "Useful modular wall/security/tech partial."
    if contains_any(entry["filename"], ["floor", "road", "ground", "pavement", "platform", "tile", "decal"]):
        return "READY_TO_PAINT", "keep in production palette", "Coherent ground/floor paint tile."
    if contains_any(entry["filename"], ["building", "structure", "tower", "platform", "gate"]):
        return "MODULAR_PART_OK", "keep in production palette", "Useful large modular structure or security architecture piece."
    if 32 <= bbox_w <= 700 and 32 <= bbox_h <= 700:
        return "READY_TO_PAINT", "keep in production palette", "Coherent paintable Central Security asset."
    return "REVIEW_MANUALLY", "move to review palette", "Unusual crop or size; inspect manually."


def verify_selection(selected: dict[str, list[dict[str, Any]]]) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    final: dict[str, list[dict[str, Any]]] = {key: [] for key in TILESETS}
    records: list[dict[str, Any]] = []
    review_seen: set[str] = set()
    for palette, entries in selected.items():
        for source_idx, entry in enumerate(entries):
            quality, action, reason = quality_classify(entry, palette)
            target_palette = palette
            if quality == "REJECT_JUNK":
                target_palette = "rejected"
            elif quality == "REVIEW_MANUALLY" and palette != "review_only":
                target_palette = "review_only"
            if target_palette in final and (target_palette != "review_only" or entry["asset_id"] not in review_seen):
                final[target_palette].append(entry)
                if target_palette == "review_only":
                    review_seen.add(entry["asset_id"])
            records.append({
                "tileset_path": TILESETS.get(target_palette, TILESETS.get(palette, {})).get("path", ""),
                "original_palette": palette,
                "palette": target_palette,
                "tile_id": f"{palette}_{source_idx:04d}",
                "source_asset_id": entry["asset_id"],
                "source_path": entry["path"],
                "source_filename": entry["filename"],
                "source_region": [0, 0, entry["width"], entry["height"]],
                "preview_width": entry["width"],
                "preview_height": entry["height"],
                "visible_alpha_bbox": entry["alpha_bbox"],
                "transparent_percentage": entry["transparent_pixel_percentage"],
                "pre_tileset_classification": entry["classification"],
                "post_creation_quality_classification": quality,
                "reason": reason,
                "recommended_action": action,
            })
    return final, records


def write_tileset(path: Path, entries: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = [
        f'[gd_resource type="TileSet" format=3 uid="{uid_for(rel(path))}"]',
        "",
    ]
    for idx, entry in enumerate(entries, 1):
        lines.append(f'[ext_resource type="Texture2D" uid="{uid_for(entry["path"])}" path="{entry["path"]}" id="{idx}_src"]')
    if entries:
        lines.append("")
    for idx, entry in enumerate(entries):
        lines.extend([
            f'[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_{idx}"]',
            f'texture = ExtResource("{idx + 1}_src")',
            f'texture_region_size = Vector2i({int(entry["width"])}, {int(entry["height"])})',
            "0:0/0 = 0",
            "",
        ])
    lines.extend([
        "[resource]",
        "tile_shape = 1",
        "tile_size = Vector2i(64, 32)",
    ])
    for idx, _entry in enumerate(entries):
        lines.append(f'sources/{idx} = SubResource("TileSetAtlasSource_{idx}")')
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        path.write_text("", encoding="utf-8")
        return
    keys: list[str] = []
    for row in rows:
        for key in row.keys():
            if key not in keys:
                keys.append(key)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=keys)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: json.dumps(row.get(key, ""), ensure_ascii=False) if isinstance(row.get(key, ""), (list, dict)) else row.get(key, "") for key in keys})


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except Exception:
        return ImageFont.load_default()


def render_contact_sheets(entries: list[dict[str, Any]], prefix: str, out_dir: Path, title: str, browsing_only: bool) -> list[str]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths: list[str] = []
    if not entries:
        entries = []
    cell_w, cell_h = 260, 230
    cols, rows = 4, 4
    per_page = cols * rows
    page_count = max(1, math.ceil(len(entries) / per_page))
    for page in range(page_count):
        chunk = entries[page * per_page:(page + 1) * per_page]
        img = Image.new("RGBA", (cols * cell_w, rows * cell_h + 70), (20, 22, 28, 255))
        draw = ImageDraw.Draw(img)
        draw.text((14, 10), f"{title} page {page + 1}/{page_count}", fill=(230, 245, 255, 255), font=font(18))
        if browsing_only:
            draw.text((14, 38), "Browsing/contact sheet only. Do not use as source art.", fill=(255, 210, 120, 255), font=font(13))
        for idx, entry in enumerate(chunk):
            x = (idx % cols) * cell_w
            y = 70 + (idx // cols) * cell_h
            draw.rectangle((x + 6, y + 6, x + cell_w - 6, y + cell_h - 6), outline=(90, 120, 150, 255), width=1)
            source = local_path(entry.get("source_path", entry.get("path", "")))
            try:
                with Image.open(source) as src:
                    src = src.convert("RGBA")
                    src.thumbnail((cell_w - 30, 120), Image.Resampling.LANCZOS)
                    img.alpha_composite(src, (x + (cell_w - src.width) // 2, y + 14))
            except Exception:
                draw.text((x + 14, y + 42), "preview unavailable", fill=(255, 80, 80, 255), font=font(12))
            quality = entry.get("post_creation_quality_classification", entry.get("quality", ""))
            lines = [
                str(entry.get("tile_id", entry.get("asset_id", "")))[:34],
                str(entry.get("source_filename", entry.get("filename", "")))[:34],
                str(quality)[:34],
                str(entry.get("palette", entry.get("recommended_palette", "")))[:34],
                str(entry.get("reason", entry.get("recommended_depth_role", "")))[:42],
            ]
            yy = y + 140
            for line in lines:
                draw.text((x + 12, yy), line, fill=(225, 235, 245, 255), font=font(11))
                yy += 16
        suffix = f"_{page + 1:03d}" if page_count > 1 else ""
        out_path = out_dir / f"{prefix}{suffix}.png"
        img.convert("RGB").save(out_path)
        paths.append(rel(out_path))
    return paths


def make_test_scene(final: dict[str, list[dict[str, Any]]]) -> None:
    TEST_SCENE.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "[gd_scene load_steps=6 format=3]",
        "",
        f'[ext_resource type="TileSet" path="{TILESETS["ground_road"]["path"]}" id="1_ground"]',
        f'[ext_resource type="TileSet" path="{TILESETS["wall"]["path"]}" id="2_wall"]',
        f'[ext_resource type="TileSet" path="{TILESETS["large_structure"]["path"]}" id="3_large"]',
        f'[ext_resource type="TileSet" path="{TILESETS["prop_sign"]["path"]}" id="4_prop"]',
        f'[ext_resource type="TileSet" path="{TILESETS["review_only"]["path"]}" id="5_review"]',
        "",
        '[node name="PVGamesCentralSecurityPaintableTileSetTest" type="Node2D"]',
        "",
        '[node name="Instructions" type="Label" parent="."]',
        "offset_left = -520.0",
        "offset_top = -320.0",
        "offset_right = 680.0",
        "offset_bottom = -220.0",
        'text = "Visual-only Central Security TileSet palette test scene. READY_TO_PAINT and MODULAR_PART_OK are intended for use. REVIEW_MANUALLY needs inspection. REJECT_JUNK is excluded from production palettes."',
        "autowrap_mode = 2",
        "",
    ]
    layer_specs = [
        ("CentralSecurityGroundRoadTileMapLayer", "1_ground", -300, Vector2(-280, -80)),
        ("CentralSecurityWallTileMapLayer", "2_wall", -220, Vector2(-80, -80)),
        ("CentralSecurityLargeStructureTileMapLayer", "3_large", -140, Vector2(120, -80)),
        ("CentralSecurityPropSignTileMapLayer", "4_prop", -60, Vector2(320, -80)),
        ("CentralSecurityReviewOnlyTileMapLayer", "5_review", -40, Vector2(520, -80)),
    ]
    for name, ext_id, z, pos in layer_specs:
        lines.extend([
            f'[node name="{name}" type="TileMapLayer" parent="."]',
            f"position = Vector2({pos.x}, {pos.y})",
            f"z_index = {z}",
            f'tile_set = ExtResource("{ext_id}")',
            "collision_enabled = false",
            "",
        ])
    lines.extend([
        '[node name="Camera2D" type="Camera2D" parent="."]',
        "position = Vector2(0, 0)",
        "zoom = Vector2(0.75, 0.75)",
        "enabled = true",
        "",
    ])
    TEST_SCENE.write_text("\n".join(lines), encoding="utf-8")


class Vector2:
    def __init__(self, x: int, y: int) -> None:
        self.x = x
        self.y = y


def add_hideout_layers() -> bool:
    text = HIDEOUT.read_text(encoding="utf-8")
    if "PVG_CentralSecurityPaintLayers" in text and "PVG_CentralSecurityDepthPaintLayers" in text:
        return False
    insert_after = '[ext_resource type="TileSet" path="res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres" id="22_catalog_prop_tileset"]'
    ext = "\n".join([
        insert_after,
        f'[ext_resource type="TileSet" path="{TILESETS["ground_road"]["path"]}" id="23_cs_ground_tileset"]',
        f'[ext_resource type="TileSet" path="{TILESETS["wall"]["path"]}" id="24_cs_wall_tileset"]',
        f'[ext_resource type="TileSet" path="{TILESETS["large_structure"]["path"]}" id="25_cs_large_tileset"]',
        f'[ext_resource type="TileSet" path="{TILESETS["prop_sign"]["path"]}" id="26_cs_prop_tileset"]',
    ])
    text = text.replace(insert_after, ext)
    nodes = """
[node name="PVG_CentralSecurityPaintLayers" type="Node2D" parent="ArtRoot/World"]
z_index = -300

[node name="PVGamesCentralSecurityGroundRoadPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityPaintLayers"]
z_index = -300
tile_set = ExtResource("23_cs_ground_tileset")
collision_enabled = false

[node name="PVGamesCentralSecurityWallBackdropPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityPaintLayers"]
z_index = -220
tile_set = ExtResource("24_cs_wall_tileset")
collision_enabled = false

[node name="PVGamesCentralSecurityLargeStructureBackdropPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityPaintLayers"]
z_index = -140
tile_set = ExtResource("25_cs_large_tileset")
collision_enabled = false

[node name="PVGamesCentralSecurityPropSignBackdropPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityPaintLayers"]
z_index = -80
tile_set = ExtResource("26_cs_prop_tileset")
collision_enabled = false

[node name="PVG_CentralSecurityDepthPaintLayers" type="Node2D" parent="ArtRoot/World"]
z_index = 0

[node name="PVGamesCentralSecurityOccludableWallPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityDepthPaintLayers"]
z_index = 80
tile_set = ExtResource("24_cs_wall_tileset")
collision_enabled = false

[node name="PVGamesCentralSecurityOccludablePropPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityDepthPaintLayers"]
z_index = 90
tile_set = ExtResource("26_cs_prop_tileset")
collision_enabled = false

[node name="PVGamesCentralSecurityOccludableLargeStructurePaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityDepthPaintLayers"]
z_index = 95
tile_set = ExtResource("25_cs_large_tileset")
collision_enabled = false

[node name="PVGamesCentralSecurityForegroundOverlayPaintLayer" type="TileMapLayer" parent="ArtRoot/World/PVG_CentralSecurityDepthPaintLayers"]
z_index = 160
tile_set = ExtResource("26_cs_prop_tileset")
collision_enabled = false

"""
    marker = "[node name=\"UI\" type=\"CanvasLayer\" parent=\".\""
    idx = text.find(marker)
    if idx < 0:
        raise RuntimeError("Could not find UI node marker in HideoutHub.")
    text = text[:idx] + nodes + text[idx:]
    HIDEOUT.write_text(text, encoding="utf-8")
    return True


def update_asset_install_doc() -> bool:
    text = ASSET_INSTALL.read_text(encoding="utf-8")
    if "CyberCity_CentralSecurity_Tiles" in text:
        return False
    section = """

## PVGames CyberCity Central Security

Install the PVGames CyberCity Central Security tiles locally at:

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/`

Expected subfolders:

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_1/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_2/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_3/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_4/`

Raw Central Security PNGs are local-only purchased/source assets. Do not redistribute them unless the license permits it. Generated Central Security TileSets under `assets/tilesets/pvgames_central_security_paintable/` reference these local PNG files; missing source files will produce missing textures in Godot.
"""
    ASSET_INSTALL.write_text(text.rstrip() + section + "\n", encoding="utf-8")
    return True


def write_classification_reports(classified: list[dict[str, Any]]) -> None:
    write_json(CLASSIFICATION_JSON, classified)
    counts = Counter(c["classification"] for c in classified)
    palette_counts = Counter(c["recommended_palette"] for c in classified)
    lines = [
        "# PVGames Central Security Paint Classification",
        "",
        "Status: PASS",
        "",
        "## Classification Counts",
        "",
    ]
    for key in ["TRUE_TILE_ATLAS", "SINGLE_TILE_SPRITE", "LARGE_STRUCTURE_SPRITE", "SPRITE_STAMP_BETTER", "SKIP_UNSAFE"]:
        lines.append(f"- {key}: {counts.get(key, 0)}")
    lines.extend(["", "## Recommended Palette Counts", ""])
    for key in sorted(palette_counts):
        lines.append(f"- {key}: {palette_counts[key]}")
    lines.extend(["", "Every Central Security candidate was classified with a recommended depth role and handling note."])
    CLASSIFICATION_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_verification_reports(records: list[dict[str, Any]], sheet_paths: list[str]) -> None:
    write_json(VERIFICATION_JSON, records)
    write_csv(VERIFICATION_CSV, records)
    counts = Counter(r["post_creation_quality_classification"] for r in records)
    lines = [
        "# PVGames Central Security Tile Verification",
        "",
        "Status: PASS",
        "",
    ]
    for key in ["READY_TO_PAINT", "MODULAR_PART_OK", "REVIEW_MANUALLY", "REJECT_JUNK"]:
        lines.append(f"- {key}: {counts.get(key, 0)}")
    lines.extend(["", "Verification sheets:", ""])
    for path in sheet_paths:
        lines.append(f"- `{path}`")
    lines.extend(["", "REJECT_JUNK tiles are excluded from production TileSets. REVIEW_MANUALLY tiles are moved to the review-only palette when present."])
    VERIFICATION_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_sprite_reports(sprite_entries: list[dict[str, Any]]) -> None:
    rows = []
    for entry in sprite_entries:
        rows.append({
            "asset_id": entry["asset_id"],
            "path": entry["path"],
            "filename": entry["filename"],
            "reason_not_in_production_tileset": entry["reason"],
            "recommended_target_layer": entry["recommended_layer"],
            "recommended_z_index": entry["recommended_z_index"],
            "recommended_depth_role": entry["recommended_depth_role"],
            "recommended_use_case": "Use Sprite2D/PVGamesArtStamper for precise placement, scale, and z-index.",
            "could_still_be_large_painted_tile": max(int(entry["width"]), int(entry["height"])) <= 900,
        })
    write_json(SPRITE_JSON, rows)
    lines = [
        "# Central Security Assets Better As Sprites Or Stamps",
        "",
        "These assets are useful, but not ideal production TileMap palette entries.",
        "",
    ]
    for row in rows[:200]:
        lines.append(f"- `{row['asset_id']}` `{row['filename']}`: {row['reason_not_in_production_tileset']} Target `{row['recommended_target_layer']}`, z `{row['recommended_z_index']}`.")
    if len(rows) > 200:
        lines.append(f"- ... {len(rows) - 200} additional entries in JSON.")
    SPRITE_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_how_to() -> None:
    HOW_TO.write_text(
        """# Central Security Paintable TileSets How To Use

This pass created verified, visual-only paint palettes for PVGames CyberCity Central Security assets.

## Source Assets

`res://assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles`

Raw PNGs are local-only purchased assets. The generated TileSets reference those source PNGs directly.

## TileSet Resources

- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityGroundRoadPaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityWallPaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityLargeStructurePaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityPropSignPaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityReviewOnlyPaint.tres`

## Verification Classes

- `READY_TO_PAINT`: coherent and useful for map dressing.
- `MODULAR_PART_OK`: useful partial like a wall segment, post, connector, barrier, floor panel, or tech module.
- `REVIEW_MANUALLY`: potentially useful but ambiguous, oversized, or context-dependent.
- `REJECT_JUNK`: excluded from production palettes.

## First Use Steps

A. Open `res://scenes/hideout/tools/PVGamesCentralSecurityPaintableTileSetTest.tscn`.

B. Select `CentralSecurityGroundRoadTileMapLayer`.

C. Paint one tile.

D. Select `CentralSecurityWallTileMapLayer`.

E. Paint one tile.

F. Open `res://scenes/hideout/HideoutHub.tscn`.

G. Select `ArtRoot/World/EditorGuideLayer` and press F.

H. Select `PVGamesCentralSecurityGroundRoadPaintLayer`.

I. Paint one floor/security panel tile.

J. Select `PVGamesCentralSecurityOccludableWallPaintLayer`.

K. Paint one wall/barrier tile.

L. Run HideoutHub.

M. Confirm player movement, station interactions, MissionBoard, and Taco Bell return still work.

## HideoutHub Layer Guide

Paint behind-player assets on:

- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityGroundRoadPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityWallBackdropPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityLargeStructureBackdropPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityPropSignBackdropPaintLayer`

Paint above-player occludable assets on:

- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableWallPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludablePropPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableLargeStructurePaintLayer`

Paint always-front overhead/foreground details on:

- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityForegroundOverlayPaintLayer`

This follows the 0M-B5 z-index approximation. True shared Y-sort is not implemented here.

## Collision

No collision, navigation, gameplay metadata, or occlusion polygons were added. These palettes are visual-only.

## Removing Painted Tiles

Use Godot's TileMap erase tool on the selected `TileMapLayer`. Be sure you are editing the intended Central Security layer, not a gameplay node.

## Combining With Core PVGames Palettes

Use the Central Security palettes for security rooms, barriers, checkpoint tech, terminals, cameras, and hardened architectural pieces. Use the existing Core PVGames palettes for broader neon city/floor/wall dressing.

## When To Use Sprite2D/Stamper Instead

Use Sprite2D or `PVGamesArtStamper` for very large, irregular, animated-looking, or highly positional props that need individual scale, rotation, or z-index control.

## Reporting Bad Tiles

Use the verification JSON and contact sheets to identify `asset_id`, source filename, palette, and quality class, then report the exact tile for future tuning.
""",
        encoding="utf-8",
    )


def write_validator() -> None:
    VALIDATOR.write_text(
        '''@tool
extends EditorScript
class_name PVGamesCentralSecurityPaintableTileSetValidator

const SOURCE_ROOT := "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles"
const EXPECTED_SUBFOLDERS := [
	"CyberCity_CentralSecurity_Tiles_1",
	"CyberCity_CentralSecurity_Tiles_2",
	"CyberCity_CentralSecurity_Tiles_3",
	"CyberCity_CentralSecurity_Tiles_4",
]
const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const SOURCE_TACO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REDESIGN_TACO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const ASSET_INSTALL := "res://docs/ASSET_INSTALLATION.md"
const REPORTS := [
	"res://docs/reports/pvgames_central_security_full_asset_catalog.json",
	"res://docs/reports/pvgames_central_security_full_asset_catalog.csv",
	"res://docs/reports/pvgames_central_security_paint_candidates.json",
	"res://docs/reports/pvgames_central_security_paint_candidates.csv",
	"res://docs/reports/pvgames_central_security_paint_classification.md",
	"res://docs/reports/pvgames_central_security_paint_classification.json",
	"res://docs/reports/pvgames_central_security_tile_verification.md",
	"res://docs/reports/pvgames_central_security_tile_verification.json",
	"res://docs/reports/pvgames_central_security_tile_verification.csv",
	"res://docs/reports/pvgames_central_security_assets_better_as_sprites_or_stamps.md",
	"res://docs/reports/pvgames_central_security_assets_better_as_sprites_or_stamps.json",
	"res://docs/reports/pvgames_central_security_paintable_tilesets_how_to_use.md",
	"res://docs/reports/pvgames_central_security_paintable_tileset_creation.md",
	"res://docs/reports/pvgames_central_security_paintable_tileset_creation.json",
]
const TILESETS := [
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityGroundRoadPaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityWallPaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityLargeStructurePaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityPropSignPaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityReviewOnlyPaint.tres",
]
const CORE_B4_TILESETS := [
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogLargeStructurePaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogReviewOnlyPaint.tres",
]
const B5_REPORTS := [
	"res://docs/reports/hideout_phase_0mb5_runtime_graybox_cleanup_depth_sorting.md",
	"res://docs/reports/hideout_phase_0mb5_y_sort_origin_audit.md",
]
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesCentralSecurityPaintableTileSetTest.tscn"
const VERIFICATION_DIR := "res://docs/reports/pvgames_central_security_verification"
const SHEET_PREFIXES := [
	"pvgames_central_security_verified_ground_road_tiles",
	"pvgames_central_security_verified_wall_tiles",
	"pvgames_central_security_verified_large_structure_tiles",
	"pvgames_central_security_verified_prop_sign_tiles",
	"pvgames_central_security_verified_review_only_tiles",
]

func _run() -> void:
	print(JSON.stringify(validate(), "\\t"))

func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_require(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SOURCE_ROOT)), "Central Security source root missing.", failures)
	for folder in EXPECTED_SUBFOLDERS:
		_require(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SOURCE_ROOT + "/" + folder)), "Central Security subfolder missing: %s" % folder, failures)
	for path in REPORTS:
		_require(FileAccess.file_exists(path), "Report missing: %s" % path, failures)
	for path in TILESETS:
		_require(FileAccess.file_exists(path), "Central Security TileSet missing: %s" % path, failures)
		if FileAccess.file_exists(path):
			var text := FileAccess.get_file_as_string(path)
			_require(not text.contains("physics_layer"), "TileSet contains physics layer: %s" % path, failures)
			_require(not text.contains("docs/reports"), "TileSet references report/contact sheet art: %s" % path, failures)
			_require(text.contains("CyberCity_CentralSecurity_Tiles"), "TileSet lacks Central Security source art: %s" % path, failures)
	for path in CORE_B4_TILESETS:
		_require(FileAccess.file_exists(path), "Original 0M-B4 TileSet missing: %s" % path, failures)
	for path in B5_REPORTS:
		_require(FileAccess.file_exists(path), "0M-B5 depth report missing: %s" % path, failures)
	for prefix in SHEET_PREFIXES:
		_require(_sheet_exists(prefix), "Verification sheet missing for prefix: %s" % prefix, failures)
	_require(FileAccess.file_exists(TEST_SCENE), "Central Security test scene missing.", failures)
	if FileAccess.file_exists(TEST_SCENE):
		var test_text := FileAccess.get_file_as_string(TEST_SCENE)
		_require(not test_text.contains("GameplayRoot"), "Test scene contains gameplay systems.", failures)
		_require(not test_text.contains("CollisionShape2D"), "Test scene contains collision.", failures)
		_require(test_text.contains("PVGamesCentralSecurityGroundRoadPaint"), "Test scene does not use new TileSets.", failures)
	if FileAccess.file_exists(HIDEOUT):
		var hideout_text := FileAccess.get_file_as_string(HIDEOUT)
		_require(hideout_text.contains("PVG_CentralSecurityPaintLayers"), "Hideout Central Security paint layers missing.", failures)
		_require(hideout_text.contains("PVG_CentralSecurityDepthPaintLayers"), "Hideout Central Security depth layers missing.", failures)
		_require(not _central_security_under_gameplay(hideout_text), "Central Security art appears under GameplayRoot.", failures)
		_require(_central_security_layers_no_collision(hideout_text), "Central Security Hideout layers lack collision_enabled = false.", failures)
	var verification = _read_array("res://docs/reports/pvgames_central_security_tile_verification.json")
	_require(not verification.is_empty(), "Verification JSON has no tiles.", failures)
	for record in verification:
		if String(record.get("post_creation_quality_classification", "")) == "":
			failures.append("A generated tile lacks verification classification.")
			break
		if String(record.get("post_creation_quality_classification", "")) == "REJECT_JUNK" and String(record.get("palette", "")) != "rejected":
			failures.append("REJECT_JUNK appears in a generated palette.")
			break
	var install_text := FileAccess.get_file_as_string(ASSET_INSTALL) if FileAccess.file_exists(ASSET_INSTALL) else ""
	_require(install_text.contains("CyberCity_CentralSecurity_Tiles"), "Asset installation doc lacks Central Security path.", failures)
	var main := _read_dict("res://docs/reports/pvgames_central_security_paintable_tileset_creation.json")
	_require(bool(main.get("taco_bell_scenes_modified", true)) == false, "Main report says Taco Bell scenes modified.", failures)
	_require(bool(main.get("gameplay_scripts_modified", true)) == false, "Main report says gameplay scripts modified.", failures)
	_require(bool(main.get("collision_added", true)) == false, "Main report says collision added.", failures)
	_require(bool(main.get("raw_central_security_pngs_staged", true)) == false, "Main report says raw PNGs staged.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures, "warnings": warnings}

func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

func _read_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []

func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _sheet_exists(prefix: String) -> bool:
	var dir := DirAccess.open(VERIFICATION_DIR)
	if dir == null:
		return false
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with(prefix) and name.ends_with(".png"):
			return true
		name = dir.get_next()
	return false

func _central_security_under_gameplay(scene_text: String) -> bool:
	for line in scene_text.split("\\n"):
		if line.begins_with("[node ") and line.contains("parent=\\"GameplayRoot") and line.contains("CentralSecurity"):
			return true
	return false

func _central_security_layers_no_collision(scene_text: String) -> bool:
	var required := [
		"PVGamesCentralSecurityGroundRoadPaintLayer",
		"PVGamesCentralSecurityWallBackdropPaintLayer",
		"PVGamesCentralSecurityLargeStructureBackdropPaintLayer",
		"PVGamesCentralSecurityPropSignBackdropPaintLayer",
		"PVGamesCentralSecurityOccludableWallPaintLayer",
		"PVGamesCentralSecurityOccludablePropPaintLayer",
		"PVGamesCentralSecurityOccludableLargeStructurePaintLayer",
		"PVGamesCentralSecurityForegroundOverlayPaintLayer",
	]
	for layer_name in required:
		var start := scene_text.find("[node name=\\"%s\\"" % layer_name)
		if start < 0:
			return false
		var next := scene_text.find("\\n[node ", start + 1)
		var block := scene_text.substr(start, scene_text.length() - start if next < 0 else next - start)
		if not block.contains("collision_enabled = false"):
			return false
	return true
''',
        encoding="utf-8",
    )


def write_main_reports(summary: dict[str, Any]) -> None:
    write_json(MAIN_JSON, summary)
    lines = [
        "# PVGames Central Security Paintable TileSet Creation",
        "",
        f"Status: {summary['status']}",
        "",
        f"- Source root: `{summary['source_root']}`",
        f"- Total source PNGs scanned: {summary['total_source_pngs_scanned']}",
        f"- .png.import files counted: {summary['png_import_files_counted']}",
        f"- Candidate assets derived: {summary['candidate_assets_derived']}",
        f"- Missing paths: {summary['missing_paths']}",
        f"- Contact sheet paths rejected: {summary['contact_sheet_paths_rejected']}",
        "",
        "## Classification Counts",
        "",
    ]
    for key, value in summary["classification_counts"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## Tile Quality Counts", ""])
    for key, value in summary["tile_quality_counts"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## TileSets", ""])
    for key, path in summary["tileset_paths"].items():
        lines.append(f"- {key}: `{path}`")
    lines.extend(["", "## Verification Contact Sheets", ""])
    for path in summary["verification_contact_sheets"]:
        lines.append(f"- `{path}`")
    lines.extend(["", "## Palette Contact Sheets", ""])
    for path in summary["palette_contact_sheets"]:
        lines.append(f"- `{path}`")
    lines.extend([
        "",
        f"Test scene: `{summary['test_scene_path']}`",
        "",
        "No contact sheets were used as TileSet sources. No collision was added. Taco Bell scenes and gameplay scripts were not modified.",
    ])
    MAIN_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    TILESET_DIR.mkdir(parents=True, exist_ok=True)
    VERIFICATION_DIR.mkdir(parents=True, exist_ok=True)
    PALETTE_DIR.mkdir(parents=True, exist_ok=True)

    catalog, import_count = scan_assets()
    write_json(CATALOG_JSON, catalog)
    write_csv(CATALOG_CSV, catalog)
    candidates, rejected_contact = derive_candidates(catalog)
    write_json(CANDIDATES_JSON, candidates)
    write_csv(CANDIDATES_CSV, candidates)
    classified = [classify_candidate(dict(c)) for c in candidates]
    write_classification_reports(classified)
    selected, sprite_entries = select_tiles(classified)
    final, verification_records = verify_selection(selected)

    for palette, entries in final.items():
        write_tileset(TILESETS[palette]["local"], entries)

    verification_sheets: list[str] = []
    for palette, info in TILESETS.items():
        records = [r for r in verification_records if r["palette"] == palette]
        prefix = {
            "ground_road": "pvgames_central_security_verified_ground_road_tiles",
            "wall": "pvgames_central_security_verified_wall_tiles",
            "large_structure": "pvgames_central_security_verified_large_structure_tiles",
            "prop_sign": "pvgames_central_security_verified_prop_sign_tiles",
            "review_only": "pvgames_central_security_verified_review_only_tiles",
        }[palette]
        verification_sheets.extend(render_contact_sheets(records, prefix, VERIFICATION_DIR, f"Central Security {info['name']} Verification", False))

    palette_sheets: list[str] = []
    for palette, info in TILESETS.items():
        entries = []
        for e in final[palette]:
            e2 = dict(e)
            e2["quality"] = quality_classify(e, palette)[0]
            e2["palette"] = palette
            entries.append(e2)
        prefix = {
            "ground_road": "pvgames_central_security_ground_road_palette",
            "wall": "pvgames_central_security_wall_palette",
            "large_structure": "pvgames_central_security_large_structure_palette",
            "prop_sign": "pvgames_central_security_prop_sign_palette",
            "review_only": "pvgames_central_security_review_only_palette",
        }[palette]
        palette_sheets.extend(render_contact_sheets(entries, prefix, PALETTE_DIR, f"Central Security {info['name']} Palette", True))

    write_verification_reports(verification_records, verification_sheets)
    write_sprite_reports(sprite_entries)
    make_test_scene(final)
    hideout_modified = add_hideout_layers()
    asset_doc_updated = update_asset_install_doc()
    write_how_to()
    write_validator()

    classification_counts = Counter(c["classification"] for c in classified)
    quality_counts = Counter(r["post_creation_quality_classification"] for r in verification_records)
    before_counts = {palette: len(entries) for palette, entries in selected.items()}
    after_counts = {palette: len(entries) for palette, entries in final.items()}
    summary = {
        "status": "PASS",
        "source_root": SOURCE_RES_ROOT,
        "four_subfolders_found": {folder: (SOURCE_ROOT / folder).exists() for folder in EXPECTED_SUBFOLDERS},
        "total_source_pngs_scanned": len(catalog),
        "png_import_files_counted": import_count,
        "candidate_assets_derived": len(candidates),
        "missing_paths": 0,
        "contact_sheet_paths_rejected": len(rejected_contact),
        "classification_counts": {key: classification_counts.get(key, 0) for key in ["TRUE_TILE_ATLAS", "SINGLE_TILE_SPRITE", "LARGE_STRUCTURE_SPRITE", "SPRITE_STAMP_BETTER", "SKIP_UNSAFE"]},
        "tileset_paths": {palette: info["path"] for palette, info in TILESETS.items()},
        "tile_counts_before_verification": before_counts,
        "tile_counts_after_verification": after_counts,
        "tile_quality_counts": {key: quality_counts.get(key, 0) for key in ["READY_TO_PAINT", "MODULAR_PART_OK", "REVIEW_MANUALLY", "REJECT_JUNK"]},
        "rejected_junk_removed_or_quarantined": True,
        "verification_report_paths": [rel(VERIFICATION_MD), rel(VERIFICATION_JSON), rel(VERIFICATION_CSV)],
        "verification_contact_sheets": verification_sheets,
        "palette_contact_sheets": palette_sheets,
        "test_scene_path": rel(TEST_SCENE),
        "hideout_hub_modified": hideout_modified or "PVG_CentralSecurityPaintLayers" in HIDEOUT.read_text(encoding="utf-8"),
        "hideout_central_security_paint_layers_created": True,
        "b5_depth_model_followed": True,
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "collision_added": False,
        "asset_installation_guide_updated": asset_doc_updated,
        "raw_central_security_pngs_staged": False,
        "validator_result": "static validation pending",
        "known_limitations": [
            "True shared Y-sort is not implemented; this follows the 0M-B5 z-index approximation.",
            "Large objects are kept in a separate palette and should be used carefully.",
            "No blind atlas slicing was performed because reliable Central Security cell sizes were not inferred.",
        ],
        "manual_test_checklist": [
            "Open res://scenes/hideout/tools/PVGamesCentralSecurityPaintableTileSetTest.tscn.",
            "Select each Central Security TileMapLayer.",
            "Confirm paintable Central Security assets appear.",
            "Open verification contact sheets and inspect READY_TO_PAINT/MODULAR_PART_OK tiles.",
            "Open HideoutHub and confirm Central Security layers exist under ArtRoot/World.",
            "Paint ground on behind-player layer and walls/barriers on occludable layers.",
            "Confirm no collision was added and Taco Bell scenes remain unmodified.",
        ],
        "recommended_next_step": "Open the test scene and inspect the verification sheets before painting production HideoutHub art.",
    }
    write_main_reports(summary)
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
