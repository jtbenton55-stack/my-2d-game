#!/usr/bin/env python3
"""PHASE 0M-D6-02A security beam authoring polish static validator."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_02a_security_beam_authoring_polish"
FORBIDDEN = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
    "assets/",
]
BEAM_EXPORTS = [
    "beam_id",
    "enabled",
    "visual_height",
    "visual_width",
    "trigger_width",
    "trigger_extra_height",
    "one_shot",
    "preview_color",
    "show_label",
    "show_trigger_preview",
    "snap_height_step",
    "authoring_notes",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def git_changed(root: Path) -> list[str]:
    out: list[str] = []
    for args in (["git", "diff", "--name-only"], ["git", "diff", "--cached", "--name-only"]):
        r = subprocess.run(args, cwd=str(root), capture_output=True, text=True, check=False)
        for ln in r.stdout.splitlines():
            s = ln.strip().replace("\\", "/")
            if s:
                out.append(s)
    return list(dict.fromkeys(out))


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    beam = root / "src/missions/iso/authoring/SecurityBeamAuthor.gd"
    if not beam.is_file():
        errors.append("SecurityBeamAuthor.gd missing")
    else:
        t = beam.read_text(encoding="utf-8")
        if "@tool" not in t:
            errors.append("SecurityBeamAuthor missing @tool")
        for ex in BEAM_EXPORTS:
            if ex not in t:
                errors.append(f"SecurityBeamAuthor missing {ex}")
        for needle in (
            "get_trigger_height",
            "build_runtime_config",
            "get_clamped_visual_height",
            "_get_configuration_warnings",
            "queue_redraw",
            "get_trigger_height",
            "* 2.0",
        ):
            if needle not in t:
                errors.append(f"SecurityBeamAuthor missing {needle}")

    iso = root / "src/levels/IsoMissionBase.gd"
    if iso.is_file():
        it = iso.read_text(encoding="utf-8")
        for needle in (
            "_setup_ambush_beam_from_security_beam_author",
            "find_enabled_beam_author",
            "_compute_fix7f_ambush_beam_doorway_rect",
            "d6_02_ambush_beam_visual_width",
            "d6_02_ambush_beam_trigger_height",
            "d6_02_ambush_beam_validation_status",
        ):
            if needle not in it:
                errors.append(f"IsoMissionBase missing {needle}")
    else:
        errors.append("IsoMissionBase.gd missing")

    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "d6_02_ambush_beam_visual_width" not in pt:
            errors.append("IsoMissionDebugPanel missing visual_width F10 field")
        if "d6_02_ambush_beam_validation_status" not in pt:
            errors.append("IsoMissionDebugPanel missing validation_status F10 field")
    else:
        errors.append("IsoMissionDebugPanel missing")

    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        if "visual_height = 340" not in tt and "visual_height = 340.0" not in tt:
            errors.append("Taco AMBUSH author missing visual_height default 340")
    else:
        errors.append("Taco scene missing")

    impl = rd / "phase0md6_02a_implementation.md"
    if not impl.is_file():
        errors.append(f"missing {impl.relative_to(root)}")

    for bad in FORBIDDEN:
        for c in git_changed(root):
            if bad in c:
                errors.append(f"forbidden modified: {c}")

    other_scenes = [
        c
        for c in git_changed(root)
        if c.startswith("scenes/") and c.endswith(".tscn") and "TacoBellIso_Editable_RedesignTest.tscn" not in c
    ]
    if other_scenes:
        errors.append(f"unexpected scene edits: {other_scenes}")

    rd.mkdir(parents=True, exist_ok=True)
    (rd / "phase0md6_02a_static_validator_run.json").write_text(
        json.dumps({"passed": not errors, "errors": errors}, indent=2) + "\n",
        encoding="utf-8",
    )
    if errors:
        print("FAIL:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
