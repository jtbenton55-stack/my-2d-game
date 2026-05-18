#!/usr/bin/env python3
"""PHASE 0M-D6-06B interactable-backed collectible authoring + hideout sync validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_06b_interactable_collectible_hideout_sync"
PROTECTED = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []
    warnings: list[str] = []

    authored_pickup = root / "src/missions/iso/runtime/AuthoredPhase0JInteractablePickup.gd"
    deprecated_pickup = root / "src/missions/iso/runtime/AuthoredCollectiblePickup.gd"
    interaction_bridge = root / "src/missions/iso/runtime/Phase0JInteractionBridge.gd"
    builder = root / "src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd"
    hideout_sync = root / "src/missions/iso/runtime/MissionCollectibleHideoutSync.gd"
    mission = root / "src/levels/IsoMissionBase.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    hideout_mgr = root / "src/hideout/HideoutManager.gd"
    hideout_state = root / "src/hideout/HideoutStateController.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    if not authored_pickup.is_file():
        errors.append("missing AuthoredPhase0JInteractablePickup.gd")
    else:
        apt = read_text(authored_pickup)
        if "extends Phase0JInteractablePickup" not in apt:
            errors.append("AuthoredPhase0JInteractablePickup must extend Phase0JInteractablePickup")
        if "record_authored_collectible_attempt" not in apt:
            errors.append("AuthoredPhase0JInteractablePickup must route to record_authored_collectible_attempt")

    if interaction_bridge.is_file():
        bt = interaction_bridge.read_text(encoding="utf-8")
        if "phase0k_louis_exit" not in bt:
            errors.append("Phase0JInteractionBridge must include phase0k_louis_exit candidates")
    else:
        errors.append("missing Phase0JInteractionBridge.gd")

    pickup_j = root / "src/missions/iso/runtime/Phase0JInteractablePickup.gd"
    if pickup_j.is_file():
        pt = pickup_j.read_text(encoding="utf-8")
        if "is_interaction_available" not in pt or "collected" not in pt.split("is_interaction_available")[1][:200]:
            errors.append("Phase0JInteractablePickup should gate is_interaction_available when collected")
    else:
        errors.append("missing Phase0JInteractablePickup.gd")

    if not builder.is_file():
        errors.append("missing CollectibleAuthoringRuntimeBuilder.gd")
    else:
        bt = read_text(builder)
        if "AuthoredPhase0JInteractablePickup" not in bt:
            errors.append("builder must spawn AuthoredPhase0JInteractablePickup")
        if "AuthoredCollectiblePickup" in bt:
            errors.append("builder must not spawn deprecated AuthoredCollectiblePickup")
        if "AuthoredGeneratedInteractables" not in bt:
            errors.append("builder must parent under AuthoredGeneratedInteractables")
        if "phase0j_interactable" not in bt and "Phase0J" not in bt:
            warnings.append("builder may not document phase0j path explicitly")

    if deprecated_pickup.is_file():
        dt = read_text(deprecated_pickup)
        if "DEPRECATED" not in dt:
            warnings.append("AuthoredCollectiblePickup should be marked DEPRECATED")

    if not hideout_sync.is_file():
        errors.append("missing MissionCollectibleHideoutSync.gd")
    else:
        ht = read_text(hideout_sync)
        for needle in ("mark_hideout_display_found", "apply_persisted_flags_to_hideout_state"):
            if needle not in ht:
                errors.append(f"MissionCollectibleHideoutSync missing {needle}")

    if not mission.is_file():
        errors.append("missing IsoMissionBase.gd")
    else:
        mt = read_text(mission)
        for needle in (
            "_d6_06_pending_collectibles",
            "record_authored_collectible_attempt",
            "_commit_pending_authored_collectibles",
            "_clear_pending_authored_collectibles",
            "fail_level",
        ):
            if needle not in mt:
                errors.append(f"IsoMissionBase missing {needle}")
        if "request_exit_completion" not in mt or "_commit_pending_authored_collectibles" not in mt:
            errors.append("mission success path must commit pending collectibles")
        if mt.find("_clear_pending_authored_collectibles") > mt.find("func fail_level"):
            pass
        else:
            errors.append("fail_level should clear pending authored collectibles")

    if not panel.is_file():
        errors.append("missing IsoMissionDebugPanel.gd")
    else:
        pt = read_text(panel)
        for needle in (
            "d6_06_pending_collectible_count",
            "d6_06_committed_collectible_count",
            "d6_06_runtime_path_kind",
            "d6_06_hideout_sync_status",
        ):
            if needle not in pt:
                errors.append(f"IsoMissionDebugPanel missing {needle}")

    if hideout_mgr.is_file():
        hmt = read_text(hideout_mgr)
        if "apply_persisted_flags_to_hideout_state" not in hmt:
            errors.append("HideoutManager must apply persisted hideout display flags on load")
    else:
        errors.append("missing HideoutManager.gd")

    if hideout_state.is_file():
        hst = read_text(hideout_state)
        if "mark_collectible_display_found" not in hst:
            errors.append("HideoutStateController missing mark_collectible_display_found")
        if "hideout_state_controller" not in hst:
            errors.append("HideoutStateController missing hideout_state_controller group")
    else:
        errors.append("missing HideoutStateController.gd")

    if taco.is_file():
        tt = read_text(taco)
        for proof in (
            "D6_06_PoopBag_Author",
            "D6_06_Money_Author",
            "D6_06_Polaroid_Author",
            "D6_06_TinyIcon_Author",
            "CollectibleAuthoringProof",
        ):
            if proof not in tt:
                errors.append(f"Taco scene missing proof node {proof}")
    else:
        errors.append("missing TacoBellIso_Editable_RedesignTest.tscn")

    for rel in PROTECTED:
        path = root / rel
        if not path.is_file():
            warnings.append(f"protected file not found for check: {rel}")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors, "warnings": warnings}
    (rd / "phase0md6_06b_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    print("PASS" if result["pass"] else "FAIL")
    for w in warnings:
        print(f"  warn: {w}")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
