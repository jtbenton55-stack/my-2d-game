#!/usr/bin/env python3
"""D6-01-FIX7E static validator — reports, code checks, forbidden edits."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_01_fix7e_ambush_beam_span_clamp"
REQUIRED = [
    "phase0md6_01_fix7e_safety_baseline.md",
    "phase0md6_01_fix7e_safety_baseline.json",
    "phase0md6_01_fix7e_beam_geometry_audit.md",
    "phase0md6_01_fix7e_beam_geometry_audit.json",
    "phase0md6_01_fix7e_collision_inner_gap_plan.md",
    "phase0md6_01_fix7e_collision_inner_gap_plan.json",
    "phase0md6_01_fix7e_implementation.md",
    "phase0md6_01_fix7e_implementation.json",
    "phase0md6_01_fix7e_f10_update.md",
    "phase0md6_01_fix7e_f10_update.json",
    "phase0md6_01_fix7e_static_self_review.md",
    "phase0md6_01_fix7e_static_self_review.json",
    "phase0md6_01_fix7e_runtime_validation.md",
    "phase0md6_01_fix7e_runtime_validation.json",
    "phase0md6_01_fix7e_validation.md",
    "phase0md6_01_fix7e_validation.json",
    "phase0md6_01_fix7e_final_report.md",
    "phase0md6_01_fix7e_final_report.json",
]
FORBIDDEN_SUBSTRINGS = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions/TacoBellMission.tscn",
    "assets/",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def git_changed_files(root: Path) -> list[str]:
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

    for name in REQUIRED:
        p = rd / name
        if not p.is_file():
            errors.append(f"missing {p.relative_to(root)}")

    fj = rd / "phase0md6_01_fix7e_final_report.json"
    if fj.is_file():
        try:
            fr = json.loads(fj.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"final_report json: {e}")
        else:
            for k in (
                "pass_fail",
                "current_branch",
                "beam_too_long_root_cause",
                "beam_x_preserved",
                "visual_trigger_separated",
                "collision_inner_gap_status",
                "fallback_used",
                "runtime_validation_status",
                "static_validator_result",
                "project_godot_modified",
                "player_gd_modified",
                "kimi_used",
            ):
                if k not in fr:
                    errors.append(f"final_report missing {k}")
            if fr.get("project_godot_modified") is not False:
                errors.append("project_godot_modified must be false")

    vj = rd / "phase0md6_01_fix7e_validation.json"
    if vj.is_file():
        try:
            v = json.loads(vj.read_text(encoding="utf-8"))
            ha = v.get("hard_assertions", {})
            for k, val in ha.items():
                if val is not True:
                    errors.append(f"validation hard_assertions.{k} != true ({val!r})")
        except json.JSONDecodeError as e:
            errors.append(str(e))

    iso = root / "src" / "levels" / "IsoMissionBase.gd"
    if not iso.is_file():
        errors.append("IsoMissionBase.gd missing")
    else:
        t = iso.read_text(encoding="utf-8")
        for needle in (
            "D6_FIX7E_AMBUSH_BEAM_VISUAL_WIDTH",
            "_compute_fix7e_ambush_beam_inner_gap",
            "_raycast_fix7e_boundary",
            "_apply_fix7e_ambush_beam_geometry",
            '_attempt_runtime_state["fix7e_mode"]',
        ):
            if needle not in t:
                errors.append(f"IsoMissionBase.gd missing {needle}")
        setup_m = re.search(
            r"func _setup_fix7_ambush_beam_runtime\(\) -> void:\r?\n([\s\S]*?)^func ",
            t,
            re.MULTILINE,
        )
        if setup_m:
            setup_body = setup_m.group(0)
            if "_compute_fix7d_ambush_beam_from_collision(anchor_pos)" in setup_body:
                errors.append("_setup_fix7_ambush_beam_runtime must not call _compute_fix7d_ambush_beam_from_collision")
            if "D6_FIX7D_FALLBACK_HEIGHT" in setup_body:
                errors.append("_setup_fix7_ambush_beam_runtime must not reference D6_FIX7D_FALLBACK_HEIGHT (840 active path)")
        else:
            errors.append("could not locate _setup_fix7_ambush_beam_runtime")

    panel = root / "src" / "missions" / "iso" / "runtime" / "IsoMissionDebugPanel.gd"
    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "AMBUSH beam (FIX7E)" not in pt or "fix7e_mode" not in pt:
            errors.append("IsoMissionDebugPanel.gd missing FIX7E F10 block")
    else:
        errors.append("IsoMissionDebugPanel.gd missing")

    changed = git_changed_files(root)
    for bad in FORBIDDEN_SUBSTRINGS:
        for c in changed:
            if bad in c.replace("\\", "/"):
                errors.append(f"forbidden path in git diff: {c}")

    (rd / "phase0md6_01_fix7e_static_validator_run.json").write_text(
        json.dumps({"errors": errors, "passed": not errors}, indent=2) + "\n",
        encoding="utf-8",
    )
    if errors:
        print("VALIDATOR FAIL:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("VALIDATOR PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
