#!/usr/bin/env python3
"""
0M-C2A-FIX3 — Frame-size forensics (100x200 vs 200x200) + idle-first fix3_stable rebuild.

Sandbox-only outputs under assets/.../c2a_animation/fix3_stable/ and docs/reports/character_animation_c2a/.
Does not modify raw PVGames kit PNGs.
"""

from __future__ import annotations

import json
import math
import statistics
import subprocess
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageDraw, ImageFont

Image.MAX_IMAGE_PIXELS = 200_000_000

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / "assets/characters/pvgames_cyber_city_character_creator_kit"
C2A = ROOT / "assets/characters/generated_player_visuals/c2a_animation"
FIX2 = C2A / "fix2_rebuilt"
FIX3 = C2A / "fix3_stable"
REPORTS = ROOT / "docs/reports/character_animation_c2a"
C2_REP = ROOT / "docs/reports/character_sprite_replacement"
C2_PREP = C2_REP / "phase0mc2_player_visual_resource_preparation.json"
C2_SLICING = C2_REP / "phase0mc2_spritesheet_slicing_report.json"
N_STRIP = 10


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


@dataclass
class GridConfig:
    fw: int
    fh: int

    @property
    def cols(self) -> int:
        return 10000 // self.fw

    @property
    def rows(self) -> int:
        return 10000 // self.fh


@dataclass
class StripMetrics:
    orientation: str
    index: int
    coverage_mean: float
    foot_bottom_std: float
    mse_seq_mean: float
    score: float
    rejected: str


class LayerSheets:
    def __init__(self, cfg: GridConfig) -> None:
        self.cfg = cfg
        self.images: dict[str, Image.Image] = {}
        for name, rel in LAYERS:
            p = KIT / rel / "Spritesheet.png"
            if not p.exists():
                raise FileNotFoundError(p)
            im = Image.open(p).convert("RGBA")
            if im.size != (10000, 10000):
                raise ValueError(f"Unexpected sheet size for {name}: {im.size}")
            self.images[name] = im

    def crop_cell(self, name: str, row: int, col: int) -> Image.Image:
        im = self.images[name]
        fw, fh = self.cfg.fw, self.cfg.fh
        x0 = col * fw
        y0 = row * fh
        return im.crop((x0, y0, x0 + fw, y0 + fh)).copy()

    def composite(self, row: int, col: int) -> Image.Image:
        fw, fh = self.cfg.fw, self.cfg.fh
        out = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        for name, _rel in LAYERS:
            layer = self.crop_cell(name, row, col)
            out = Image.alpha_composite(out, layer)
        return out


def _alpha_bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    a = im.split()[3]
    return a.getbbox()


def _coverage(im: Image.Image, fw: int, fh: int) -> float:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    a = im.split()[3]
    hist = a.histogram()
    nz = sum(hist[1:])
    return nz / float(fw * fh)


def _mse(a: Image.Image, b: Image.Image, fw: int, fh: int) -> float:
    d = ImageChops.difference(a.convert("RGBA"), b.convert("RGBA"))
    h = d.histogram()
    total = sum(i * h[i] for i in range(256))
    return total / float(fw * fh * 4)


def _foot_bottom(im: Image.Image) -> float | None:
    bb = _alpha_bbox(im)
    if not bb:
        return None
    return float(bb[3])


def _strip_horizontal(sheets: LayerSheets, row: int, n: int) -> tuple[list[Image.Image], StripMetrics]:
    fw, fh = sheets.cfg.fw, sheets.cfg.fh
    frames = [sheets.composite(row, c) for c in range(n)]
    cov = sum(_coverage(f, fw, fh) for f in frames) / n
    feet = [_foot_bottom(f) for f in frames]
    if any(v is None for v in feet) or cov < 0.008:
        return frames, StripMetrics("horizontal", row, cov, 9999.0, 9999.0, 1e9, "low_coverage_or_empty")
    foot_std = float(statistics.pstdev([v for v in feet if v is not None]))
    mses = [_mse(frames[i], frames[i + 1], fw, fh) for i in range(n - 1)]
    mse_m = float(sum(mses) / len(mses))
    score = foot_std * 12.0 + mse_m * 0.0007
    return frames, StripMetrics("horizontal", row, cov, foot_std, mse_m, score, "")


