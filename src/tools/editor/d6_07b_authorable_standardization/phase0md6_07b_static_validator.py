#!/usr/bin/env python3
"""PHASE 0M-D6-07B authorable taxonomy + standardization validator (read-only)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPORT_DIR = "d6_07b_authorable_standardization"
PLACEHOLDER_TOKENS = ("CHANGE_ME", "CHANGE_ME_UNIQUE_ID", "TODO_ID")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def collect_scene_nodes_with_ids(scene_text: str) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    current_name = ""
    for line in scene_text.splitlines():
        if line.startswith("[node name="):
            m = re.search(r'name="([^"]+)"', line)
            current_name = m.group(1) if m else ""
        if "collectible_id = &" in line:
            m = re.search(r'collectible_id = &"([^"]*)"', line)
            if m:
                out.append((current_name, m.group(1).strip()))
    return out


def collect_case_cash_amounts(scene_text: str) -> list[int]:
    out: list[int] = []
    for line in scene_text.splitlines():
        if "case_cash_amount =" in line:
            m = re.search(r"case_cash_amount = (-?\d+)", line)
            if m:
                out.append(int(m.group(1)))
    return out


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []
    warnings: list[str] = []

    money_author = root / "src/missions/iso/authoring/MoneyPickupAuthor.gd"
    case_cash_author = root / "src/missions/iso/authoring/CaseCashAuthor.gd"
    builder = root / "src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd"
    mission = root / "src/levels/IsoMissionBase.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco_scene = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    taxonomy_guide = root / "docs/reports/d6_07b_authorable_standardization/D6_07B_AUTHORABLE_TAXONOMY_AND_PLACEMENT_GUIDE.md"
    templates_dir = root / "scenes/missions_iso/authoring_templates"

    if not case_cash_author.is_file():
        errors.append("missing CaseCashAuthor.gd")

    if not money_author.is_file():
        errors.append("missing MoneyPickupAuthor.gd")
    else:
        mt = read_text(money_author)
        if 'return "case_cash"' not in mt:
            errors.append("MoneyPickupAuthor must be alias-only to case_cash")
        if "DEPRECATED" not in mt:
            warnings.append("MoneyPickupAuthor should include deprecation guidance")

    if builder.is_file():
        bt = read_text(builder)
        for needle in ("duplicate_ids", "case_cash", "evidence_clue", "glow_guy"):
            if needle not in bt:
                errors.append(f"CollectibleAuthoringRuntimeBuilder missing {needle}")
    else:
        errors.append("missing CollectibleAuthoringRuntimeBuilder.gd")

    if mission.is_file():
        mt = read_text(mission)
        for needle in (
            "d6_06_duplicate_author_id_count",
            "d6_06_pending_case_cash_amount",
            "d6_06_pending_case_cash_instances",
            'ctype in ["money", "case_cash"]',
        ):
            if needle not in mt:
                errors.append(f"IsoMissionBase missing {needle}")
    else:
        errors.append("missing IsoMissionBase.gd")

    if panel.is_file():
        pt = read_text(panel)
        if "Case Cash" not in pt:
            errors.append("IsoMissionDebugPanel should use Case Cash wording")
        if "d6_06_duplicate_author_id_count" not in pt:
            errors.append("IsoMissionDebugPanel missing duplicate author ID visibility")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if not taco_scene.is_file():
        errors.append("missing TacoBellIso_Editable_RedesignTest.tscn")
    else:
        ttext = read_text(taco_scene)
        node_ids = collect_scene_nodes_with_ids(ttext)
        seen: dict[str, str] = {}
        duplicate_ids: list[str] = []
        missing_ids = 0
        placeholder_ids: list[str] = []
        for _node, cid in node_ids:
            if cid == "":
                missing_ids += 1
            if any(tok in cid for tok in PLACEHOLDER_TOKENS):
                placeholder_ids.append(cid)
            if cid in seen:
                duplicate_ids.append(cid)
            else:
                seen[cid] = _node
        if missing_ids > 0:
            errors.append(f"Taco proof scene has {missing_ids} missing collectible_id entries")
        if placeholder_ids:
            errors.append(f"Taco proof scene has placeholder IDs: {sorted(set(placeholder_ids))}")
        if duplicate_ids:
            errors.append(f"Taco proof scene has duplicate collectible IDs: {sorted(set(duplicate_ids))}")

        if ttext.count("CaseCash") < 2:
            errors.append("Taco proof scene should contain at least two Case Cash authors")
        if ttext.count("PoopBag") < 2:
            errors.append("Taco proof scene should contain at least two poop bag authors")
        if ttext.count("Clue") < 2:
            warnings.append("Only one clue author detected; recommend >=2 unique one-shot proofs")

        for amount in collect_case_cash_amounts(ttext):
            if amount <= 0:
                errors.append(f"invalid case_cash_amount detected in taco scene: {amount}")

    if not taxonomy_guide.is_file():
        errors.append("missing D6_07B authorable taxonomy guide")

    if not templates_dir.is_dir():
        warnings.append("authoring_templates directory not found; copy/duplicate workflow must be docs-only")
    else:
        template_files = sorted(templates_dir.glob("*.tscn"))
        if not template_files:
            warnings.append("authoring_templates exists but has no template scenes")
        for t in template_files:
            text = read_text(t)
            if "CHANGE_ME_UNIQUE_ID" not in text:
                warnings.append(f"template missing CHANGE_ME_UNIQUE_ID placeholder: {t.name}")

    rd.mkdir(parents=True, exist_ok=True)
    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
    }
    (rd / "phase0md6_07b_static_validator_run.json").write_text(
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
