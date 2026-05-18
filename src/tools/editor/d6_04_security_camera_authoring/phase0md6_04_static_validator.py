#!/usr/bin/env python3
"""PHASE 0M-D6-04 security camera authoring + event hardening static validator."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_04_security_camera_authoring"
FORBIDDEN = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
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

    router = root / "src/missions/iso/runtime/SecurityEventRouter.gd"
    cam = root / "src/missions/iso/authoring/SecurityCameraAuthor.gd"
    spawn = root / "src/missions/iso/authoring/GuardSpawnAuthor.gd"
    builder = root / "src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd"
    iso = root / "src/levels/IsoMissionBase.gd"
    guard = root / "src/enemies/Guard.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    if not router.is_file():
        errors.append("missing SecurityEventRouter")
    else:
        rt = router.read_text(encoding="utf-8")
        for needle in ("listeners_handled", "get_last_dispatch_result", "return result"):
            if needle not in rt:
                errors.append(f"SecurityEventRouter missing {needle}")

    if not cam.is_file():
        errors.append("missing SecurityCameraAuthor")
    else:
        ct = cam.read_text(encoding="utf-8")
        for needle in ("on_alarm_event", "setup_runtime_camera", "build_runtime_config", "sweep_enabled"):
            if needle not in ct:
                errors.append(f"SecurityCameraAuthor missing {needle}")

    if not spawn.is_file():
        errors.append("missing GuardSpawnAuthor")
    else:
        st = spawn.read_text(encoding="utf-8")
        if '"handled"' not in st and "handled" not in st:
            errors.append("GuardSpawnAuthor missing handled result")
        if "rejected_cooldown" not in st:
            errors.append("GuardSpawnAuthor missing rejection reasons")

    if not builder.is_file():
        errors.append("missing MissionAuthoringRuntimeBuilder")
    else:
        bt = builder.read_text(encoding="utf-8")
        if "_setup_authored_cameras" not in bt:
            errors.append("MissionAuthoringRuntimeBuilder missing camera setup")

    if iso.is_file():
        it = iso.read_text(encoding="utf-8")
        for needle in ("_should_suppress_direct_spawn_for_event", "_bind_authored_security_camera", "d6_04_last_event_handled"):
            if needle not in it:
                errors.append(f"IsoMissionBase missing {needle}")
    else:
        errors.append("missing IsoMissionBase")

    if guard.is_file():
        gt = guard.read_text(encoding="utf-8")
        if "authoring_force_chase" not in gt:
            errors.append("Guard missing authoring_force_chase")
    else:
        errors.append("missing Guard.gd")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "D6-04 Events / Cameras" not in pt:
            errors.append("IsoMissionDebugPanel missing D6-04 section")
    else:
        errors.append("missing IsoMissionDebugPanel")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        for needle in ("TestCamera_Author", "test_camera_alarm", "CameraAlarmGuardSpawn_Author"):
            if needle not in tt:
                errors.append(f"Taco scene missing {needle}")
    else:
        errors.append("missing Taco scene")

    changed = git_changed(root)
    for path in changed:
        for bad in FORBIDDEN:
            if path.replace("\\", "/").startswith(bad):
                errors.append(f"forbidden change: {path}")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors, "changed_files": changed}
    (rd / "phase0md6_04_static_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
