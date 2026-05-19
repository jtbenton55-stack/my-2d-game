#!/usr/bin/env python3
"""PHASE 0M-D6-07 broader interactable authoring validator (read-only)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_07_broader_interactable_authoring"
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

    glow_author = root / "src/missions/iso/authoring/GlowGuyAuthor.gd"
    clue_author = root / "src/missions/iso/authoring/ClueAuthor.gd"
    case_cash_author = root / "src/missions/iso/authoring/CaseCashAuthor.gd"
    money_author = root / "src/missions/iso/authoring/MoneyPickupAuthor.gd"
    builder = root / "src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd"
    hideout_sync = root / "src/missions/iso/runtime/MissionCollectibleHideoutSync.gd"
    mission = root / "src/levels/IsoMissionBase.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    hideout_mgr = root / "src/hideout/HideoutManager.gd"
    hideout_state = root / "src/hideout/HideoutStateController.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    for path, label in (
        (glow_author, "GlowGuyAuthor.gd"),
        (clue_author, "ClueAuthor.gd"),
        (case_cash_author, "CaseCashAuthor.gd"),
    ):
        if not path.is_file():
            errors.append(f"missing {label}")
        else:
            text = read_text(path)
            if "CollectibleAuthorBase" not in text and "MoneyPickupAuthor" not in text:
                errors.append(f"{label} must extend CollectibleAuthorBase (or MoneyPickupAuthor)")

    if money_author.is_file():
        mt = read_text(money_author)
        if "commits_as_case_cash" not in mt:
            warnings.append("MoneyPickupAuthor should bridge money to Case Cash")
    else:
        errors.append("missing MoneyPickupAuthor.gd")

    if builder.is_file():
        bt = read_text(builder)
        for needle in ("glow_guy", "evidence_clue", "case_cash"):
            if needle not in bt:
                errors.append(f"CollectibleAuthoringRuntimeBuilder missing {needle}")
    else:
        errors.append("missing CollectibleAuthoringRuntimeBuilder.gd")

    if hideout_sync.is_file():
        ht = read_text(hideout_sync)
        for needle in ("commit_case_cash", "apply_banked_case_cash_to_hideout", "CASE_CASH_BANK_FLAG"):
            if needle not in ht:
                errors.append(f"MissionCollectibleHideoutSync missing {needle}")
    else:
        errors.append("missing MissionCollectibleHideoutSync.gd")

    if mission.is_file():
        mt = read_text(mission)
        for needle in (
            "commit_authored_collectibles_for_success",
            "d6_06_pending_case_cash_amount",
            "d6_06_glow_guy_author_count",
            "d6_06_clue_author_count",
            "PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS",
        ):
            if needle not in mt:
                errors.append(f"IsoMissionBase missing {needle}")
        if 'ctype in ["money", "case_cash"]' not in mt.replace(" ", ""):
            if 'ctype == "money"' in mt and "case_cash" not in mt.split("_commit_authored_money")[0][-500:]:
                errors.append("IsoMissionBase commit should handle case_cash type")
    else:
        errors.append("missing IsoMissionBase.gd")

    if panel.is_file():
        pt = read_text(panel)
        for needle in ("d6_06_pending_case_cash_amount", "d6_06_glow_guy_author_count", "d6_06_clue_corkboard_sync"):
            if needle not in pt:
                errors.append(f"IsoMissionDebugPanel missing {needle}")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if hideout_mgr.is_file():
        hmt = read_text(hideout_mgr)
        if "apply_banked_case_cash_to_hideout" not in hmt:
            errors.append("HideoutManager must apply banked Case Cash on load")
    if hideout_state.is_file():
        hst = read_text(hideout_state)
        if "add_case_cash" not in hst:
            errors.append("HideoutStateController missing add_case_cash")
        if "glow_guy_taco_bell" not in hst or "clue_sauce_packet" not in hst:
            errors.append("HideoutStateController missing glow/clue display keys")

    if taco.is_file():
        tt = read_text(taco)
        for needle in ("D6_07_GlowGuy_Author", "D6_07_Clue_Author", "D6_07_CaseCash_Author"):
            if needle not in tt:
                errors.append(f"Taco scene missing proof node {needle}")
    else:
        warnings.append("TacoBellIso_Editable_RedesignTest.tscn not found")

    for rel in PROTECTED:
        p = root / rel
        if p.exists() and p.stat().st_mtime > (root / "src/levels/IsoMissionBase.gd").stat().st_mtime:
            warnings.append(f"protected file may have been touched recently: {rel}")

    rd.mkdir(parents=True, exist_ok=True)
    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
    }
    (rd / "phase0md6_07_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    if errors:
        print("FAIL")
        for e in errors:
            print(f"  ERROR: {e}")
        for w in warnings:
            print(f"  WARN: {w}")
        return 1
    print("PASS")
    for w in warnings:
        print(f"  WARN: {w}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
