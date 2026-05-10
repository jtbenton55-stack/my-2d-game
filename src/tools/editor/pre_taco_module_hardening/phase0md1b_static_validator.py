#!/usr/bin/env python3
"""0M-D1B static checks: no TacoBellDialogue preload in IsoMissionBase, reports exist, reset API present."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
REPORTS = ROOT / "docs/reports/pre_taco_module_hardening"
ISO = ROOT / "src" / "levels" / "IsoMissionBase.gd"
PLAYER = ROOT / "src" / "player" / "Player.gd"
PG = ROOT / "project.godot"


def main() -> int:
    ok = True
    out: dict = {"checks": []}

    txt = ISO.read_text(encoding="utf-8", errors="replace")
    if re.search(r"preload\s*\(\s*[\"']res://src/missions/iso/runtime/TacoBellDialogue\.gd", txt):
        out["checks"].append({"name": "iso_no_taco_dialogue_preload", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "iso_no_taco_dialogue_preload", "ok": True})

    if "reset_mission_runtime_for_new_attempt" not in txt:
        out["checks"].append({"name": "iso_reset_contract_method", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "iso_reset_contract_method", "ok": True})

    if "handle_tool_use" not in txt or "MissionToolSurfaceHelper" not in PLAYER.read_text(encoding="utf-8", errors="replace"):
        out["checks"].append({"name": "tool_surface_wiring", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "tool_surface_wiring", "ok": True})

    if "PlayerStaminaController" not in PLAYER.read_text(encoding="utf-8", errors="replace"):
        out["checks"].append({"name": "player_stamina", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "player_stamina", "ok": True})

    required = [
        "phase0md1b_safety_baseline.json",
        "phase0md1b_canonical_taco_scene_decision.json",
        "phase0md1b_dialogue_boundary.json",
        "phase0md1b_tool_surface.json",
        "phase0md1b_objective_ownership.json",
        "phase0md1b_stamina_hook.json",
        "phase0md1b_attempt_reset_contract.json",
        "phase0md1b_validation.json",
        "phase0md1b_pre_taco_module_hardening.json",
    ]
    for name in required:
        p = REPORTS / name
        c = {"name": f"report:{name}", "ok": p.exists()}
        if p.exists():
            try:
                json.loads(p.read_text(encoding="utf-8"))
                c["json_ok"] = True
            except json.JSONDecodeError:
                c["json_ok"] = False
                ok = False
        else:
            ok = False
        out["checks"].append(c)

    r = subprocess.run(["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"], capture_output=True, text=True)
    dirty = {ln.strip().replace("\\", "/") for ln in (r.stdout or "").splitlines() if ln.strip()}
    if "project.godot" in dirty:
        out["checks"].append({"name": "project_godot_clean_diff", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "project_godot_clean_diff", "ok": True})

    out["overall_ok"] = ok
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "phase0md1b_static_validator_result.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("phase0md1b_static_validator:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
