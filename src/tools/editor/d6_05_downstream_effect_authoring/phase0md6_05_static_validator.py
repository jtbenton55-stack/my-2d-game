#!/usr/bin/env python3
"""PHASE 0M-D6-05 downstream effect authoring static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_05_downstream_effect_authoring"
FORBIDDEN = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    scripts = {
        "SecurityEffectAuthorBase.gd": root / "src/missions/iso/authoring/SecurityEffectAuthorBase.gd",
        "DoorLockEffectAuthor.gd": root / "src/missions/iso/authoring/DoorLockEffectAuthor.gd",
        "SecurityLockdownEffectAuthor.gd": root / "src/missions/iso/authoring/SecurityLockdownEffectAuthor.gd",
        "ObjectiveEffectAuthor.gd": root / "src/missions/iso/authoring/ObjectiveEffectAuthor.gd",
        "NodeToggleEffectAuthor.gd": root / "src/missions/iso/authoring/NodeToggleEffectAuthor.gd",
    }
    for name, path in scripts.items():
        if not path.is_file():
            errors.append(f"missing {name}")
            continue
        text = path.read_text(encoding="utf-8")
        if name == "SecurityEffectAuthorBase.gd":
            if "on_security_event" not in text:
                errors.append("SecurityEffectAuthorBase missing on_security_event")
        elif "extends" not in text or "SecurityEffectAuthorBase" not in text:
            errors.append(f"{name} must extend SecurityEffectAuthorBase")
        elif "_apply_effect" not in text:
            errors.append(f"{name} missing _apply_effect")

    root_gd = root / "src/missions/iso/authoring/SecurityAuthoringRoot.gd"
    if root_gd.is_file():
        rt = root_gd.read_text(encoding="utf-8")
        if "collect_effect_authors" not in rt:
            errors.append("SecurityAuthoringRoot missing collect_effect_authors")
    else:
        errors.append("missing SecurityAuthoringRoot.gd")

    builder = root / "src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd"
    if builder.is_file():
        bt = builder.read_text(encoding="utf-8")
        if "_register_effect_listeners" not in bt:
            errors.append("MissionAuthoringRuntimeBuilder missing effect registration")
    else:
        errors.append("missing MissionAuthoringRuntimeBuilder.gd")

    iso = root / "src/levels/IsoMissionBase.gd"
    if iso.is_file():
        it = iso.read_text(encoding="utf-8")
        if "_record_authoring_effect_result" not in it:
            errors.append("IsoMissionBase missing _record_authoring_effect_result")
        if "d6_05_effect_author_count" not in it:
            errors.append("IsoMissionBase missing d6_05 summary fields")
    else:
        errors.append("missing IsoMissionBase.gd")

    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "--- Downstream Effects ---" not in pt:
            errors.append("IsoMissionDebugPanel missing Downstream Effects section")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        for needle in (
            "CameraLockdownEffect_Author",
            "BeamObjectiveEffect_Author",
            "CameraProofToggleEffect_Author",
        ):
            if needle not in tt:
                errors.append(f"Taco scene missing proof node {needle}")
    else:
        errors.append("missing Taco scene")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_05_static_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
