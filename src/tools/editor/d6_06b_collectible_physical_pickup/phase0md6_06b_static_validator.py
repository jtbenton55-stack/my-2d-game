#!/usr/bin/env python3
"""PHASE 0M-D6-06B collectible physical pickup + F10 sections static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_06b_collectible_physical_pickup"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    pickup = root / "src/missions/iso/runtime/AuthoredCollectiblePickup.gd"
    builder = root / "src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    mission = root / "src/levels/IsoMissionBase.gd"
    base = root / "src/missions/iso/authoring/CollectibleAuthorBase.gd"

    if pickup.is_file():
        pt = pickup.read_text(encoding="utf-8")
        for needle in (
            "body_entered",
            "_on_body_entered",
            "monitoring = true",
            "CollisionShape2D",
            "pickup_radius",
            "get_runtime_pickup_debug_state",
            '"source"',
        ):
            if needle not in pt:
                errors.append(f"AuthoredCollectiblePickup missing {needle}")
    else:
        errors.append("missing AuthoredCollectiblePickup.gd")

    if builder.is_file():
        bt = builder.read_text(encoding="utf-8")
        if "parent.add_child(pickup)" not in bt or bt.find("add_child(shape)") > bt.find("parent.add_child(pickup)"):
            errors.append("builder should add CollisionShape2D before parent.add_child(pickup)")
    else:
        errors.append("missing CollectibleAuthoringRuntimeBuilder.gd")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        for needle in (
            "DEBUG_FOCUS_SECTION",
            "SHOW_COLLAPSED_DEBUG_SECTIONS",
            "_format_debug_section",
            "d6_06_last_pickup_source",
            "collectibles",
        ):
            if needle not in pt:
                errors.append(f"IsoMissionDebugPanel missing {needle}")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if mission.is_file():
        mt = mission.read_text(encoding="utf-8")
        if "d6_06_last_pickup_source" not in mt:
            errors.append("IsoMissionBase missing d6_06_last_pickup_source")
        if "d6_06_physical_overlap_verified" not in mt:
            errors.append("IsoMissionBase missing d6_06_physical_overlap_verified")
    else:
        errors.append("missing IsoMissionBase.gd")

    if base.is_file():
        bt = base.read_text(encoding="utf-8")
        if "pickup_radius" not in bt:
            errors.append("CollectibleAuthorBase missing pickup_radius")
    else:
        errors.append("missing CollectibleAuthorBase.gd")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_06b_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
