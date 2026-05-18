#!/usr/bin/env python3
"""D6-01-FIX7F static validator."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_01_fix7f_ambush_beam_doorway_rect"
FORBIDDEN = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "assets/",
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
    iso = root / "src" / "levels" / "IsoMissionBase.gd"
    panel = root / "src" / "missions" / "iso" / "runtime" / "IsoMissionDebugPanel.gd"
    if not iso.is_file():
        errors.append("IsoMissionBase.gd missing")
    else:
        t = iso.read_text(encoding="utf-8")
        for needle in (
            "D6_FIX7F_AMBUSH_BEAM_VISUAL_WIDTH",
            "_compute_fix7f_ambush_beam_doorway_rect",
            "_probe_fix7f_candidate_doorway_x",
            "_fix7f_passage_walkable",
            "_schedule_fix7_ambush_beam_physics_setup",
            "_store_fix7f_runtime_state",
            '_attempt_runtime_state["fix7f_mode"]',
            "_find_runtime_debug_marker",
        ):
            if needle not in t:
                errors.append(f"IsoMissionBase missing {needle}")
        m = re.search(
            r"func _setup_fix7_ambush_beam_runtime\(\) -> void:\r?\n([\s\S]*?)^func ",
            t,
            re.MULTILINE,
        )
        if not m:
            errors.append("_setup_fix7_ambush_beam_runtime not found")
        else:
            body = m.group(1)
            if "_compute_fix7e_ambush_beam_inner_gap(anchor_pos)" in body:
                errors.append("setup must not call fix7e inner gap")
            if "_compute_fix7f_ambush_beam_doorway_rect(anchor_pos)" not in body:
                errors.append("setup must call fix7f doorway rect")
            if "D6_FIX7D_FALLBACK_HEIGHT" in body or "840" in body:
                errors.append("setup must not use 840px fallback")
        if "D6_FIX7D_AMBUSH_BEAM_WALL_OVERLAP_PX" in t and "overlap" in t:
            pass  # legacy const ok if unused in setup
    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "AMBUSH beam (FIX7F)" not in pt or "fix7f_chosen_x" not in pt:
            errors.append("IsoMissionDebugPanel missing FIX7F block")
    else:
        errors.append("IsoMissionDebugPanel missing")
    impl = rd / "phase0md6_01_fix7f_implementation.md"
    val = rd / "phase0md6_01_fix7f_validation.json"
    if not impl.is_file():
        errors.append(f"missing {impl.relative_to(root)}")
    if not val.is_file():
        errors.append(f"missing {val.relative_to(root)}")
    else:
        try:
            v = json.loads(val.read_text(encoding="utf-8"))
            for k, ok in v.get("hard_assertions", {}).items():
                if ok is not True:
                    errors.append(f"hard_assertions.{k} != true")
        except json.JSONDecodeError as e:
            errors.append(str(e))
    for bad in FORBIDDEN:
        for c in git_changed(root):
            if bad in c:
                errors.append(f"forbidden modified: {c}")
    (rd / "phase0md6_01_fix7f_static_validator_run.json").write_text(
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
