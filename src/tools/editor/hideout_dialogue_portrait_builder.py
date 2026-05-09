"""
Phase 0M-C3 - Hideout Portrait Sheet Slicing + Dialogue Polish

This script scans res://assets/portraits/ for portrait sheets, slices them
into individual portrait regions (preferred 4 cols x 2 rows when sheet
dimensions match the canonical 1456 x 816 layout), generates safe
non-destructive cropped PNG copies and AtlasTexture .tres resources, and
emits the catalog/scan/contact-sheet reports.

It does NOT modify the source PNG files. It does NOT touch gameplay
scripts or scenes. All output goes under:

    res://assets/portraits/generated_slices/
    res://assets/portraits/generated_slices/atlas_textures/
    res://docs/reports/hideout_dialogue_portraits/
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
import sys
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

from PIL import Image, ImageDraw, ImageFont

PROJECT_ROOT = Path(__file__).resolve().parents[3]
PORTRAITS_DIR = PROJECT_ROOT / "assets" / "portraits"
GEN_SLICES_DIR = PORTRAITS_DIR / "generated_slices"
ATLAS_DIR = GEN_SLICES_DIR / "atlas_textures"
REPORT_DIR = PROJECT_ROOT / "docs" / "reports" / "hideout_dialogue_portraits"
CONTACT_SHEETS_DIR = REPORT_DIR / "contact_sheets"

CANONICAL_W = 1456
CANONICAL_H = 816
DEFAULT_COLS = 4
DEFAULT_ROWS = 2

# Stable seed UID prefix for AtlasTexture .tres files. Godot will regenerate
# UIDs on first import; we still write a placeholder so the file is valid.
ATLAS_TRES_HEADER = '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'


@dataclass
class PortraitEntry:
    portrait_id: str
    source_sheet_path: str            # res:// path
    source_sheet_filename: str
    source_sheet_width: int
    source_sheet_height: int
    is_sheet: bool
    columns: int
    rows: int
    row: int
    column: int
    region_x: int
    region_y: int
    region_w: int
    region_h: int
    cropped_png_res_path: str
    atlas_tres_res_path: str
    quality: str
    coverage: float                   # 0..1, fraction of pixels above brightness threshold
    has_visible_content: bool
    suggested_character: str
    notes: str


def res_path(p: Path) -> str:
    rel = p.relative_to(PROJECT_ROOT).as_posix()
    return "res://" + rel


def safe_stem(name: str) -> str:
    stem = Path(name).stem
    # Stable, filesystem friendly stem - shorten brutally long names
    h = hashlib.sha1(stem.encode("utf-8")).hexdigest()[:8]
    short = stem[:80]
    return f"{short}_{h}"


def detect_sheet_layout(width: int, height: int, filename: str) -> tuple[bool, int, int, str]:
    """
    Returns: (is_sheet, cols, rows, notes)

    The policy from the user:
      - Do not assume every file is 4x2 unless dimensions/content support it.
      - If sheet is 1456 x 816 and looks like the screenshot, try 4 columns x 2 rows.
      - If grid detection is uncertain, create review-only candidate slices and report them.
    """
    notes = []
    if width == CANONICAL_W and height == CANONICAL_H:
        # The user-provided canonical layout. We treat as 4x2 by default, but flag
        # any file whose name does NOT clearly look like the standard set.
        notes.append("Canonical 1456x816 sheet; using 4x2 grid as instructed.")
        return True, DEFAULT_COLS, DEFAULT_ROWS, " ".join(notes)
    # Heuristic for other dimensions: if aspect ratio is roughly 16:9 and width
    # is >= 1024, treat as 4x2; otherwise treat as a single portrait.
    aspect = width / max(1, height)
    if width >= 1024 and 1.5 <= aspect <= 2.0:
        notes.append(
            f"Non-canonical sheet {width}x{height}; tentatively sliced as 4x2 - REVIEW MANUALLY."
        )
        return True, DEFAULT_COLS, DEFAULT_ROWS, " ".join(notes)
    notes.append(
        f"Treated as single portrait (dimensions {width}x{height} not a recognised sheet layout)."
    )
    return False, 1, 1, " ".join(notes)


def measure_coverage(im: Image.Image) -> tuple[float, bool]:
    """Return (coverage, has_visible_content)."""
    gray = im.convert("L")
    data = gray.getdata()
    n = len(data)
    if n == 0:
        return 0.0, False
    bright = sum(1 for px in data if 12 < px < 248)
    coverage = bright / n
    return coverage, coverage > 0.05


def quality_for(coverage: float) -> str:
    if coverage < 0.05:
        return "REJECT_BAD_SLICE"
    if coverage < 0.20:
        return "REVIEW_MANUALLY"
    return "READY_PORTRAIT"


def write_atlas_tres(target_path: Path, source_res_path: str,
                     region_x: int, region_y: int, region_w: int, region_h: int) -> None:
    """Write a minimal valid AtlasTexture resource. Godot will assign a UID
    on first import."""
    target_path.parent.mkdir(parents=True, exist_ok=True)
    body = (
        ATLAS_TRES_HEADER
        + f'[ext_resource type="Texture2D" path="{source_res_path}" id="1_src"]\n\n'
        + '[resource]\n'
        + 'atlas = ExtResource("1_src")\n'
        + f'region = Rect2({region_x}, {region_y}, {region_w}, {region_h})\n'
    )
    target_path.write_text(body, encoding="utf-8")


def slice_sheet(source_path: Path) -> list[PortraitEntry]:
    entries: list[PortraitEntry] = []
    img = Image.open(source_path).convert("RGBA")
    width, height = img.size
    is_sheet, cols, rows, layout_notes = detect_sheet_layout(width, height, source_path.name)
    cell_w = width // cols
    cell_h = height // rows
    stem = safe_stem(source_path.name)
    sheet_res_path = res_path(source_path)

    for r in range(rows):
        for c in range(cols):
            x = c * cell_w
            y = r * cell_h
            region = img.crop((x, y, x + cell_w, y + cell_h))
            coverage, visible = measure_coverage(region)
            quality = quality_for(coverage)
            portrait_id = f"portrait_{stem}_r{r}_c{c}"

            cropped_path = GEN_SLICES_DIR / f"{portrait_id}.png"
            cropped_path.parent.mkdir(parents=True, exist_ok=True)
            region.save(cropped_path, format="PNG")

            atlas_path = ATLAS_DIR / f"{portrait_id}.tres"
            write_atlas_tres(atlas_path, sheet_res_path, x, y, cell_w, cell_h)

            entry_notes = layout_notes
            if not is_sheet:
                entry_notes += " | Whole image was treated as a single portrait."
            entries.append(
                PortraitEntry(
                    portrait_id=portrait_id,
                    source_sheet_path=sheet_res_path,
                    source_sheet_filename=source_path.name,
                    source_sheet_width=width,
                    source_sheet_height=height,
                    is_sheet=is_sheet,
                    columns=cols,
                    rows=rows,
                    row=r,
                    column=c,
                    region_x=x,
                    region_y=y,
                    region_w=cell_w,
                    region_h=cell_h,
                    cropped_png_res_path=res_path(cropped_path),
                    atlas_tres_res_path=res_path(atlas_path),
                    quality=quality,
                    coverage=round(coverage, 4),
                    has_visible_content=visible,
                    suggested_character="",
                    notes=entry_notes,
                )
            )
    return entries


def build_contact_sheet(entries: list[PortraitEntry]) -> Path:
    cells = [e for e in entries if e.quality != "REJECT_BAD_SLICE"]
    if not cells:
        cells = list(entries)
    cols = 4
    rows = (len(cells) + cols - 1) // cols
    cell_w = 256
    cell_h = 256
    label_h = 64
    pad = 8
    sheet_w = cols * (cell_w + pad) + pad
    sheet_h = rows * (cell_h + label_h + pad) + pad + 80
    sheet = Image.new("RGB", (sheet_w, sheet_h), (16, 18, 26))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
        title_font = ImageFont.truetype("arial.ttf", 22)
    except Exception:
        font = ImageFont.load_default()
        title_font = font

    draw.text((pad, pad),
              "0M-C3 Portrait Slices Contact Sheet",
              fill=(255, 220, 180), font=title_font)
    draw.text((pad, pad + 28),
              "Generated review sheet only - do not use this contact sheet as source art.",
              fill=(255, 120, 120), font=font)

    for idx, e in enumerate(cells):
        col = idx % cols
        row = idx // cols
        x = pad + col * (cell_w + pad)
        y = 80 + row * (cell_h + label_h + pad)
        png_path = PROJECT_ROOT / e.cropped_png_res_path[len("res://"):]
        try:
            tile = Image.open(png_path).convert("RGB")
            tile.thumbnail((cell_w, cell_h))
            ox = x + (cell_w - tile.width) // 2
            oy = y + (cell_h - tile.height) // 2
            sheet.paste(tile, (ox, oy))
        except Exception as ex:
            draw.rectangle([x, y, x + cell_w, y + cell_h], outline=(255, 100, 100))
            draw.text((x + 8, y + 8), f"ERR: {ex}", fill=(255, 200, 200), font=font)

        text_y = y + cell_h + 4
        suggested = f" -> {e.suggested_character}" if e.suggested_character else ""
        draw.text((x, text_y),
                  e.portrait_id,
                  fill=(220, 235, 255), font=font)
        draw.text((x, text_y + 16),
                  f"r{e.row} c{e.column}  q={e.quality}{suggested}",
                  fill=(170, 200, 230), font=font)
        draw.text((x, text_y + 32),
                  e.source_sheet_filename[:40],
                  fill=(140, 160, 190), font=font)

    out = REPORT_DIR / "portrait_slices_contact_sheet.png"
    sheet.save(out)
    return out


def assign_characters(entries: list[PortraitEntry]) -> dict:
    """
    Use the visual review notes recorded by the developer to map specific
    sliced portraits to character roles. The IDs below are stable because
    they are derived deterministically from the source filenames.
    """
    by_id = {e.portrait_id: e for e in entries}

    def find_first(predicate) -> Optional[str]:
        for e in entries:
            if predicate(e):
                return e.portrait_id
        return None

    def from_sheet(sheet_token: str, row: int, col: int) -> Optional[str]:
        for e in entries:
            if sheet_token in e.source_sheet_filename and e.row == row and e.column == col:
                return e.portrait_id
        return None

    assignments = {
        # Jake: brown-haired suited man with stubble (tired but kind),
        # WHITE_B 069c08a9 sheet, top row middle-right.
        "jake": from_sheet("069c08a9", 0, 2),
        # Parmida / Mere: kind, intelligent hooded woman with pink eyes,
        # WHITE_B 069c08a9 _2 sheet, top row col 1.
        "parmida": from_sheet("069c08a9-90d0-4b77-bb2d-889d27000089_2",
                              0, 1),
        # Louis: bald guy with sunglasses, professorial-but-shady,
        # WHITE_B 069c08a9 _0 sheet, bottom row col 0.
        "louis": from_sheet("069c08a9-90d0-4b77-bb2d-889d27000089_0",
                            1, 0),
    }
    # Mere shares Parmida's portrait by default.
    assignments["mere"] = assignments.get("parmida")

    # Bentley: there is no dog portrait in the pack. Leave unassigned;
    # the registry will fall back to a generated placeholder.
    assignments["bentley"] = None

    # Fallback portrait: pick a neutral hooded figure if available, else
    # the first READY_PORTRAIT we find.
    fallback = from_sheet("069c08a9-90d0-4b77-bb2d-889d27000089_2", 0, 0)
    if fallback is None:
        fallback = find_first(lambda e: e.quality == "READY_PORTRAIT")
    assignments["fallback"] = fallback

    # Stamp suggested_character back on the entries
    suggested_for: dict[str, str] = {}
    for role, pid in assignments.items():
        if pid and pid in by_id:
            cur = suggested_for.get(pid, "")
            suggested_for[pid] = (cur + " / " + role).strip(" /") if cur else role
    for e in entries:
        if e.portrait_id in suggested_for:
            e.suggested_character = suggested_for[e.portrait_id]
    return assignments


def make_bentley_placeholder() -> Path:
    """Generate a simple Bentley placeholder card so the registry has
    something safe to fall back to until a real dog portrait is added."""
    target = GEN_SLICES_DIR / "portrait_bentley_placeholder.png"
    img = Image.new("RGBA", (256, 256), (12, 14, 20, 255))
    draw = ImageDraw.Draw(img)
    try:
        big = ImageFont.truetype("arial.ttf", 36)
        small = ImageFont.truetype("arial.ttf", 14)
    except Exception:
        big = ImageFont.load_default()
        small = big
    draw.rectangle([4, 4, 251, 251], outline=(120, 180, 255, 255), width=3)
    draw.text((36, 70), "BENTLEY", fill=(220, 235, 255), font=big)
    draw.text((36, 120), "(placeholder portrait)", fill=(180, 200, 230), font=small)
    draw.text((36, 150), "Black Shiba Inu", fill=(180, 200, 230), font=small)
    draw.text((36, 170), "Tiny king. Snack-motivated.", fill=(180, 200, 230), font=small)
    img.save(target)
    return target


def make_fallback_placeholder() -> Path:
    target = GEN_SLICES_DIR / "portrait_fallback_silhouette.png"
    img = Image.new("RGBA", (256, 256), (10, 12, 18, 255))
    draw = ImageDraw.Draw(img)
    try:
        big = ImageFont.truetype("arial.ttf", 28)
        small = ImageFont.truetype("arial.ttf", 14)
    except Exception:
        big = ImageFont.load_default()
        small = big
    draw.rectangle([4, 4, 251, 251], outline=(150, 100, 220, 255), width=3)
    draw.ellipse([90, 50, 166, 126], fill=(38, 42, 64, 255), outline=(160, 200, 255, 255))
    draw.rectangle([60, 130, 196, 230], fill=(28, 32, 50, 255), outline=(160, 200, 255, 255))
    draw.text((46, 235 - 30), "Unknown speaker", fill=(220, 220, 235), font=small)
    img.save(target)
    return target


def write_reports(entries: list[PortraitEntry], assignments: dict,
                  contact_sheet_path: Path,
                  bentley_placeholder_path: Path,
                  fallback_placeholder_path: Path) -> dict:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    sheets: dict[str, dict] = {}
    for e in entries:
        s = sheets.setdefault(e.source_sheet_path, {
            "source_sheet_path": e.source_sheet_path,
            "filename": e.source_sheet_filename,
            "width": e.source_sheet_width,
            "height": e.source_sheet_height,
            "is_sheet": e.is_sheet,
            "columns": e.columns,
            "rows": e.rows,
            "slice_count": 0,
            "ready_count": 0,
            "review_count": 0,
            "rejected_count": 0,
            "notes": e.notes,
        })
        s["slice_count"] += 1
        if e.quality == "READY_PORTRAIT":
            s["ready_count"] += 1
        elif e.quality == "REVIEW_MANUALLY":
            s["review_count"] += 1
        elif e.quality == "REJECT_BAD_SLICE":
            s["rejected_count"] += 1

    sheet_scan = {
        "phase": "0M-C3",
        "scan_root": "res://assets/portraits/",
        "sheets": list(sheets.values()),
        "skipped_subfolders": ["Don't like"],
        "policy": (
            "Top-level portrait sheets only. Files inside the 'Don't like' "
            "subfolder are intentionally skipped."
        ),
    }
    (REPORT_DIR / "phase0mc3_portrait_sheet_scan.json").write_text(
        json.dumps(sheet_scan, indent=2), encoding="utf-8"
    )
    md_lines = ["# Phase 0M-C3 Portrait Sheet Scan", ""]
    md_lines.append(f"- Scan root: `{sheet_scan['scan_root']}`")
    md_lines.append(f"- Skipped subfolders: {sheet_scan['skipped_subfolders']}")
    md_lines.append("")
    md_lines.append("| Sheet | Size | Sheet? | Cols x Rows | Ready | Review | Rejected | Notes |")
    md_lines.append("|---|---|---|---|---|---|---|---|")
    for s in sheet_scan["sheets"]:
        md_lines.append(
            f"| `{s['filename']}` | {s['width']}x{s['height']} | "
            f"{'yes' if s['is_sheet'] else 'no'} | {s['columns']}x{s['rows']} | "
            f"{s['ready_count']} | {s['review_count']} | {s['rejected_count']} | "
            f"{s['notes']} |"
        )
    (REPORT_DIR / "phase0mc3_portrait_sheet_scan.md").write_text(
        "\n".join(md_lines), encoding="utf-8"
    )

    catalog = {
        "phase": "0M-C3",
        "portrait_count": len(entries),
        "ready_count": sum(1 for e in entries if e.quality == "READY_PORTRAIT"),
        "review_count": sum(1 for e in entries if e.quality == "REVIEW_MANUALLY"),
        "rejected_count": sum(1 for e in entries if e.quality == "REJECT_BAD_SLICE"),
        "entries": [asdict(e) for e in entries],
        "assignments": assignments,
        "fallback_portrait_png": res_path(fallback_placeholder_path),
        "bentley_placeholder_png": res_path(bentley_placeholder_path),
        "contact_sheet": res_path(contact_sheet_path),
    }
    (REPORT_DIR / "phase0mc3_portrait_slice_catalog.json").write_text(
        json.dumps(catalog, indent=2), encoding="utf-8"
    )
    md = ["# Phase 0M-C3 Portrait Slice Catalog", ""]
    md.append(f"- Total slices: {catalog['portrait_count']}")
    md.append(f"- READY_PORTRAIT: {catalog['ready_count']}")
    md.append(f"- REVIEW_MANUALLY: {catalog['review_count']}")
    md.append(f"- REJECT_BAD_SLICE: {catalog['rejected_count']}")
    md.append(f"- Contact sheet (review only): `{catalog['contact_sheet']}`")
    md.append("")
    md.append(
        "All cropped PNGs and AtlasTextures are non-destructive copies. "
        "Source sheets in `res://assets/portraits/` were NOT modified."
    )
    md.append("")
    md.append("## Character assignments")
    md.append("")
    md.append("| Role | Portrait ID |")
    md.append("|---|---|")
    for role in ["jake", "parmida", "mere", "bentley", "louis", "fallback"]:
        md.append(f"| {role} | {assignments.get(role) or '(unassigned)'} |")
    md.append("")
    md.append("## All slices")
    md.append("")
    md.append("| Portrait ID | Quality | Coverage | Source | Row | Col | Cropped PNG | AtlasTexture |")
    md.append("|---|---|---|---|---|---|---|---|")
    for e in entries:
        md.append(
            f"| `{e.portrait_id}` | {e.quality} | {e.coverage:.2f} | "
            f"`{e.source_sheet_filename}` | {e.row} | {e.column} | "
            f"`{e.cropped_png_res_path}` | `{e.atlas_tres_res_path}` |"
        )
    (REPORT_DIR / "phase0mc3_portrait_slice_catalog.md").write_text(
        "\n".join(md), encoding="utf-8"
    )

    csv_path = REPORT_DIR / "phase0mc3_portrait_slice_catalog.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "portrait_id", "quality", "coverage", "row", "column",
            "region_x", "region_y", "region_w", "region_h",
            "source_sheet_path", "cropped_png_res_path",
            "atlas_tres_res_path", "suggested_character", "notes",
        ])
        for e in entries:
            writer.writerow([
                e.portrait_id, e.quality, e.coverage, e.row, e.column,
                e.region_x, e.region_y, e.region_w, e.region_h,
                e.source_sheet_path, e.cropped_png_res_path,
                e.atlas_tres_res_path, e.suggested_character, e.notes,
            ])

    assignment_md = ["# Phase 0M-C3 Portrait Assignment Report", ""]
    assignment_md.append("Recommended portrait IDs for each speaker:")
    assignment_md.append("")
    assignment_md.append("| Speaker | Portrait ID | Source sheet | Quality |")
    assignment_md.append("|---|---|---|---|")
    by_id = {e.portrait_id: e for e in entries}
    for role in ["jake", "parmida", "mere", "bentley", "louis", "fallback"]:
        pid = assignments.get(role)
        if pid and pid in by_id:
            e = by_id[pid]
            assignment_md.append(
                f"| {role} | `{pid}` | `{e.source_sheet_filename}` | {e.quality} |"
            )
        else:
            note = ("uses generated placeholder PNG"
                    if role == "bentley" else "(unassigned)")
            assignment_md.append(f"| {role} | {note} | - | - |")
    assignment_md.append("")
    assignment_md.append("## Notes")
    assignment_md.append("- Mere uses the same portrait as Parmida by design (same character).")
    assignment_md.append(
        "- No dog portrait was found in the source pack, so Bentley falls back to a "
        "generated placeholder card. This is documented as a known limitation."
    )
    (REPORT_DIR / "phase0mc3_portrait_assignment_report.md").write_text(
        "\n".join(assignment_md), encoding="utf-8"
    )
    (REPORT_DIR / "phase0mc3_portrait_assignment_report.json").write_text(
        json.dumps({
            "phase": "0M-C3",
            "assignments": assignments,
            "missing_portrait_assets": [
                {"role": "bentley", "reason": "No dog portrait in source pack",
                 "fallback": res_path(bentley_placeholder_path)},
            ],
        }, indent=2),
        encoding="utf-8",
    )
    return catalog


def main() -> int:
    if not PORTRAITS_DIR.exists():
        print(f"ERROR: portrait folder missing: {PORTRAITS_DIR}", file=sys.stderr)
        return 2

    GEN_SLICES_DIR.mkdir(parents=True, exist_ok=True)
    ATLAS_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    CONTACT_SHEETS_DIR.mkdir(parents=True, exist_ok=True)

    sources = sorted([p for p in PORTRAITS_DIR.iterdir()
                      if p.is_file() and p.suffix.lower() == ".png"])
    print(f"Found {len(sources)} top-level portrait PNGs (sub-folders skipped).")

    all_entries: list[PortraitEntry] = []
    for p in sources:
        print(f"  - slicing {p.name} ...")
        all_entries.extend(slice_sheet(p))

    assignments = assign_characters(all_entries)

    bentley_placeholder = make_bentley_placeholder()
    fallback_placeholder = make_fallback_placeholder()

    contact_sheet = build_contact_sheet(all_entries)

    catalog = write_reports(all_entries, assignments, contact_sheet,
                            bentley_placeholder, fallback_placeholder)

    print(json.dumps({
        "ok": True,
        "portrait_count": catalog["portrait_count"],
        "ready_count": catalog["ready_count"],
        "review_count": catalog["review_count"],
        "rejected_count": catalog["rejected_count"],
        "assignments": assignments,
        "contact_sheet": catalog["contact_sheet"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
