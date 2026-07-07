#!/usr/bin/env python3
"""PHASE 0M-D6-03 security event + guard/patrol authoring static validator."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_03_security_event_guard_patrol_authoring"
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
    builder = root / "src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd"
    area = root / "src/missions/iso/authoring/AreaTriggerAuthor.gd"
    beam = root / "src/missions/iso/authoring/SecurityBeamAuthor.gd"
    spawn = root / "src/missions/iso/authoring/GuardSpawnAuthor.gd"
    patrol = root / "src/missions/iso/authoring/GuardPatrolRouteAuthor.gd"
    iso = root / "src/levels/IsoMissionBase.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    for p, name in (
        (router, "SecurityEventRouter"),
        (builder, "MissionAuthoringRuntimeBuilder"),
        (area, "AreaTriggerAuthor"),
    ):
        if not p.is_file():
            errors.append(f"missing {name}")

    if beam.is_file():
        bt = beam.read_text(encoding="utf-8")
        for needle in ("on_trip_event", "emit_event_on_trip"):
            if needle not in bt:
                errors.append(f"SecurityBeamAuthor missing {needle}")
    else:
        errors.append("SecurityBeamAuthor missing")

    if spawn.is_file():
        st = spawn.read_text(encoding="utf-8")
        for needle in ("trigger_events", "initial_behavior", "on_security_event", "guard_archetype"):
            if needle not in st:
                errors.append(f"GuardSpawnAuthor missing {needle}")
    else:
        errors.append("GuardSpawnAuthor missing")

    if patrol.is_file():
        pt = patrol.read_text(encoding="utf-8")
        if "get_patrol_points_global" not in pt or "route_id" not in pt:
            errors.append("GuardPatrolRouteAuthor missing route helpers")
    else:
        errors.append("GuardPatrolRouteAuthor missing")

    if iso.is_file():
        it = iso.read_text(encoding="utf-8")
        for needle in (
            "_setup_d6_03_authoring_security_runtime",
            "_emit_security_authoring_event",
            "_spawn_guard_from_authoring_spawn",
            "_should_suppress_direct_beam_guard_spawn",
            "d6_03_security_router_active",
        ):
            if needle not in it:
                errors.append(f"IsoMissionBase missing {needle}")
    else:
        errors.append("IsoMissionBase missing")

    if panel.is_file():
        panel_text = panel.read_text(encoding="utf-8")
        if "Security Authoring" not in panel_text or "Event Router" not in panel_text:
            errors.append("F10 missing Security Authoring/Event Router sections")
    else:
        errors.append("IsoMissionDebugPanel missing")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        for needle in ("AmbushGuardSpawn_Author", "ambush_beam_tripped", "AreaTriggerAuthor.gd"):
            if needle not in tt:
                errors.append(f"Taco scene missing {needle}")
    else:
        errors.append("Taco scene missing")

    impl = rd / "phase0md6_03_implementation.md"
    if not impl.is_file():
        errors.append(f"missing {impl.relative_to(root)}")

    for bad in FORBIDDEN:
        for c in git_changed(root):
            if bad in c:
                errors.append(f"forbidden modified: {c}")

    rd.mkdir(parents=True, exist_ok=True)
    (rd / "phase0md6_03_static_validator_run.json").write_text(
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