def _strip_vertical(sheets: LayerSheets, col: int, n: int) -> tuple[list[Image.Image], StripMetrics]:
    fw, fh = sheets.cfg.fw, sheets.cfg.fh
    frames = [sheets.composite(r, col) for r in range(n)]
    cov = sum(_coverage(f, fw, fh) for f in frames) / n
    feet = [_foot_bottom(f) for f in frames]
    if any(v is None for v in feet) or cov < 0.008:
        return frames, StripMetrics("vertical", col, cov, 9999.0, 9999.0, 1e9, "low_coverage_or_empty")
    foot_std = float(statistics.pstdev([v for v in feet if v is not None]))
    mses = [_mse(frames[i], frames[i + 1], fw, fh) for i in range(n - 1)]
    mse_m = float(sum(mses) / len(mses))
    score = foot_std * 12.0 + mse_m * 0.0007
    return frames, StripMetrics("vertical", col, cov, foot_std, mse_m, score, "")


def _pick_best_idle(cands: list[tuple[list[Image.Image], StripMetrics]]) -> tuple[list[Image.Image], StripMetrics]:
    ok = [(f, m) for f, m in cands if m.rejected == "" and math.isfinite(m.score)]
    ok.sort(key=lambda x: x[1].score)
    return ok[0]


def _forensic_strip_image(sheets: LayerSheets, row: int, title: str, n: int = 6) -> Image.Image:
    fw, fh = sheets.cfg.fw, sheets.cfg.fh
    frames = [sheets.composite(row, c) for c in range(min(n, sheets.cfg.cols))]
    pad = 4
    lab = 18
    cw = fw + pad * 2
    ch = fh + pad * 2 + lab
    out = Image.new("RGBA", (len(frames) * cw + 24, ch + 24), (24, 26, 30, 255))
    dr = ImageDraw.Draw(out)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    if font:
        dr.text((8, 4), title, fill=(240, 240, 240, 255), font=font)
    for i, fr in enumerate(frames):
        x0 = 12 + i * cw
        y0 = 20 + lab
        dr.rectangle([x0, y0, x0 + fw + pad, y0 + fh + pad], outline=(180, 180, 200, 255))
        out.paste(fr, (x0 + pad // 2, y0 + pad // 2), fr)
        bb = _alpha_bbox(fr)
        if bb:
            px = x0 + pad // 2
            py = y0 + pad // 2
            dr.rectangle([px + bb[0], py + bb[1], px + bb[2], py + bb[3]], outline=(255, 90, 90, 255), width=1)
            fy = py + bb[3]
            dr.line([px, fy, px + fw, fy], fill=(255, 220, 60, 255), width=1)
    return out


def _stack_horizontal(images: list[Image.Image], labels: list[str]) -> Image.Image:
    pad = 8
    max_h = max(im.size[1] for im in images) + 40
    total_w = sum(im.size[0] for im in images) + pad * (len(images) + 1)
    out = Image.new("RGBA", (total_w, max_h), (18, 20, 24, 255))
    dr = ImageDraw.Draw(out)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    x = pad
    for im, lab in zip(images, labels, strict=True):
        if font:
            dr.text((x, 6), lab, fill=(230, 230, 240, 255), font=font)
        y = 28
        out.paste(im, (x, y), im)
        x += im.size[0] + pad
    return out


def _frame_body_metrics(fr: Image.Image, fw: int, fh: int) -> dict[str, Any]:
    bb = _alpha_bbox(fr)
    cov = _coverage(fr, fw, fh)
    if not bb:
        return {"bbox": None, "coverage": cov, "full_body": False, "half_body": True, "tag": "BLANK"}
    bw = bb[2] - bb[0]
    bh = bb[3] - bb[1]
    head_region = fr.crop((0, 0, fw, int(fh * 0.28)))
    head_cov = _coverage(head_region, fw, int(fh * 0.28))
    leg_region = fr.crop((0, int(fh * 0.62), fw, fh))
    leg_cov = _coverage(leg_region, fw, fh - int(fh * 0.62))
    full = bh >= fh * 0.52 and bw >= fw * 0.16 and cov >= 0.02 and head_cov >= 0.006 and leg_cov >= 0.006
    half = bh < fh * 0.38 or bw < fw * 0.12
    tag = "FULL_BODY" if full else ("HALF_BODY" if half else "PARTIAL_BODY")
    return {
        "bbox": list(bb),
        "coverage": cov,
        "bbox_w_ratio": bw / float(fw),
        "bbox_h_ratio": bh / float(fh),
        "full_body": bool(full),
        "half_body": bool(half),
        "tag": tag,
    }


def _score_candidate_size(row: int, cfg: GridConfig) -> dict[str, Any]:
    sheets = LayerSheets(cfg)
    n = min(N_STRIP, cfg.cols)
    frames = [sheets.composite(row, c) for c in range(n)]
    mets = [_frame_body_metrics(f, cfg.fw, cfg.fh) for f in frames]
    full_count = sum(1 for m in mets if m["full_body"])
    half_count = sum(1 for m in mets if m["half_body"])
    hr = [float(m["bbox_h_ratio"]) for m in mets if m.get("bbox")]
    wr = [float(m["bbox_w_ratio"]) for m in mets if m.get("bbox")]
    mean_h = float(statistics.mean(hr)) if hr else 0.0
    mean_w = float(statistics.mean(wr)) if wr else 0.0
    return {
        "frame_size": [cfg.fw, cfg.fh],
        "sample_row": row,
        "strip_length": n,
        "full_body_frames": full_count,
        "half_body_frames": half_count,
        "mean_bbox_h_ratio": mean_h,
        "mean_bbox_w_ratio": mean_w,
        "layer_alignment_assumed": True,
    }


def _pick_walk(
    sheets: LayerSheets,
    orient: str,
    idle: StripMetrics,
    idle_frames: list[Image.Image],
    n: int,
) -> tuple[list[Image.Image] | None, dict[str, Any]]:
    fw, fh = sheets.cfg.fw, sheets.cfg.fh
    idle_mse = idle.mse_seq_mean
    idle_std = idle.foot_bottom_std
    best: tuple[float, list[Image.Image], StripMetrics] | None = None
    notes: list[str] = []

    if orient == "horizontal":
        for row in range(sheets.cfg.rows):
            if row == idle.index:
                continue
            frames, m = _strip_horizontal(sheets, row, n)
            if m.rejected:
                continue
            if m.mse_seq_mean < idle_mse * 1.06:
                continue
            if m.foot_bottom_std > min(2.5, max(1.8, idle_std * 4.5)):
                continue
            if m.coverage_mean < idle.coverage_mean * 0.5:
                continue
            motion = abs(m.mse_seq_mean - idle_mse * 1.25)
            jitter_penalty = max(0.0, m.foot_bottom_std - idle_std) * 6.0
            score = motion + jitter_penalty
            if best is None or score < best[0]:
                best = (score, frames, m)
    else:
        for col in range(sheets.cfg.cols):
            if col == idle.index:
                continue
            frames, m = _strip_vertical(sheets, col, n)
            if m.rejected:
                continue
            if m.mse_seq_mean < idle_mse * 1.06:
                continue
            if m.foot_bottom_std > min(2.5, max(1.8, idle_std * 4.5)):
                continue
            if m.coverage_mean < idle.coverage_mean * 0.5:
                continue
            motion = abs(m.mse_seq_mean - idle_mse * 1.25)
            jitter_penalty = max(0.0, m.foot_bottom_std - idle_std) * 6.0
            score = motion + jitter_penalty
            if best is None or score < best[0]:
                best = (score, frames, m)

    if best is None:
        notes.append("No walk strip passed heuristics; walk rejected.")
        return None, {"kept_walk": False, "notes": notes}

    _, frames, m = best
    notes.append(f"Walk chosen: {m.orientation} index={m.index} mse={m.mse_seq_mean:.3f} foot_std={m.foot_bottom_std:.3f}")
    return frames, {"kept_walk": True, "walk_metrics": asdict(m), "notes": notes}


def _prune_idle(
    frames: list[Image.Image],
    fw: int,
    fh: int,
) -> tuple[list[Image.Image], list[int], dict[str, Any]]:
    """Pick 2–6 consecutive frames with best stability + body metrics."""
    n = len(frames)
    metrics = [_frame_body_metrics(frames[i], fw, fh) for i in range(n)]
    acceptable = [bool(m["full_body"] or (m["bbox"] and m["bbox_h_ratio"] >= 0.46 and not m["half_body"])) for m in metrics]

    best: tuple[float, int, int, list[int]] | None = None
    for length in range(6, 1, -1):
        for start in range(0, n - length + 1):
            idxs = list(range(start, start + length))
            if not all(acceptable[i] for i in idxs):
                continue
            sub = [frames[i] for i in idxs]
            feet = [_foot_bottom(f) for f in sub]
            if any(f is None for f in feet):
                continue
            foot_std = float(statistics.pstdev(feet))
            min_h = min(float(metrics[i]["bbox_h_ratio"]) for i in idxs if metrics[i]["bbox"])
            score = min_h * 4.0 - foot_std * 1.2
            if best is None or score > best[0]:
                best = (score, start, length, idxs)

    if best is not None:
        _, _s, _l, idxs = best
        out = [frames[i] for i in idxs]
        return out, idxs, {"prune": "window", "indices": idxs, "reason": "best consecutive body+feet score"}

    # fallback: take up to 4 any acceptable
    idxs = [i for i in range(n) if acceptable[i]]
    if len(idxs) >= 2:
        idxs = idxs[: min(6, len(idxs))]
        return [frames[i] for i in idxs], idxs, {"prune": "first_acceptable", "indices": idxs}

    if len(idxs) == 1:
        return [frames[idxs[0]]], idxs, {"prune": "single_only", "indices": idxs, "note": "Only one stable frame; animation marginal."}

    return [], [], {"prune": "failed", "indices": [], "note": "No acceptable frames in strip"}


def _save_frames(out_dir: Path, prefix: str, frames: list[Image.Image]) -> list[str]:
    paths: list[str] = []
    for i, fr in enumerate(frames):
        p = out_dir / f"{prefix}_{i:03d}.png"
        fr.save(p)
        paths.append(str(p.relative_to(ROOT)).replace("\\", "/"))
    return paths


def _build_composite_sheet(idle: list[Image.Image], walk: list[Image.Image] | None, fw: int, fh: int) -> Image.Image:
    w = fw * len(idle)
    h = fh * (2 if walk else 1)
    sheet = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for i, fr in enumerate(idle):
        sheet.paste(fr, (i * fw, 0), fr)
    if walk:
        for i, fr in enumerate(walk):
            sheet.paste(fr, (i * fw, fh), fr)
    return sheet


def _write_spriteframes_tres(sheet_rel: str, out_tres: Path, fw: int, fh: int, idle_n: int, walk_n: int) -> None:
    lines: list[str] = [
        '[gd_resource type="SpriteFrames" format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{sheet_rel}" id="1_sheet"]',
        "",
    ]
    for i in range(idle_n):
        x = i * fw
        lines += [
            f'[sub_resource type="AtlasTexture" id="idle_{i}"]',
            'atlas = ExtResource("1_sheet")',
            f"region = Rect2({x}, 0, {fw}, {fh})",
            "",
        ]
    for i in range(walk_n):
        x = i * fw
        lines += [
            f'[sub_resource type="AtlasTexture" id="walk_{i}"]',
            'atlas = ExtResource("1_sheet")',
            f"region = Rect2({x}, {fh}, {fw}, {fh})",
            "",
        ]
    idle_frames = ", ".join([f'SubResource("idle_{i}")' for i in range(idle_n)])
    lines += ["[resource]", "animations = [ {"]
    lines += [
        f'"frames": [ {idle_frames} ],',
        '"loop": true,',
        '"name": "idle",',
        '"speed": 5.0',
    ]
    if walk_n > 0:
        walk_frames = ", ".join([f'SubResource("walk_{i}")' for i in range(walk_n)])
        lines += [
            "}, {",
            f'"frames": [ {walk_frames} ],',
            '"loop": true,',
            '"name": "walk",',
            '"speed": 9.0',
            "}",
        ]
    else:
        lines += ["}"]
    lines += ["]", ""]
    out_tres.write_text("\n".join(lines), encoding="utf-8")


def _contact_sheet(
    frames_by_title: list[tuple[str, list[Image.Image]]],
    out_png: Path,
    meta_sidecar: Path,
    fw: int,
    fh: int,
) -> dict[str, Any]:
    cell_pad = 6
    label_h = 22
    cols = max((len(frs) for _, frs in frames_by_title), default=1)
    rows = len(frames_by_title)
    cw = fw + cell_pad * 2
    ch = fh + cell_pad * 2 + label_h
    img = Image.new("RGBA", (cols * cw + 40, rows * ch + 40), (30, 30, 34, 255))
    dr = ImageDraw.Draw(img)
    try:
        font = ImageFont.load_default()
    except Exception:  # noqa: BLE001
        font = None
    meta: dict[str, Any] = {"cells": []}
    for r, (title, frames) in enumerate(frames_by_title):
        for c, fr in enumerate(frames):
            x0 = 20 + c * cw
            y0 = 20 + r * ch
            dr.rectangle([x0, y0, x0 + cw - cell_pad, y0 + ch - cell_pad], outline=(200, 200, 200, 255))
            px = x0 + cell_pad
            py = y0 + cell_pad + label_h
            img.paste(fr, (px, py), fr)
            bb = _alpha_bbox(fr)
            m = _frame_body_metrics(fr, fw, fh)
            tag = m["tag"]
            if bb:
                dr.rectangle([px + bb[0], py + bb[1], px + bb[2], py + bb[3]], outline=(255, 80, 80, 255), width=1)
                foot_y = py + bb[3]
                dr.line([px, foot_y, px + fw, foot_y], fill=(255, 220, 60, 255), width=1)
            if font:
                dr.text((x0 + cell_pad, y0 + 2), f"{title} [{c}] {tag}", fill=(240, 240, 240, 255), font=font)
            meta["cells"].append({"title": title, "index": c, "tag": tag, "bbox": bb})
    img.save(out_png)
    meta_sidecar.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def _frame_quality(frames: list[Image.Image], name: str, fw: int, fh: int) -> dict[str, Any]:
    feet = [_foot_bottom(f) for f in frames]
    foot_std = (
        float(statistics.pstdev([f for f in feet if f is not None]))
        if len(frames) > 1 and all(f is not None for f in feet)
        else None
    )
    tags = [_frame_body_metrics(fr, fw, fh)["tag"] for fr in frames]
    ok_tags = {"FULL_BODY"}
    all_ok = all(t in ok_tags for t in tags)
    return {"name": name, "foot_bottom_std": foot_std, "per_frame_tags": tags, "all_ok": all_ok}


def _forensic_comparison_png(row: int) -> tuple[Image.Image, dict[str, Any]]:
    cfg100 = GridConfig(100, 200)
    cfg200 = GridConfig(200, 200)
    im100 = _forensic_strip_image(LayerSheets(cfg100), row, f"100x200 row={row}", n=6)
    im200 = _forensic_strip_image(LayerSheets(cfg200), row, f"200x200 row={row}", n=6)
    combo = _stack_horizontal([im100, im200], [f"100x200 (cols 0-5) row {row}", f"200x200 (cols 0-5) row {row}"])
    js = {
        "row": row,
        "scores": {
            "100x200": _score_candidate_size(row, cfg100),
            "200x200": _score_candidate_size(row, cfg200),
        },
    }
    return combo, js


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    FIX3.mkdir(parents=True, exist_ok=True)
    (FIX3 / "frames").mkdir(parents=True, exist_ok=True)

    branch = _git(["branch", "--show-current"])
    if branch != "c2a-full-character-animation-20260509-172230":
        raise SystemExit(f"HARD STOP: wrong branch: {branch!r}")

    c2_frame = [200, 200]
    c2_rect = {"x": 0, "y": 0, "w": 200, "h": 200}
    if C2_PREP.exists():
        prep = json.loads(C2_PREP.read_text(encoding="utf-8"))
        r = prep.get("source_frame_rect", {})
        c2_rect = r
        c2_frame = [int(r.get("w", 200)), int(r.get("h", 200))]

    forensic_row = 8
    cfg100 = GridConfig(100, 200)
    cfg200 = GridConfig(200, 200)

    img100 = _forensic_strip_image(LayerSheets(cfg100), forensic_row, f"FORENSIC 100x200 row={forensic_row}", n=min(10, cfg100.cols))
    img200 = _forensic_strip_image(LayerSheets(cfg200), forensic_row, f"FORENSIC 200x200 row={forensic_row}", n=min(10, cfg200.cols))
    img100.save(REPORTS / "phase0mc2a_fix3_frame_size_forensic_100x200.png")
    img200.save(REPORTS / "phase0mc2a_fix3_frame_size_forensic_200x200.png")

    combo, combo_js = _forensic_comparison_png(forensic_row)
    combo.save(REPORTS / "phase0mc2a_fix3_frame_size_forensic_comparison.png")
    (REPORTS / "phase0mc2a_fix3_frame_size_forensic_comparison.json").write_text(json.dumps(combo_js, indent=2), encoding="utf-8")

    s100 = _score_candidate_size(forensic_row, cfg100)
    s200 = _score_candidate_size(forensic_row, cfg200)

    # Decision: prefer 200x200 if more full-body frames or C2 says 200x200 and 200 is not worse on half-body count
    choose_200 = False
    reason = ""
    if s200["full_body_frames"] > s100["full_body_frames"]:
        choose_200 = True
        reason = "200x200 produced more full-body frames in sampled strip than 100x200."
    elif s200["half_body_frames"] < s100["half_body_frames"]:
        choose_200 = True
        reason = "200x200 produced fewer half-body frames than 100x200."
    elif c2_frame == [200, 200]:
        choose_200 = True
        reason = "C2 static preparation documented 200x200 source_frame_rect; forensic tie-break to native cell size."
    else:
        choose_200 = s200["mean_bbox_h_ratio"] >= s100["mean_bbox_h_ratio"]
        reason = (
            "Chose 200x200 based on mean visible height ratio tie-break."
            if choose_200
            else "Chose 100x200 based on mean visible height ratio tie-break."
        )

    chosen = GridConfig(200, 200) if choose_200 else GridConfig(100, 200)
    chosen_fw, chosen_fh = chosen.fw, chosen.fh
    chosen_score = s200 if choose_200 else s100
    decision = {
        "chosen_frame_size": [chosen_fw, chosen_fh],
        "reason": reason,
        "c2_reported_frame_rect": c2_rect,
        "c2a_prior_note": "Earlier C2A tooling assumed 100x200; FIX3 overrides after forensic.",
        "forensic_scores": {"100x200": s100, "200x200": s200},
        "chosen_produces_full_body": bool(chosen_score["full_body_frames"] >= 3),
        "chosen_does_not_cut_half": bool(chosen_score["half_body_frames"] <= max(2, min(s100["half_body_frames"], s200["half_body_frames"]) + 1)),
    }
    (REPORTS / "phase0mc2a_fix3_frame_size_decision.json").write_text(json.dumps(decision, indent=2), encoding="utf-8")
    (REPORTS / "phase0mc2a_fix3_frame_size_decision.md").write_text(
        "# FIX3 frame size decision\n\n"
        f"- **Chosen:** `{chosen_fw}x{chosen_fh}`\n"
        f"- **Reason:** {reason}\n"
        f"- **C2 `source_frame_rect`:** `{c2_rect}`\n"
        "- See forensic PNGs: `phase0mc2a_fix3_frame_size_forensic_100x200.png`, "
        "`phase0mc2a_fix3_frame_size_forensic_200x200.png`, `phase0mc2a_fix3_frame_size_forensic_comparison.png`.\n",
        encoding="utf-8",
    )

    sheets = LayerSheets(chosen)
    n_strip = min(N_STRIP, chosen.cols)

    horiz: list[tuple[list[Image.Image], StripMetrics]] = []
    for row in range(chosen.rows):
        horiz.append(_strip_horizontal(sheets, row, n_strip))
    vert: list[tuple[list[Image.Image], StripMetrics]] = []
    for col in range(chosen.cols):
        vert.append(_strip_vertical(sheets, col, n_strip))

    best_h = _pick_best_idle(horiz)
    best_v = _pick_best_idle(vert)
    if best_h[1].score <= best_v[1].score:
        orient = "horizontal"
        raw_idle, idle_m = best_h
        idle_desc = f"row={idle_m.index}, cols=0..{n_strip - 1}"
    else:
        orient = "vertical"
        raw_idle, idle_m = best_v
        idle_desc = f"col={idle_m.index}, rows=0..{n_strip - 1}"

    pruned, pr_idx, prune_info = _prune_idle(raw_idle, chosen_fw, chosen_fh)
    if len(pruned) < 2:
        pruned = raw_idle[: min(6, len(raw_idle))]
        pr_idx = list(range(len(pruned)))
        prune_info = {"prune": "fallback_raw", "indices": pr_idx, "note": "Prune yielded <2 frames; using raw strip head."}

    walk_frames, walk_pick = _pick_walk(sheets, orient, idle_m, raw_idle, n_strip)
    walk_quality_ok = False
    if walk_frames:
        wq = _frame_quality(walk_frames, "walk", chosen_fw, chosen_fh)
        walk_std = wq.get("foot_bottom_std")
        idle_std = idle_m.foot_bottom_std
        walk_quality_ok = bool(
            wq["all_ok"] or (walk_std is not None and idle_std is not None and walk_std <= idle_std * 2.8)
        )
    has_walk = walk_frames is not None and walk_quality_ok

    for stale in (FIX3 / "frames").glob("walk_*.png"):
        try:
            stale.unlink()
        except OSError:
            pass

    idle_paths = _save_frames(FIX3 / "frames", "idle", pruned)
    walk_paths: list[str] = []
    if has_walk and walk_frames:
        walk_paths = _save_frames(FIX3 / "frames", "walk", walk_frames[: len(pruned)])

    sheet = _build_composite_sheet(pruned, walk_frames[: len(pruned)] if has_walk else None, chosen_fw, chosen_fh)
    sheet_path = FIX3 / "parmida_player_composite_sheet_0mc2a_fix3.png"
    sheet.save(sheet_path)
    sheet_rel = "res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_composite_sheet_0mc2a_fix3.png"
    walk_n = len(walk_frames[: len(pruned)]) if has_walk else 0
    _write_spriteframes_tres(sheet_rel, FIX3 / "parmida_player_spriteframes_0mc2a_fix3.tres", chosen_fw, chosen_fh, len(pruned), walk_n)

    meta = {
        "frame_width": chosen_fw,
        "frame_height": chosen_fh,
        "verified_kit_sheet_size": [10000, 10000],
        "orientation_chosen": orient,
        "idle": {
            "strip": idle_desc,
            "raw_metrics": asdict(idle_m),
            "prune": prune_info,
            "frame_files": idle_paths,
            "source_indices_in_raw_strip": pr_idx,
        },
        "walk": {"included": has_walk, "pick": walk_pick, "frame_files": walk_paths},
        "layers": [{"name": n, "path": str((KIT / rel / "Spritesheet.png").relative_to(ROOT)).replace("\\", "/")} for n, rel in LAYERS],
        "forensic": {"sample_row": forensic_row, "decision": decision},
        "rules": {"fixed_canvas": True, "no_per_frame_trim": True, "same_grid_all_layers": True},
    }
    (FIX3 / "parmida_player_animation_metadata_0mc2a_fix3.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    # Phase 3 bad sheets from FIX2 current idle / walk (separate PNGs)
    if (FIX2 / "frames").exists():
        idle_bad_paths = sorted((FIX2 / "frames").glob("idle_*.png"))
        walk_bad_paths = sorted((FIX2 / "frames").glob("walk_*.png"))
        if idle_bad_paths:
            idle_imgs = [Image.open(p).convert("RGBA") for p in idle_bad_paths]
            fw_b, fh_b = idle_imgs[0].size
            _contact_sheet(
                [("FIX2_idle_current", idle_imgs)],
                REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.png",
                REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.json",
                fw_b,
                fh_b,
            )
        else:
            Image.new("RGBA", (400, 120), (40, 40, 44, 255)).save(REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.png")
            (REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.json").write_text(
                json.dumps({"note": "No FIX2 idle_*.png under fix2_rebuilt/frames."}, indent=2), encoding="utf-8"
            )
        if walk_bad_paths:
            walk_imgs = [Image.open(p).convert("RGBA") for p in walk_bad_paths]
            fw_w, fh_w = walk_imgs[0].size
            _contact_sheet(
                [("FIX2_walk_current", walk_imgs)],
                REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.png",
                REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.json",
                fw_w,
                fh_w,
            )
        else:
            (REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.json").write_text(
                json.dumps({"note": "No walk frames on disk under fix2_rebuilt/frames."}, indent=2), encoding="utf-8"
            )
            Image.new("RGBA", (520, 100), (40, 40, 44, 255)).save(REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.png")
    else:
        Image.new("RGBA", (400, 120), (40, 40, 44, 255)).save(REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.png")
        (REPORTS / "phase0mc2a_fix3_current_bad_idle_frames.json").write_text(json.dumps({"note": "No FIX2 frames folder."}, indent=2), encoding="utf-8")
        Image.new("RGBA", (520, 100), (40, 40, 44, 255)).save(REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.png")
        (REPORTS / "phase0mc2a_fix3_current_bad_walk_frames.json").write_text(json.dumps({"note": "No FIX2 frames folder."}, indent=2), encoding="utf-8")

    analysis = {
        "primary_animation_resource": "res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_spriteframes_0mc2a_fix2.tres",
        "root_cause": "A — WRONG_FRAME_SIZE (100x200 vs true 200x200 C2 cell) + G/L secondary",
        "fix2_frame_size": [100, 200],
        "fix3_chosen": [chosen_fw, chosen_fh],
    }
    (REPORTS / "phase0mc2a_fix3_current_bad_frames_analysis.json").write_text(json.dumps(analysis, indent=2), encoding="utf-8")

    fq = {
        "idle": _frame_quality(pruned, "idle", chosen_fw, chosen_fh),
        "walk": _frame_quality(walk_frames[:walk_n], "walk", chosen_fw, chosen_fh) if has_walk else {"name": "walk", "included": False},
        "walk_included": has_walk,
    }
    (REPORTS / "phase0mc2a_fix3_frame_quality.json").write_text(json.dumps(fq, indent=2), encoding="utf-8")
    (REPORTS / "phase0mc2a_fix3_frame_quality.md").write_text(
        "# FIX3 rebuilt frame quality\n\nSee `phase0mc2a_fix3_frame_quality.json`.\n", encoding="utf-8"
    )

    stable_sets: list[tuple[str, list[Image.Image]]] = [("FIX3_idle_accepted", pruned)]
    if has_walk:
        stable_sets.append(("FIX3_walk_accepted", walk_frames[:walk_n]))
    _contact_sheet(
        stable_sets,
        REPORTS / "phase0mc2a_fix3_stable_frames_contact_sheet.png",
        REPORTS / "phase0mc2a_fix3_stable_frames_contact_sheet.json",
        chosen_fw,
        chosen_fh,
    )

    print("FIX3 pipeline complete.")
    print("chosen:", chosen_fw, "x", chosen_fh, "idle frames:", len(pruned), "walk:", has_walk)


if __name__ == "__main__":
    main()
