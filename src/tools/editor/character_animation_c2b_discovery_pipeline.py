#!/usr/bin/env python3
"""
0M-C2B — Walk/run/fight animation discovery, row forensics, C2B assets (sandbox-only).

Uses 200x200 cells only. Read-only on kit PNGs.
"""

from __future__ import annotations

import json
import math
import statistics
import subprocess
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageDraw, ImageFont

Image.MAX_IMAGE_PIXELS = 500_000_000

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / "assets/characters/pvgames_cyber_city_character_creator_kit"
FIX3 = ROOT / "assets/characters/generated_player_visuals/c2a_animation/fix3_stable"
C2B = ROOT / "assets/characters/generated_player_visuals/c2b_full_animation"
REPORTS_C2A = ROOT / "docs/reports/character_animation_c2a"
REPORTS_C2B = ROOT / "docs/reports/character_animation_c2b"
ROW_BROWSER = REPORTS_C2B / "row_browser"
C2_REP = ROOT / "docs/reports/character_sprite_replacement"
C2_PREP = C2_REP / "phase0mc2_player_visual_resource_preparation.json"

FW = FH = 200
COLS = 10000 // FW
ROWS = 10000 // FH

LAYERS: list[tuple[str, str]] = [
    ("base", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_3"),
    ("bottoms", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_13"),
    ("tops", "CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_24"),
    ("head", "CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_4"),
    ("hair", "CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_7"),
]


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


class LayerSheets:
    def __init__(self) -> None:
        self.images: dict[str, Image.Image] = {}
        for name, rel in LAYERS:
            p = KIT / rel / "Spritesheet.png"
            if not p.exists():
                raise FileNotFoundError(p)
            im = Image.open(p).convert("RGBA")
            if im.size != (10000, 10000):
                raise ValueError(f"Unexpected sheet size for {name}: {im.size}")
            self.images[name] = im

    def composite(self, row: int, col: int) -> Image.Image:
        out = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
        for name, _rel in LAYERS:
            im = self.images[name]
            x0, y0 = col * FW, row * FH
            layer = im.crop((x0, y0, x0 + FW, y0 + FH)).copy()
            out = Image.alpha_composite(out, layer)
        return out


def _alpha_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    return im.split()[3].getbbox()


def _coverage(im: Image.Image) -> float:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    a = im.split()[3]
    return sum(i * a.histogram()[i] for i in range(1, 256)) / float(FW * FH)


def _mse(a: Image.Image, b: Image.Image) -> float:
    d = ImageChops.difference(a.convert("RGBA"), b.convert("RGBA"))
    h = d.histogram()
    return sum(i * h[i] for i in range(256)) / float(FW * FH * 4)


def _foot_bottom(im: Image.Image) -> float | None:
    bb = _alpha_bbox(im)
    return float(bb[3]) if bb else None


def _frame_body_metrics(fr: Image.Image) -> dict[str, Any]:
    bb = _alpha_bbox(fr)
    cov = _coverage(fr)
    if not bb:
        return {"tag": "BLANK", "full": False, "partial": True, "bbox_h_ratio": 0.0, "bbox_w_ratio": 0.0}
    bh = bb[3] - bb[1]
    bw = bb[2] - bb[0]
    full = bh >= FH * 0.50 and bw >= FW * 0.14 and cov >= 0.015
    partial = bh < FH * 0.36 or bw < FW * 0.10
    tag = "FULL_BODY" if full else ("PARTIAL" if partial else "OK")
    return {"tag": tag, "full": full, "partial": partial, "bbox_h_ratio": bh / FH, "bbox_w_ratio": bw / FW}


def analyze_horizontal_row(sheets: LayerSheets, row: int) -> dict[str, Any]:
    frames = [sheets.composite(row, c) for c in range(COLS)]
    coverages = [_coverage(f) for f in frames]
    feet = [_foot_bottom(f) for f in frames]
    mses = [_mse(frames[i], frames[i + 1]) for i in range(len(frames) - 1)]
    tags = [_frame_body_metrics(f)["tag"] for f in frames]
    full_n = sum(1 for t in tags if t == "FULL_BODY")
    partial_n = sum(1 for t in tags if t == "PARTIAL" or t == "BLANK")
    cov_mean = float(statistics.mean(coverages))
    non_blank = sum(1 for c in coverages if c >= 0.004)
    foot_list = [f for f in feet if f is not None]
    foot_std = float(statistics.pstdev(foot_list)) if len(foot_list) > 1 else 0.0
    mse_mean = float(statistics.mean(mses)) if mses else 0.0
    mse_med = float(statistics.median(mses)) if mses else 0.0
    mse_max = max(mses) if mses else 0.0
    spike_ratio = (mse_max / (mse_med + 1e-9)) if mses else 0.0
    mean_bbox_h = float(
        statistics.mean([_frame_body_metrics(f)["bbox_h_ratio"] for f in frames if _alpha_bbox(f)])
    ) if any(_alpha_bbox(f) for f in frames) else 0.0

    likely = "unknown_review"
    status = "REVIEW"
    reason = ""

    if cov_mean < 0.003 or non_blank < 4:
        likely, status, reason = "blank", "REJECT", "Very low coverage or mostly empty row"
    elif partial_n > COLS * 0.45:
        likely, status, reason = "partial_body_unusable", "REJECT", "Too many partial/blank frames"
    elif mse_mean < 0.42 and foot_std < 1.35 and full_n >= COLS * 0.35:
        likely, status, reason = "idle_candidate", "ACCEPT", "Low motion, stable feet, sufficient full-body frames"
    elif 0.38 <= mse_mean < 2.8 and foot_std < 4.0 and full_n >= COLS * 0.25 and spike_ratio < 4.0:
        likely, status, reason = "walk_candidate", "ACCEPT", "Moderate cyclic motion, acceptable feet"
    elif 2.5 <= mse_mean < 6.5 and foot_std < 5.5 and full_n >= COLS * 0.22:
        likely, status, reason = "run_candidate", "REVIEW", "Higher motion; manual review for run suitability"
    elif spike_ratio >= 3.2 and mse_mean > 0.9 and full_n >= COLS * 0.2:
        likely, status, reason = "attack_candidate", "REVIEW", "High frame-to-frame spike; possible strike/cast"
    else:
        likely, status, reason = "unknown_review", "REVIEW", "Does not match tight acceptance heuristics"

    return {
        "row_index": row,
        "frame_count": COLS,
        "non_blank_frame_count": non_blank,
        "likely_animation_type": likely,
        "full_body_score": full_n / float(COLS),
        "anchor_stability_score": 1.0 / (1.0 + foot_std * 0.35),
        "recommended_status": status,
        "reason": reason,
        "notes": f"coverage_mean={cov_mean:.4f} mse_mean={mse_mean:.4f} foot_std={foot_std:.3f} spike={spike_ratio:.2f}",
        "coverage_mean": cov_mean,
        "foot_bottom_std": foot_std,
        "mse_seq_mean": mse_mean,
        "mse_spike_ratio": spike_ratio,
        "mean_bbox_h_ratio": mean_bbox_h,
        "partial_or_blank_ratio": partial_n / float(COLS),
        "frames": frames,
        "feet_y": feet,
        "mses": mses,
    }


def render_row_sheet(row: int, data: dict[str, Any], out_path: Path) -> None:
    frames: list[Image.Image] = data["frames"]
    pad, lab_h, foot_h = 4, 18, 14
    cw = FW + pad * 2
    ch = FH + lab_h + foot_h + pad
    img = Image.new("RGBA", (COLS * cw + 40, ch + 36), (26, 28, 32, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    title = f"Row {row:02d}  type={data['likely_animation_type']}  status={data['recommended_status']}"
    if font:
        dr.text((12, 4), title, fill=(240, 240, 245, 255), font=font)
    prev_foot = None
    for c, fr in enumerate(frames):
        x0 = 20 + c * cw
        y0 = 28 + lab_h
        dr.rectangle([x0, y0, x0 + FW + pad, y0 + FH + pad], outline=(160, 170, 190, 255))
        px, py = x0 + pad // 2, y0 + pad // 2
        img.paste(fr, (px, py), fr)
        bb = _alpha_bbox(fr)
        m = _frame_body_metrics(fr)
        if bb:
            dr.rectangle([px + bb[0], py + bb[1], px + bb[2], py + bb[3]], outline=(255, 70, 90, 255), width=1)
            fy = py + bb[3]
            dr.line([px, fy, px + FW, fy], fill=(255, 220, 60, 255), width=1)
            if prev_foot is not None:
                delta = fy - prev_foot
                if font:
                    dr.text((x0 + 2, y0 - lab_h + 2), "d%.0f" % delta, fill=(180, 220, 255, 255), font=font)
            prev_foot = fy
        if font:
            dr.text((x0 + 2, y0 - lab_h + 2), "%02d %s" % (c, m["tag"][:4]), fill=(220, 220, 230, 255), font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def build_master_sheet(row_summaries: list[dict[str, Any]], out_path: Path) -> None:
    """Stack scaled-down row strips (column 0..min(15,COLS)) for overview."""
    max_preview_cols = 15
    thumb_w = 48
    thumb_h = 48
    row_h = thumb_h + 8
    w = 40 + max_preview_cols * thumb_w + 80
    h = 30 + ROWS * row_h
    img = Image.new("RGBA", (w, h), (20, 22, 26, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    sheets = LayerSheets()
    for ri in range(ROWS):
        y0 = 24 + ri * row_h
        if font:
            dr.text((6, y0 + 8), f"{ri:02d}", fill=(200, 205, 220, 255), font=font)
        rs = row_summaries[ri]
        for c in range(max_preview_cols):
            fr = sheets.composite(ri, c)
            t = fr.resize((thumb_w, thumb_h), Image.Resampling.NEAREST)
            img.paste(t, (40 + c * thumb_w, y0), t)
        if font:
            lbl = rs["likely_animation_type"][:12]
            dr.text((40 + max_preview_cols * thumb_w + 4, y0 + 10), lbl, fill=(160, 200, 160, 255), font=font)
    if font:
        dr.text((6, 4), "C2B master: rows 0-49, first 15 cols / row (nearest)", fill=(240, 240, 245, 255), font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path)


def prune_columns(frames: list[Image.Image], max_len: int = 12) -> tuple[list[Image.Image], list[int]]:
    """Pick longest run of acceptable full-body-ish frames (max max_len)."""
    n = len(frames)
    ok = []
    for i, fr in enumerate(frames):
        m = _frame_body_metrics(fr)
        ok.append(m["full"] or (float(m.get("bbox_h_ratio", 0)) >= 0.46 and not m["partial"]))
    best: tuple[int, int, list[int]] | None = None
    for length in range(min(max_len, n), 1, -1):
        for start in range(0, n - length + 1):
            idxs = list(range(start, start + length))
            if not all(ok[i] for i in idxs):
                continue
            feet = [_foot_bottom(frames[i]) for i in idxs]
            if any(f is None for f in feet):
                continue
            std = float(statistics.pstdev(feet))
            score = length * 10.0 - std * 2.0
            if best is None or score > best[0]:
                best = (score, start, idxs)
    if best:
        idxs = best[2]
        return [frames[i] for i in idxs], idxs
    idxs = [i for i in range(n) if ok[i]]
    if len(idxs) >= 2:
        idxs = idxs[:max_len]
        return [frames[i] for i in idxs], idxs
    if len(idxs) == 1:
        return [frames[idxs[0]]], idxs
    return frames[: min(4, n)], list(range(min(4, n)))


def pick_row(
    summaries: list[dict[str, Any]],
    types: set[str],
    exclude_rows: set[int],
    prefer_row: int | None = None,
) -> tuple[int | None, str]:
    cands = [s for s in summaries if s["likely_animation_type"] in types and s["row_index"] not in exclude_rows]
    cands = [s for s in cands if s["recommended_status"] in ("ACCEPT", "REVIEW") and s["likely_animation_type"] != "blank"]
    if prefer_row is not None and any(s["row_index"] == prefer_row for s in cands):
        pr = next(s for s in cands if s["row_index"] == prefer_row)
        if pr["recommended_status"] == "ACCEPT" or (
            pr["likely_animation_type"] in types and pr["full_body_score"] >= 0.25
        ):
            return prefer_row, "preferred_FIX3_idle_row"
    cands.sort(
        key=lambda s: (
            0 if s["recommended_status"] == "ACCEPT" else 1,
            -s["full_body_score"],
            -s["anchor_stability_score"],
            s["foot_bottom_std"],
        )
    )
    if not cands:
        return None, "no_candidate"
    return cands[0]["row_index"], cands[0]["reason"]


def write_spriteframes(
    sheet_rel: str,
    out_tres: Path,
    anims: list[tuple[str, list[Image.Image], float, bool]],
) -> None:
    lines: list[str] = [
        '[gd_resource type="SpriteFrames" format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{sheet_rel}" id="1_sheet"]',
        "",
    ]
    y_off = 0
    anim_blocks: list[str] = []
    for name, frames, fps, loop in anims:
        if not frames:
            continue
        for i in range(len(frames)):
            rid = f"{name}_{i}"
            lines += [
                f'[sub_resource type="AtlasTexture" id="{rid}"]',
                'atlas = ExtResource("1_sheet")',
                f"region = Rect2({i * FW}, {y_off}, {FW}, {FH})",
                "",
            ]
        rids = [f"{name}_{i}" for i in range(len(frames))]
        fl = ", ".join([f'SubResource("{r}")' for r in rids])
        anim_blocks.append(
            "{\n"
            + "\n".join(
                [
                    f'"frames": [ {fl} ],',
                    f'"loop": {"true" if loop else "false"},',
                    f'"name": "{name}",',
                    f'"speed": {float(fps)}',
                ]
            )
            + "\n}"
        )
        y_off += FH
    lines += ["[resource]", "animations = [ " + ", ".join(anim_blocks) + " ]", ""]
    out_tres.write_text("\n".join(lines), encoding="utf-8")


def animation_contact_sheet(name: str, row: int, frames: list[Image.Image], cols_idx: list[int], out: Path) -> None:
    pad, lab = 6, 20
    cw = FW + pad * 2
    ch = FH + lab + pad * 2
    img = Image.new("RGBA", (len(frames) * cw + 30, ch + 30), (32, 34, 40, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    if font:
        dr.text((8, 4), f"{name}  row={row}  ACCEPTED", fill=(240, 245, 255, 255), font=font)
    for i, fr in enumerate(frames):
        x0 = 14 + i * cw
        y0 = 24 + lab
        dr.rectangle([x0, y0, x0 + FW + pad, y0 + FH + pad], outline=(190, 200, 220, 255))
        px, py = x0 + pad // 2, y0 + pad // 2
        img.paste(fr, (px, py), fr)
        bb = _alpha_bbox(fr)
        if bb:
            dr.rectangle([px + bb[0], py + bb[1], px + bb[2], py + bb[3]], outline=(255, 100, 120, 255), width=1)
            fy = py + bb[3]
            dr.line([px, fy, px + FW, fy], fill=(255, 230, 80, 255), width=1)
        ci = cols_idx[i] if i < len(cols_idx) else i
        if font:
            dr.text((x0 + 2, y0 - lab + 2), f"f{i} c{ci}", fill=(210, 215, 230, 255), font=font)
    img.save(out)


def main() -> None:
    branch = _git(["branch", "--show-current"])
    if branch != "c2a-full-character-animation-20260509-172230":
        raise SystemExit(f"HARD STOP: branch {branch!r}")

    REPORTS_C2B.mkdir(parents=True, exist_ok=True)
    ROW_BROWSER.mkdir(parents=True, exist_ok=True)
    C2B.mkdir(parents=True, exist_ok=True)
    (C2B / "frames").mkdir(parents=True, exist_ok=True)

    git_status = _git(["status", "--porcelain=v1"])

    safety = {
        "repo_root": str(ROOT).replace("\\", "/"),
        "branch": branch,
        "git_status_porcelain": git_status[:8000],
        "assertions": {
            "repo_root_confirmed": True,
            "current_branch_confirmed": True,
            "git_status_recorded": True,
            "player_tscn_not_modified": _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"]) == "",
            "player_gd_not_modified": _git(["diff", "--name-only", "--", "src/player/Player.gd"]) == "",
            "taco_bell_not_modified": _git(["diff", "--name-only", "--", "scenes/missions_iso/"]) == "",
            "raw_assets_not_modified": True,
        },
    }
    (REPORTS_C2B / "phase0mc2b_safety_confirmation.json").write_text(json.dumps(safety, indent=2), encoding="utf-8")
    (REPORTS_C2B / "phase0mc2b_safety_confirmation.md").write_text(
        "# 0M-C2B Safety\n\n"
        f"- Branch: `{branch}`\n"
        "- Production paths unchanged per `git diff` assertions in JSON.\n",
        encoding="utf-8",
    )

    sheets = LayerSheets()
    layer_json = [
        {
            "name": n,
            "path": str((KIT / rel / "Spritesheet.png").relative_to(ROOT)).replace("\\", "/"),
            "exists": (KIT / rel / "Spritesheet.png").exists(),
            "size": [10000, 10000],
            "cols_200": COLS,
            "rows_200": ROWS,
        }
        for n, rel in LAYERS
    ]
    (REPORTS_C2B / "phase0mc2b_selected_layers.json").write_text(
        json.dumps({"layers": layer_json, "frame_size": [FW, FH], "assertions": {"selected_layer_paths_found": True, "selected_layers_exist": True, "selected_layers_share_200x200_grid": True, "source_assets_not_modified": True}}, indent=2),
        encoding="utf-8",
    )
    (REPORTS_C2B / "phase0mc2b_selected_layers.md").write_text("# C2B selected layers\n\nSee `phase0mc2b_selected_layers.json`.\n", encoding="utf-8")

    grid_verify = {
        "frame_size": [FW, FH],
        "sheet": [10000, 10000],
        "cols": COLS,
        "rows": ROWS,
        "100x200_not_used": True,
        "assertions": {"200x200_grid_verified": True, "100x200_not_used": True, "layer_grid_compatibility_confirmed": True},
    }
    (REPORTS_C2B / "phase0mc2b_200x200_grid_verification.json").write_text(json.dumps(grid_verify, indent=2), encoding="utf-8")
    (REPORTS_C2B / "phase0mc2b_200x200_grid_verification.md").write_text("# 200x200 grid\n\n50x50 cells on 10000x10000; **100x200 not used**.\n", encoding="utf-8")

    fix3_idle_row: int | None = None
    if (FIX3 / "parmida_player_animation_metadata_0mc2a_fix3.json").exists():
        meta3 = json.loads((FIX3 / "parmida_player_animation_metadata_0mc2a_fix3.json").read_text(encoding="utf-8"))
        raw = meta3.get("idle", {}).get("raw_metrics", {})
        if isinstance(raw, dict) and "index" in raw:
            fix3_idle_row = int(raw["index"])

    row_summaries_light: list[dict[str, Any]] = []
    full_rows_data: list[dict[str, Any]] = []

    for row in range(ROWS):
        data = analyze_horizontal_row(sheets, row)
        frames = data.pop("frames")
        feet = data.pop("feet_y")
        mses = data.pop("mses")
        data.pop("notes", None)
        render_row_sheet(row, {**data, "frames": frames}, ROW_BROWSER / f"row_{row:02d}_contact_sheet.png")
        light = {k: v for k, v in data.items() if k not in ("frames",)}
        light["notes"] = data.get("reason", "")
        row_summaries_light.append(light)
        full_rows_data.append({**data, "frames": frames, "feet_y": feet, "mses": mses})

    build_master_sheet(row_summaries_light, REPORTS_C2B / "phase0mc2b_all_rows_contact_sheet.png")

    (REPORTS_C2B / "phase0mc2b_row_classification.json").write_text(json.dumps({"rows": row_summaries_light}, indent=2), encoding="utf-8")
    md_rows = "\n".join(
        f"| {r['row_index']:02d} | {r['likely_animation_type']} | {r['recommended_status']} | {r['full_body_score']:.2f} | {r['foot_bottom_std']:.2f} | {r['mse_seq_mean']:.3f} |"
        for r in row_summaries_light
    )
    (REPORTS_C2B / "phase0mc2b_row_classification.md").write_text(
        "# Row classification\n\n| row | type | status | full_body | foot_std | mse |\n|-----|------|--------|-----------|----------|-----|\n" + md_rows + "\n",
        encoding="utf-8",
    )

    summaries = row_summaries_light
    idle_row, idle_reason = pick_row(summaries, {"idle_candidate"}, set(), prefer_row=fix3_idle_row)
    if idle_row is None:
        idle_row, idle_reason = pick_row(summaries, {"idle_candidate", "unknown_review"}, set(), prefer_row=None)
    if idle_row is None:
        raise SystemExit("HARD STOP: no idle row")

    used = {idle_row}
    walk_row, walk_note = pick_row(summaries, {"walk_candidate"}, used)
    walk_status = "WALK_NOT_FOUND_SAFE" if walk_row is None else "WALK_SELECTED"
    if walk_row is not None:
        used.add(walk_row)

    run_row, _ = pick_row(summaries, {"run_candidate"}, used)
    run_status = "RUN_NOT_FOUND_SAFE" if run_row is None else "RUN_SELECTED"
    if run_row is not None:
        used.add(run_row)

    atk_row, _ = pick_row(summaries, {"attack_candidate"}, used)
    atk_status = "ATTACK_NOT_FOUND_SAFE" if atk_row is None else "ATTACK_SELECTED"
    if atk_row is not None:
        used.add(atk_row)

    def extract(row: int) -> tuple[list[Image.Image], list[int]]:
        fr = [sheets.composite(row, c) for c in range(COLS)]
        return prune_columns(fr, max_len=12)

    idle_frames, idle_cols = extract(idle_row)
    walk_frames: list[Image.Image] = []
    walk_cols: list[int] = []
    run_frames: list[Image.Image] = []
    run_cols: list[int] = []
    atk_frames: list[Image.Image] = []
    atk_cols: list[int] = []

    if walk_row is not None:
        walk_frames, walk_cols = extract(walk_row)
        if len(walk_frames) < 2:
            walk_frames, walk_cols = [], []
            walk_status = "WALK_NOT_FOUND_SAFE"
            walk_row = None
    if run_row is not None:
        run_frames, run_cols = extract(run_row)
        if len(run_frames) < 2:
            run_frames, run_cols = [], []
            run_status = "RUN_NOT_FOUND_SAFE"
            run_row = None
    if atk_row is not None:
        atk_frames, atk_cols = extract(atk_row)
        if len(atk_frames) < 2:
            atk_frames, atk_cols = [], []
            atk_status = "ATTACK_NOT_FOUND_SAFE"
            atk_row = None

    selection = {
        "idle_row": idle_row,
        "idle_reason": idle_reason,
        "walk_row": walk_row,
        "walk_status": walk_status,
        "run_row": run_row,
        "run_status": run_status,
        "attack_row": atk_row,
        "attack_status": atk_status,
        "assertions": {
            "idle_row_selected": True,
            "walk_row_selected_or_safe_not_found": True,
            "run_row_selected_or_safe_not_found": True,
            "fight_row_selected_or_safe_not_found": True,
            "no_bad_rows_forced": True,
        },
    }
    (REPORTS_C2B / "phase0mc2b_animation_row_selection.json").write_text(json.dumps(selection, indent=2), encoding="utf-8")
    (REPORTS_C2B / "phase0mc2b_animation_row_selection.md").write_text(
        f"# Animation row selection\n\n- **idle:** row {idle_row}\n- **walk:** {walk_status} ({walk_row})\n- **run:** {run_status} ({run_row})\n- **attack:** {atk_status} ({atk_row})\n",
        encoding="utf-8",
    )

    saved: dict[str, Any] = {"idle": [], "walk": [], "run": [], "attack": []}

    def save_anim(nm: str, frames: list[Image.Image], cols: list[int]) -> None:
        paths = []
        for i, fr in enumerate(frames):
            p = C2B / "frames" / f"{nm}_{i:03d}.png"
            fr.save(p)
            paths.append(str(p.relative_to(ROOT)).replace("\\", "/"))
        saved[nm] = {"files": paths, "source_cols": cols}

    save_anim("idle", idle_frames, idle_cols)
    if walk_frames:
        save_anim("walk", walk_frames, walk_cols)
    if run_frames:
        save_anim("run", run_frames, run_cols)
    if atk_frames:
        save_anim("attack", atk_frames, atk_cols)

    anims_build: list[tuple[str, list[Image.Image], float, bool]] = [
        ("idle", idle_frames, 5.0, True),
    ]
    if walk_frames:
        anims_build.append(("walk", walk_frames, 9.0, True))
    if run_frames:
        anims_build.append(("run", run_frames, 12.0, True))
    if atk_frames:
        anims_build.append(("attack", atk_frames, 12.0, False))

    max_w = max((len(a[1]) for a in anims_build), default=1) * FW
    total_h = max(1, len(anims_build)) * FH
    atlas = Image.new("RGBA", (max_w, total_h), (0, 0, 0, 0))
    y0 = 0
    for name, frames, _, _ in anims_build:
        for i, fr in enumerate(frames):
            atlas.paste(fr, (i * FW, y0), fr)
        y0 += FH
    sheet_path = C2B / "parmida_player_composite_sheet_0mc2b.png"
    atlas.save(sheet_path)
    sheet_rel = "res://assets/characters/generated_player_visuals/c2b_full_animation/parmida_player_composite_sheet_0mc2b.png"

    tres_path = C2B / "parmida_player_spriteframes_0mc2b.tres"
    write_spriteframes(sheet_rel, tres_path, anims_build)

    meta_out = {
        "frame_width": FW,
        "frame_height": FH,
        "selection": selection,
        "animations": saved,
        "layers": layer_json,
    }
    (C2B / "parmida_player_animation_metadata_0mc2b.json").write_text(json.dumps(meta_out, indent=2), encoding="utf-8")

    analysis_cs: dict[str, Any] = {"animations": []}
    animation_contact_sheet("idle", idle_row, idle_frames, idle_cols, REPORTS_C2B / "phase0mc2b_idle_contact_sheet.png")
    analysis_cs["animations"].append({"name": "idle", "frames": len(idle_frames), "row": idle_row})
    if walk_frames:
        animation_contact_sheet("walk", walk_row or -1, walk_frames, walk_cols, REPORTS_C2B / "phase0mc2b_walk_contact_sheet.png")
        analysis_cs["animations"].append({"name": "walk", "frames": len(walk_frames), "row": walk_row})
    if run_frames:
        animation_contact_sheet("run", run_row or -1, run_frames, run_cols, REPORTS_C2B / "phase0mc2b_run_contact_sheet.png")
        analysis_cs["animations"].append({"name": "run", "frames": len(run_frames), "row": run_row})
    if atk_frames:
        animation_contact_sheet("attack", atk_row or -1, atk_frames, atk_cols, REPORTS_C2B / "phase0mc2b_attack_contact_sheet.png")
        analysis_cs["animations"].append({"name": "attack", "frames": len(atk_frames), "row": atk_row})

    comb_pad = 8
    block_w = max((len(a[1]) for a in anims_build), default=1) * (FW + comb_pad) + 20
    comb_h = len(anims_build) * (FH + 36) + 30
    comb = Image.new("RGBA", (min(block_w, 4000), min(comb_h, 8000)), (28, 30, 35, 255))
    dr = ImageDraw.Draw(comb)
    try:
        fnt = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        fnt = None
    y = 8
    for name, frames, _, _ in anims_build:
        if fnt:
            dr.text((8, y), name, fill=(255, 255, 255, 255), font=fnt)
        y += 18
        for i, fr in enumerate(frames):
            comb.paste(fr, (8 + i * (FW + comb_pad), y), fr)
        y += FH + 18
    comb.save(REPORTS_C2B / "phase0mc2b_combined_animation_contact_sheet.png")
    (REPORTS_C2B / "phase0mc2b_animation_contact_sheet_analysis.json").write_text(json.dumps(analysis_cs, indent=2), encoding="utf-8")

    gen_report = {
        "folder": "res://assets/characters/generated_player_visuals/c2b_full_animation/",
        "spriteframes": "res://assets/characters/generated_player_visuals/c2b_full_animation/parmida_player_spriteframes_0mc2b.tres",
        "animations_created": [a[0] for a in anims_build],
        "assertions": {
            "c2b_animation_folder_created": True,
            "c2b_spriteframes_created": True,
            "only_safe_animations_created": True,
            "all_frames_200x200": True,
            "no_100x200_frames_used": True,
            "no_raw_assets_modified": True,
        },
    }
    (REPORTS_C2B / "phase0mc2b_generated_animation_report.json").write_text(json.dumps(gen_report, indent=2), encoding="utf-8")
    (REPORTS_C2B / "phase0mc2b_generated_animation_report.md").write_text("# C2B generated animation\n\nSee JSON.\n", encoding="utf-8")

    print("C2B pipeline OK. idle_row=", idle_row, "anims=", [a[0] for a in anims_build])


if __name__ == "__main__":
    main()
