#!/usr/bin/env python3
"""PHASE 0M-D6-06 collectible authoring foundation static validator.

Superseded for new work: this validator targets the deprecated
AuthoredCollectiblePickup path. Use the later D6-06B interactable/hideout
sync validator and D6-07/D6-07B validators for current authored collectibles.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_06_collectible_authoring"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    authors = [
        "CollectibleAuthorBase.gd",
        "PoopBagAuthor.gd",
        "MoneyPickupAuthor.gd",
        "PolaroidAuthor.gd",
        "TinyIconAuthor.gd",
    ]
    for name in authors:
        p = root / "src/missions/iso/authoring" / name
        if not p.is_file():
            errors.append(f"missing author script {name}")
        elif "build_runtime_config" not in p.read_text(encoding="utf-8"):
            errors.append(f"{name} missing build_runtime_config")

    builder = root / "src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd"
    pickup = root / "src/missions/iso/runtime/AuthoredCollectiblePickup.gd"
    root_gd = root / "src/missions/iso/authoring/SecurityAuthoringRoot.gd"
    mission = root / "src/levels/IsoMissionBase.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    if builder.is_file():
        bt = builder.read_text(encoding="utf-8")
        for needle in (
            "collect_collectible_authors",
            "AuthoredGeneratedInteractables",
            "AuthoredPhase0JInteractablePickup",
            "phase0j_interactable",
        ):
            if needle not in bt:
                errors.append(f"builder missing {needle}")
    else:
        errors.append("missing CollectibleAuthoringRuntimeBuilder.gd")

    if pickup.is_file():
        pt = pickup.read_text(encoding="utf-8")
        if "TypedMissionCollectible" not in pt:
            errors.append("pickup missing TypedMissionCollectible integration")
    else:
        errors.append("missing AuthoredCollectiblePickup.gd")

    if root_gd.is_file():
        rt = root_gd.read_text(encoding="utf-8")
        if "collect_collectible_authors" not in rt:
            errors.append("SecurityAuthoringRoot missing collect_collectible_authors")
    else:
        errors.append("missing SecurityAuthoringRoot.gd")

    if mission.is_file():
        mt = mission.read_text(encoding="utf-8")
        for needle in (
            "_setup_d6_06_collectible_authoring_runtime",
            "record_authored_collectible_pickup",
            "d6_06_runtime_pickup_count",
        ):
            if needle not in mt:
                errors.append(f"IsoMissionBase missing {needle}")
    else:
        errors.append("missing IsoMissionBase.gd")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "Collectible Authoring" not in pt:
            errors.append("F10 missing Collectible Authoring section")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        for needle in (
            "CollectibleAuthoringProof",
            "D6_06_PoopBag_Author",
            "D6_06_Money_Author",
            "D6_06_Polaroid_Author",
            "D6_06_TinyIcon_Author",
        ):
            if needle not in tt:
                errors.append(f"Taco scene missing {needle}")
    else:
        errors.append("missing Taco scene")

    protected = [
        root / "project.godot",
        root / "src/player/Player.gd",
        root / "scenes/characters/player.tscn",
    ]
    for p in protected:
        if not p.is_file():
            errors.append(f"expected protected file missing: {p.name}")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_06_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
