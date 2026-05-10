#!/usr/bin/env python3
"""0M-D1C static checks: playable Taco routes -> RedesignTest; legacy Editable preserved; key files unchanged."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
REPORTS = ROOT / "docs/reports/taco_canonical_scene_correction"
EXPANDED = "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
EXPECTED_CONST = f'const TACO_BELL_SCENE := "{EXPANDED}"'
SCENEMGR_SNIPPET = f'scene_path = "{EXPANDED}"'
FILES = {
    "HideoutMissionBoardController": ROOT / "src/hideout/HideoutMissionBoardController.gd",
    "HideoutStationCatalog": ROOT / "src/hideout/HideoutStationCatalog.gd",
    "SceneManager": ROOT / "src/autoload/SceneManager.gd",
    "IsoMissionDebugPanel": ROOT / "src/missions/iso/runtime/IsoMissionDebugPanel.gd",
}


def _git_diff_names() -> set[str]:
    r = subprocess.run(["git", "-C", str(ROOT), "diff", "--name-only", "HEAD"], capture_output=True, text=True)
    return {ln.strip().replace("\\", "/") for ln in (r.stdout or "").splitlines() if ln.strip()}


def main() -> int:
    ok = True
    checks: list[dict] = []

    for label, p in [
        ("expanded_scene_exists", ROOT / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"),
        ("legacy_scene_exists", ROOT / "scenes/missions_iso/TacoBellIso_Editable.tscn"),
    ]:
        exists = p.exists()
        checks.append({"name": label, "ok": exists, "path": str(p.relative_to(ROOT))})
        ok = ok and exists

    for name, path in FILES.items():
        txt = path.read_text(encoding="utf-8", errors="replace")
        if name in ("HideoutMissionBoardController", "HideoutStationCatalog"):
            c_ok = EXPECTED_CONST in txt
        elif name == "SceneManager":
            c_ok = SCENEMGR_SNIPPET in txt
        else:
            c_ok = f'SceneManager.change_scene("{EXPANDED}")' in txt
        checks.append({"name": f"route:{name}", "ok": c_ok})
        ok = ok and c_ok

    dirty = _git_diff_names()
    for forbidden in ("project.godot", "scenes/characters/player.tscn"):
        hit = forbidden in dirty
        checks.append({"name": f"not_dirty:{forbidden}", "ok": not hit})
        ok = ok and (not hit)

    for taco in ("scenes/missions_iso/TacoBellIso_Editable.tscn", "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"):
        checks.append({"name": f"taco_scene_not_modified:{taco}", "ok": taco not in dirty})
        ok = ok and (taco not in dirty)

    player_txt = (ROOT / "src/player/Player.gd").read_text(encoding="utf-8", errors="replace")
    no_taco_path_in_player = "TacoBellIso" not in player_txt
    checks.append({"name": "player_gd_has_no_taco_scene_paths", "ok": no_taco_path_in_player})
    ok = ok and no_taco_path_in_player

    out = {"overall_ok": ok, "checks": checks}
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "phase0md1c_validation.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("phase0md1c_static_validator:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
