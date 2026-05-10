#!/usr/bin/env python3
"""Static validation for 0M-C2A-FIX2."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
REPORTS = ROOT / "docs/reports/character_animation_c2a"
FIX2 = ROOT / "assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt"


def _git(args: list[str]) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False)
    return (r.stdout or "").strip()


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    branch = _git(["branch", "--show-current"])
    checks: dict[str, bool] = {}
    checks["branch_ok"] = branch == "c2a-full-character-animation-20260509-172230"
    checks["player_tscn_clean"] = _git(["diff", "--name-only", "--", "scenes/characters/player.tscn"]) == ""
    checks["player_gd_clean"] = _git(["diff", "--name-only", "--", "src/player/Player.gd"]) == ""
    checks["taco_clean"] = _git(["diff", "--name-only", "--", "scenes/missions_iso/"]) == ""

    bad_sheet = REPORTS / "phase0mc2a_fix2_current_bad_frames_contact_sheet.png"
    rebuilt_sheet = REPORTS / "phase0mc2a_fix2_rebuilt_frames_contact_sheet.png"
    checks["bad_contact_sheet_exists"] = bad_sheet.exists()
    checks["rebuilt_contact_sheet_exists"] = rebuilt_sheet.exists()

    checks["fix2_frames_dir_exists"] = (FIX2 / "frames").exists()
    checks["fix2_composite_exists"] = (FIX2 / "parmida_player_composite_sheet_0mc2a_fix2.png").exists()
    checks["fix2_spriteframes_exists"] = (FIX2 / "parmida_player_spriteframes_0mc2a_fix2.tres").exists()
    checks["fix2_metadata_exists"] = (FIX2 / "parmida_player_animation_metadata_0mc2a_fix2.json").exists()

    sf_txt = _read(FIX2 / "parmida_player_spriteframes_0mc2a_fix2.tres")
    checks["no_nested_animations_idle_bug"] = '"animations/idle"' not in sf_txt
    checks["has_idle_name"] = '"name": "idle"' in sf_txt
    checks["uses_subresource_idle0"] = 'SubResource("idle_0")' in sf_txt

    sandbox = _read(ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn")
    ctrl = _read(ROOT / "scenes/hideout/tools/CharacterAnimationSandbox_0MC2AController.gd")
    # When FIX3 exists in controller, it must be loaded before FIX2; else FIX2 is the first SpriteFrames try.
    has_fix3 = "SPRITEFRAMES_FIX3" in ctrl
    if has_fix3:
        checks["sandbox_spriteframes_priority_ok"] = ctrl.find("SPRITEFRAMES_FIX3") < ctrl.find("SPRITEFRAMES_FIX2")
    else:
        checks["sandbox_spriteframes_priority_ok"] = "SPRITEFRAMES_FIX2" in ctrl
    checks["sandbox_not_primary_fix1"] = not re.search(
        r'sprite_frames\s*=\s*ExtResource\("3_sf_fix1"\)', sandbox
    )
    checks["sandbox_has_debug"] = "DebugPanel" in sandbox and "DebugLabel" in sandbox

    legacy_sf = ROOT / "assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a.tres"
    checks["legacy_broken_not_required_to_exist"] = True
    checks["fix1_not_overwritten"] = (ROOT / "assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres").exists()

    # Fixed-size frames: all idle_*.png same size
    idle_frames = sorted((FIX2 / "frames").glob("idle_*.png"))
    checks["idle_frame_png_count"] = len(idle_frames) == 10
    sizes = {Image.open(p).size for p in idle_frames} if idle_frames else set()
    checks["idle_frames_fixed_100x200"] = sizes == {(100, 200)} if idle_frames else False

    walk_frames = sorted((FIX2 / "frames").glob("walk_*.png"))
    checks["walk_optional"] = True
    checks["walk_frame_count"] = len(walk_frames) in (0, 10)

    meta = json.loads(_read(FIX2 / "parmida_player_animation_metadata_0mc2a_fix2.json"))
    checks["metadata_walk_included_matches_files"] = meta["walk"]["included"] == (len(walk_frames) == 10)

    structural = all(
        checks[k]
        for k in [
            "branch_ok",
            "player_tscn_clean",
            "player_gd_clean",
            "taco_clean",
            "bad_contact_sheet_exists",
            "rebuilt_contact_sheet_exists",
            "fix2_frames_dir_exists",
            "fix2_composite_exists",
            "fix2_spriteframes_exists",
            "fix2_metadata_exists",
            "no_nested_animations_idle_bug",
            "has_idle_name",
            "uses_subresource_idle0",
            "sandbox_spriteframes_priority_ok",
            "sandbox_not_primary_fix1",
            "sandbox_has_debug",
            "idle_frame_png_count",
            "idle_frames_fixed_100x200",
            "metadata_walk_included_matches_files",
        ]
    )

    out = {
        "branch": branch,
        "structural_pass": structural,
        "overall_status": "PARTIAL" if structural else "FAIL",
        "checks": checks,
        "note": "Structural checks only. Eyeball rebuilt contact sheet + run sandbox in Godot for final acceptance; production promotion remains manual.",
    }
    (REPORTS / "phase0mc2a_fix2_validation.json").write_text(json.dumps(out, indent=2), encoding="utf-8")

    lines = [
        "# Phase 0M-C2A-FIX2 — Static validation",
        "",
        f"- **Branch:** `{branch}`",
        f"- **structural_pass:** {structural}",
        f"- **overall_status:** {out['overall_status']} (runtime/visual still manual)",
        "",
        "## Checks",
        "",
    ]
    for k, v in sorted(checks.items()):
        lines.append(f"- **{k}:** {v}")
    lines.extend(["", out["note"], ""])
    (REPORTS / "phase0mc2a_fix2_validation.md").write_text("\n".join(lines), encoding="utf-8")

    print(json.dumps({"structural_pass": structural}, indent=2))


if __name__ == "__main__":
    main()
