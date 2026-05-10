#!/usr/bin/env python3
"""Inventory C2A generated assets for 0M-C2A-FIX1 (writes JSON fragment; full MD written separately)."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
C2A = ROOT / "assets/characters/generated_player_visuals/c2a_animation"
REPORTS = ROOT / "docs/reports/character_animation_c2a"


def file_info(p: Path) -> dict:
    if not p.exists():
        return {"path": str(p.relative_to(ROOT)).replace("\\", "/"), "exists": False}
    st = p.stat()
    out: dict = {"path": str(p.relative_to(ROOT)).replace("\\", "/"), "exists": True, "size_bytes": st.st_size}
    if p.suffix.lower() == ".png":
        try:
            from PIL import Image

            with Image.open(p) as im:
                out["width"], out["height"] = im.size
                out["mode"] = im.mode
                if im.mode in ("RGBA", "LA") or (im.mode == "P" and "transparency" in im.info):
                    bbox = im.getchannel("A").getbbox() if im.mode == "RGBA" else None
                    out["alpha_channel"] = True
                    out["alpha_bbox"] = bbox
                else:
                    out["alpha_channel"] = False
        except Exception as e:  # noqa: BLE001
            out["image_error"] = str(e)
    if p.suffix.lower() == ".tres":
        txt = p.read_text(encoding="utf-8", errors="replace")
        out["resource_type"] = "SpriteFrames" if 'type="SpriteFrames"' in txt[:200] else "unknown"
        names = re.findall(r'"name"\s*:\s*"([^"]+)"', txt)
        out["animation_names_in_text"] = list(dict.fromkeys(names))
        out["has_subresource_atlas"] = "AtlasTexture" in txt
        out["has_valid_animations_block"] = bool(re.search(r"animations\s*=\s*\[\s*\{", txt))
    return out


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    candidates = sorted(C2A.rglob("*")) if C2A.exists() else []
    files = [p for p in candidates if p.is_file()]
    entries = [file_info(p) for p in files]

    sandbox = ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn"
    ctrl = ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd"
    fix1 = C2A / "parmida_player_spriteframes_0mc2a_fix1.tres"
    legacy = C2A / "parmida_player_spriteframes_0mc2a.tres"
    composite = C2A / "parmida_player_composite_sheet_0mc2a.png"

    report = {
        "repo_root": str(ROOT),
        "c2a_folder_exists": C2A.exists(),
        "file_count": len(files),
        "files": entries,
        "highlights": {
            "composite_sheet": file_info(composite),
            "spriteframes_fix1": file_info(fix1),
            "spriteframes_legacy": file_info(legacy),
            "sandbox_scene": file_info(sandbox),
            "sandbox_controller": file_info(ctrl),
        },
    }
    out_json = REPORTS / "phase0mc2a_fix1_generated_resource_inventory.json"
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("Wrote", out_json)


if __name__ == "__main__":
    main()
