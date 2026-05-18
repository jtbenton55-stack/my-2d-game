#!/usr/bin/env python3
"""PHASE 0M-D6-02 security authoring foundation static validator."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_02_security_authoring_foundation"
FORBIDDEN = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
    "assets/",
]
AUTHORING_SCRIPTS = [
    "src/missions/iso/authoring/SecurityAuthoringRoot.gd",
    "src/missions/iso/authoring/SecurityBeamAuthor.gd",
    "src/missions/iso/authoring/SecurityCameraAuthor.gd",
    "src/missions/iso/authoring/GuardSpawnAuthor.gd",
    "src/missions/iso/authoring/GuardPatrolRouteAuthor.gd",
]
BEAM_EXPORTS = [
    "beam_id",
    "enabled",
    "visual_height",
    "visual_width",
    "trigger_width",
    "trigger_extra_height",
    "alarm_id",
    "one_shot",
    "preview_color",
    "label_visible",
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

    for rel in AUTHORING_SCRIPTS:
        p = root / rel
        if not p.is_file():
            errors.append(f"missing {rel}")
            continue
        t = p.read_text(encoding="utf-8")
        if "@tool" not in t:
            errors.append(f"{rel} missing @tool")

    beam = root / "src/missions/iso/authoring/SecurityBeamAuthor.gd"
    if beam.is_file():
        bt = beam.read_text(encoding="utf-8")
        for ex in BEAM_EXPORTS:
            if f"@export var {ex}" not in bt and f"@export var {ex}:" not in bt:
                errors.append(f"SecurityBeamAuthor missing export {ex}")
        if "build_runtime_config" not in bt:
            errors.append("SecurityBeamAuthor missing build_runtime_config")

    root_script = root / "src/missions/iso/authoring/SecurityAuthoringRoot.gd"
    if root_script.is_file():
        rt = root_script.read_text(encoding="utf-8")
        if "find_enabled_beam_author" not in rt:
            errors.append("SecurityAuthoringRoot missing find_enabled_beam_author")

    iso = root / "src/levels/IsoMissionBase.gd"
    if not iso.is_file():
        errors.append("IsoMissionBase.gd missing")
    else:
        t = iso.read_text(encoding="utf-8")
        for needle in (
            "D6_02_SECURITY_AUTHORING_ROOT_PATH",
            "_find_security_authoring_root",
            "_setup_ambush_beam_from_security_beam_author",
            "_store_d6_02_authoring_summary",
            'd6_02_ambush_beam_source',
            "find_enabled_beam_author",
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
            if "_setup_ambush_beam_from_security_beam_author" not in body:
                errors.append("setup must call authoring beam path")
            if "find_enabled_beam_author" not in body:
                errors.append("setup must find_enabled_beam_author")
            if '_store_d6_02_authoring_summary(sec_root, "fix7f_fallback"' not in body:
                errors.append("setup must store fix7f_fallback when no author")

    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    if not panel.is_file():
        errors.append("IsoMissionDebugPanel missing")
    else:
        pt = panel.read_text(encoding="utf-8")
        if "--- Security Authoring ---" not in pt:
            errors.append("IsoMissionDebugPanel missing Security Authoring F10 block")
        if "d6_02_ambush_beam_source" not in pt:
            errors.append("IsoMissionDebugPanel missing d6_02_ambush_beam_source")

    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    if not taco.is_file():
        errors.append("Taco scene missing")
    else:
        tt = taco.read_text(encoding="utf-8")
        if "SecurityAuthoringRoot" not in tt:
            errors.append("Taco scene missing SecurityAuthoringRoot")
        if "SecurityBeamAuthor.gd" not in tt:
            errors.append("Taco scene missing SecurityBeamAuthor")
        if "AMBUSH_security_beam" not in tt:
            errors.append("Taco scene missing AMBUSH_security_beam author node")

    impl = rd / "phase0md6_02_implementation.md"
    if not impl.is_file():
        errors.append(f"missing {impl.relative_to(root)}")

    for bad in FORBIDDEN:
        for c in git_changed(root):
            if bad in c:
                errors.append(f"forbidden modified: {c}")

    for secret in (".env", "credentials", "id_rsa", "private_key"):
        if any(secret in c.lower() for c in git_changed(root)):
            errors.append(f"suspicious path in git diff: {secret}")

    rd.mkdir(parents=True, exist_ok=True)
    (rd / "phase0md6_02_static_validator_run.json").write_text(
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
