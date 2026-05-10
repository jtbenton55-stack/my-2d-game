#!/usr/bin/env python3
"""0M-D1B-RT static preflight: D1B validator + file existence + IsoMissionBase Taco preload ban + git diff guards."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
D1B_VAL = ROOT / "src/tools/editor/pre_taco_module_hardening/phase0md1b_static_validator.py"
REPORTS = ROOT / "docs/reports/pre_taco_module_hardening_runtime"
ISO = ROOT / "src/levels/IsoMissionBase.gd"
PLAYER = ROOT / "src/player/Player.gd"
PG = ROOT / "project.godot"
SCRIPTS = [
    ROOT / "src/missions/dialogue/MissionDialogueProvider.gd",
    ROOT / "src/missions/taco_bell/TacoBellDialogueProvider.gd",
    ROOT / "src/missions/tools/MissionToolSurfaceHelper.gd",
    ROOT / "src/missions/objectives/MissionObjectiveBridge.gd",
    ROOT / "src/player/PlayerStaminaController.gd",
]
SCENES = [
    ROOT / "scenes/missions_iso/TacoBellIso_Editable.tscn",
    ROOT / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    ROOT / "scenes/hideout/HideoutHub.tscn",
]


def _run_d1b() -> tuple[bool, str]:
    if not D1B_VAL.exists():
        return False, "missing phase0md1b_static_validator.py"
    r = subprocess.run([sys.executable, str(D1B_VAL)], cwd=str(ROOT), capture_output=True, text=True)
    ok = r.returncode == 0
    return ok, (r.stdout or "") + (r.stderr or "")


def _git_dirty() -> set[str]:
    r = subprocess.run(["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"], capture_output=True, text=True)
    return {ln.strip().replace("\\", "/") for ln in (r.stdout or "").splitlines() if ln.strip()}


def main() -> int:
    ok = True
    out: dict = {"checks": []}

    d1_ok, d1_out = _run_d1b()
    out["d1b_static_validator"] = {"ok": d1_ok, "output_tail": d1_out[-800:]}
    out["checks"].append({"name": "d1b_static_validator", "ok": d1_ok})
    if not d1_ok:
        ok = False

    dirty = _git_dirty()
    if "project.godot" in dirty:
        out["checks"].append({"name": "project_godot_not_in_diff", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "project_godot_not_in_diff", "ok": True})

    iso_txt = ISO.read_text(encoding="utf-8", errors="replace")
    if re.search(r'preload\s*\(\s*["\']res://src/missions/iso/runtime/TacoBellDialogue\.gd', iso_txt):
        out["checks"].append({"name": "iso_no_taco_dialogue_preload", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "iso_no_taco_dialogue_preload", "ok": True})

    if "MissionToolSurfaceHelper" not in PLAYER.read_text(encoding="utf-8", errors="replace"):
        out["checks"].append({"name": "player_uses_tool_helper", "ok": False})
        ok = False
    else:
        out["checks"].append({"name": "player_uses_tool_helper", "ok": True})

    for p in SCRIPTS + SCENES:
        c = {"path": str(p.relative_to(ROOT)), "ok": p.exists()}
        out["checks"].append({"name": f"exists:{p.name}", "ok": c["ok"]})
        if not c["ok"]:
            ok = False

    gen_markers = ("generated", "imported", ".godot/imported", "icon_catalog", "object_palette")
    for d in dirty:
        if any(m in d.lower() for m in gen_markers) and "docs/reports" not in d:
            out["checks"].append({"name": f"suspicious_dirty:{d}", "ok": False})
            ok = False

    out["overall_ok"] = ok
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "phase0md1b_rt_static_preflight_machine.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("phase0md1b_rt_static_validator:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
