#!/usr/bin/env python3
"""0M-D4 static validator — reports + resolver + git scope."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=None)
    args = ap.parse_args()
    root: Path = args.root or Path.cwd()
    errors: list[str] = []
    rep = root / "docs" / "reports" / "taco_bell_redesign_d4"
    req_json = [
        "phase0md4_safety_baseline.json",
        "phase0md4_expanded_scene_audit.json",
        "phase0md4_existing_taco_mechanic_audit.json",
        "phase0md4_mission_design_blueprint.json",
        "phase0md4_taco_module_ownership_map.json",
        "phase0md4_d5_implementation_spec.json",
        "phase0md4_risk_deferral_plan.json",
        "phase0md4_optional_runtime_inspection.json",
        "phase0md4_validation.json",
        "phase0md4_final_safety_review.json",
        "phase0md4_taco_bell_redesign_plan.json",
    ]
    for name in req_json:
        p = rep / name
        if not p.is_file():
            errors.append(f"missing {p}")
        else:
            try:
                json.loads(p.read_text(encoding="utf-8"))
            except json.JSONDecodeError as e:
                errors.append(f"invalid json {p}: {e}")

    redesign = root / "scenes" / "missions_iso" / "TacoBellIso_Editable_RedesignTest.tscn"
    legacy = root / "scenes" / "missions_iso" / "TacoBellIso_Editable.tscn"
    resolver = root / "src" / "missions" / "MissionSceneResolver.gd"
    for p, label in [(redesign, "RedesignTest"), (legacy, "legacy Editable"), (resolver, "MissionSceneResolver")]:
        if not p.is_file():
            errors.append(f"missing {label}: {p}")

    if resolver.is_file():
        txt = resolver.read_text(encoding="utf-8", errors="replace")
        if "taco_bell_drop" not in txt:
            errors.append("MissionSceneResolver: missing taco_bell_drop")
        if "TacoBellIso_Editable_RedesignTest.tscn" not in txt:
            errors.append("MissionSceneResolver: missing RedesignTest playable path")

    bp = (rep / "phase0md4_mission_design_blueprint.md").read_text(encoding="utf-8", errors="replace") if (rep / "phase0md4_mission_design_blueprint.md").is_file() else ""
    for needle in ["Louis", "garage_entry_beam", "code gate", "poop", "pause", "reset", "MissionPauseDataProvider", "objective"]:
        if needle.lower() not in bp.lower():
            errors.append(f"blueprint md missing keyword hint: {needle}")

    d5j = rep / "phase0md4_d5_implementation_spec.json"
    if d5j.is_file():
        d5 = json.loads(d5j.read_text(encoding="utf-8"))
        pres = " ".join(d5.get("must_preserve", [])).lower()
        if "redesigntest" not in pres and "redesign" not in pres:
            errors.append("d5 must_preserve should mention RedesignTest playable route")
        if not d5.get("d5_phases") or len(d5["d5_phases"]) < 3:
            errors.append("d5_phases should have at least 3 ordered phases")
        for key in (
            "protected_files",
            "likely_modified_files",
            "acceptance_criteria",
            "stop_conditions",
            "static_validation",
            "runtime_validation",
        ):
            if key not in d5 or not d5[key]:
                errors.append(f"d5 spec missing non-empty {key}")
        bad = " ".join(d5.get("drop_for_now_items", [])).lower()
        if "legacy" in bad and "redesign" in bad:
            pass
        joined = json.dumps(d5).lower()
        if "tacobelliso_editable.tscn" in joined and "playable" in joined and "redesigntest" not in joined:
            errors.append("d5 spec may instruct legacy editable as playable — verify")

    risk = rep / "phase0md4_risk_deferral_plan.json"
    if risk.is_file():
        rj = json.loads(risk.read_text(encoding="utf-8"))
        for k in ("p0", "p1", "p2", "p3"):
            if k not in rj or not rj[k]:
                errors.append(f"risk plan missing {k}")

    mech = rep / "phase0md4_existing_taco_mechanic_audit.json"
    if mech.is_file():
        mj = json.loads(mech.read_text(encoding="utf-8"))
        ids = [m.get("id") for m in mj.get("mechanics", [])]
        for req in ("beam_one_shot", "code_gate_keypad", "louis_bypass_route", "poop_bag_aimed_throw"):
            if req not in ids:
                errors.append(f"mechanic audit missing {req}")

    try:
        out = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=60,
        )
        changed = [ln.strip() for ln in out.stdout.splitlines() if ln.strip()] if out.returncode == 0 else []
    except (OSError, subprocess.TimeoutExpired):
        changed = []

    allowed_prefixes = (
        "docs/reports/taco_bell_redesign_d4/",
        "src/tools/editor/taco_bell_redesign_d4/",
    )
    for rel in changed:
        r = rel.replace("\\", "/")
        if not any(r.startswith(a) for a in allowed_prefixes):
            errors.append(f"D4 git diff vs HEAD touches non-D4 path (disallowed for this pass): {rel}")

    ok = len(errors) == 0
    result = {"ok": ok, "errors": errors, "root": str(root.resolve())}
    print(json.dumps(result, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
