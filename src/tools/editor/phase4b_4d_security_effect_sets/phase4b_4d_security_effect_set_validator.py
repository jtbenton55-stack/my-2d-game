#!/usr/bin/env python3
"""Phase 4B-4D security EffectSet authoring validator (read-only)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase4b_4d_security_effect_sets"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def require_contains(errors: list[str], text: str, needle: str, label: str) -> None:
    if needle not in text:
        errors.append(f"{label} missing `{needle}`")


def main() -> int:
    root = repo_root()
    errors: list[str] = []
    warnings: list[str] = []

    author = root / "src/missions/iso/authoring/SecurityEffectSetAuthor.gd"
    root_script = root / "src/missions/iso/authoring/SecurityAuthoringRoot.gd"
    builder = root / "src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd"
    debug_panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    base = root / "src/levels/IsoMissionBase.gd"
    template = root / "scenes/missions_iso/security_authoring_templates/SecurityEffectSetAuthorTemplate.tscn"
    proof_scene = root / "scenes/dev/mission_authoring/SecurityEffectSetAuthorProofRoom.tscn"
    proof_controller = root / "src/missions/iso/dev/SecurityEffectSetAuthorProofController.gd"
    test_file = root / "tests/mission_authoring/SecurityEffectSetAuthorTest.gd"
    guide = root / "docs/SECURITY_AUTHORABLES_GUIDE.md"

    for path in (author, root_script, builder, debug_panel, base, template, proof_scene, proof_controller, test_file, guide):
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    author_text = read_text(author)
    require_contains(errors, author_text, "func get_debug_chain", "SecurityEffectSetAuthor")
    require_contains(errors, author_text, "func get_security_effect_debug_summary", "SecurityEffectSetAuthor")
    require_contains(errors, author_text, 'return "effect_set"', "SecurityEffectSetAuthor")
    require_contains(errors, author_text, "effect_set_applied_count", "SecurityEffectSetAuthor")

    require_contains(errors, read_text(root_script), "collect_effect_set_authors", "SecurityAuthoringRoot")
    require_contains(errors, read_text(builder), "_store_d6_05_effect_set_author_count", "MissionAuthoringRuntimeBuilder")
    require_contains(errors, read_text(base), "d6_05_effect_set_count", "IsoMissionBase")
    require_contains(errors, read_text(debug_panel), "EffectSet:", "IsoMissionDebugPanel")

    template_text = read_text(template)
    require_contains(errors, template_text, "SecurityEffectSetAuthor.gd", "SecurityEffectSetAuthorTemplate")
    require_contains(errors, template_text, "CHANGE_ME_TRIGGER_EVENT", "SecurityEffectSetAuthorTemplate")
    require_contains(errors, template_text, "CHANGE_ME_EFFECT_SET_ID", "SecurityEffectSetAuthorTemplate")
    require_contains(errors, template_text, "EffectSet.gd", "SecurityEffectSetAuthorTemplate")

    scene_text = read_text(proof_scene)
    for needle in (
        "SecurityAuthoringRoot",
        "AreaTriggerAuthor.gd",
        "SecurityEffectSetAuthor.gd",
        "phase4b_area_alarm",
        "phase4b_area_alarm_effect_seen",
        "SecurityEffectSetAuthorProofController.gd",
    ):
        require_contains(errors, scene_text, needle, "SecurityEffectSetAuthorProofRoom")

    test_text = read_text(test_file)
    require_contains(errors, test_text, "SecurityEffectSetAuthorProofRoom.tscn", "SecurityEffectSetAuthorTest")
    require_contains(errors, test_text, "get_security_effect_debug_summary", "SecurityEffectSetAuthorTest")

    guide_text = read_text(guide)
    if "SecurityEffectSetAuthorTemplate.tscn" not in guide_text:
        warnings.append("guide does not list SecurityEffectSetAuthorTemplate.tscn")

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static check only; GdUnit and Godot scene smoke remain the runtime gates.",
            "Does not inspect editor-assigned UIDs because templates intentionally use paths.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase4b_4d_security_effect_set_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )

    if errors:
        print("FAIL")
        for error in errors:
            print(f"  ERROR: {error}")
        for warning in warnings:
            print(f"  WARN: {warning}")
        return 1
    print("PASS")
    for warning in warnings:
        print(f"  WARN: {warning}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
