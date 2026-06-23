#!/usr/bin/env python3
"""Phase 13A-13G social stealth identity validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase13_social_stealth"


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

    resources = [
        root / "src/missions/iso/social/SocialStealthAdapter.gd",
        root / "src/missions/iso/social/CoverStoryData.gd",
        root / "src/missions/iso/social/CredentialData.gd",
        root / "src/missions/iso/social/InspectionRuleSet.gd",
    ]
    mechanics = [
        root / "src/missions/iso/authoring/mechanics/InspectionZone.gd",
        root / "src/missions/iso/authoring/mechanics/BelievableTaskZone.gd",
        root / "src/missions/iso/authoring/mechanics/ProtocolZone.gd",
        root / "src/missions/iso/authoring/mechanics/ProfessionalismMeterNode.gd",
        root / "src/missions/iso/authoring/mechanics/CleanlinessGate.gd",
    ]
    templates = [
        root / "scenes/missions/iso/authoring/InspectionZoneTemplate.tscn",
        root / "scenes/missions/iso/authoring/BelievableTaskZoneTemplate.tscn",
        root / "scenes/missions/iso/authoring/ProtocolZoneTemplate.tscn",
        root / "scenes/missions/iso/authoring/ProfessionalismMeterNodeTemplate.tscn",
        root / "scenes/missions/iso/authoring/CleanlinessGateTemplate.tscn",
    ]
    core_files = [
        root / "src/missions/iso/authoring/core/MissionFactBridge.gd",
        root / "src/missions/iso/authoring/core/MissionEffect.gd",
        root / "src/missions/iso/authoring/core/MissionEffectApplier.gd",
        root / "src/autoload/GameState.gd",
        root / "src/ui/MissionResult.gd",
        root / "addons/mission_dock/MissionDock.gd",
    ]
    dev_scene = root / "scenes/dev/mission_authoring/Phase13SocialStealthProofRoom.tscn"
    tests = root / "tests/mission_authoring/Phase13SocialStealthTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    report = root / "reports/ai/2026-06-22_phase13_social_stealth_report.md"

    for path in [*resources, *mechanics, *templates, *core_files, dev_scene, tests, roadmap, blueprint, report]:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    adapter_text = read_text(resources[0])
    for needle in (
        "FACT_COVER_STORY_ACTIVE",
        "grant_credential",
        "complete_protocol",
        "complete_task",
        "adjust_professionalism",
        "adjust_cleanliness",
        "record_inspection",
        "annotate_mission_result",
    ):
        require_contains(errors, adapter_text, needle, "SocialStealthAdapter")

    for path, label, needles in (
        (resources[1], "CoverStoryData", ("class_name CoverStoryData", "professionalism_bonus", "activate")),
        (resources[2], "CredentialData", ("class_name CredentialData", "trust_value", "grant")),
        (resources[3], "InspectionRuleSet", ("class_name InspectionRuleSet", "accepted_cover_story_ids", "required_credential_ids", "min_professionalism", "min_cleanliness")),
        (mechanics[0], "InspectionZone", ("class_name InspectionZone", "rule_set", "record_inspection", "accepted_flag", "rejected_flag")),
        (mechanics[1], "BelievableTaskZone", ("class_name BelievableTaskZone", "complete_task", "professionalism_delta", "exposure_decay")),
        (mechanics[2], "ProtocolZone", ("class_name ProtocolZone", "complete_protocol", "required_cover_story_id", "required_credential_id")),
        (mechanics[3], "ProfessionalismMeterNode", ("class_name ProfessionalismMeterNode", "adjust_professionalism", "adjust_cleanliness", "get_summary")),
        (mechanics[4], "CleanlinessGate", ("class_name CleanlinessGate", "min_cleanliness", "required_protocol_id", "unlock")),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    fact_bridge_text = read_text(core_files[0])
    for needle in ("social_cover_story_active", "social_credential_active", "social_protocol_complete", "social_task_complete", "professionalism_score", "cleanliness_score", "SocialStealthAdapterScript"):
        require_contains(errors, fact_bridge_text, needle, "MissionFactBridge")

    effect_text = read_text(core_files[1]) + read_text(core_files[2])
    for needle in ("ACTIVATE_COVER_STORY", "GRANT_CREDENTIAL", "COMPLETE_PROTOCOL", "COMPLETE_BELIEVABLE_TASK", "ADJUST_PROFESSIONALISM", "SET_CLEANLINESS"):
        require_contains(errors, effect_text, needle, "MissionEffect/MissionEffectApplier")

    require_contains(errors, read_text(core_files[3]), "SocialStealthAdapterScript.annotate_mission_result", "GameState")
    require_contains(errors, read_text(core_files[4]), "Social Stealth", "MissionResult")

    dock_text = read_text(core_files[5])
    for needle in ("InspectionZone", "BelievableTaskZone", "ProtocolZone", "ProfessionalismMeterNode", "CleanlinessGate", "missing_inspection_rule_set", "missing_professionalism_meter_id"):
        require_contains(errors, dock_text, needle, "MissionDock")

    for template in templates:
        require_contains(errors, read_text(template), template.stem, template.stem)

    scene_text = read_text(dev_scene)
    for needle in ("Phase13SocialStealthProofRoom", "InspectionZone_phase13d_inspection", "BelievableTaskZone_phase13e_believable_task", "ProtocolZone_phase13f_protocol", "ProfessionalismMeterNode_phase13f_professionalism", "CleanlinessGate_phase13f_cleanliness_gate"):
        require_contains(errors, scene_text, needle, "Phase13SocialStealthProofRoom")

    test_text = read_text(tests)
    for needle in ("test_cover_story_credentials_and_social_fact_bridge", "test_social_effects_route_through_effect_applier", "test_inspection_rule_set_accepts_and_rejects_social_state", "test_social_mechanic_nodes_drive_believable_action_flow", "test_mission_result_receives_social_summary", "test_templates_and_dev_scene_contain_phase13_nodes"):
        require_contains(errors, test_text, needle, "Phase13SocialStealthTest")

    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (report, "AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 13A-13G", label)
        require_contains(errors, doc_text, "InspectionZone", label)
        require_contains(errors, doc_text, "BelievableTaskZone", label)
        require_contains(errors, doc_text, "CleanlinessGate", label)

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; GdUnit and headless scene smoke cover runtime contracts.",
            "Phase 13 intentionally uses mission-local adapter state and facts/effects instead of adding a global social manager.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase13_social_stealth_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

    if errors:
        print("FAIL")
        for error in errors:
            print(f"  ERROR: {error}")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
