#!/usr/bin/env python3
"""Static validation for Phase 14 encounter challenge authoring."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "phase14_encounter"
REPORT_PATH = REPORT_DIR / "phase14_encounter_validation.json"

REQUIRED_FILES = [
    "src/missions/iso/encounters/ChallengeMeterData.gd",
    "src/missions/iso/encounters/EncounterPhaseData.gd",
    "src/missions/iso/encounters/EncounterController.gd",
    "src/missions/iso/encounters/EncounterResultAdapter.gd",
    "src/missions/iso/authoring/mechanics/ChallengeObjectiveNode.gd",
    "src/missions/iso/authoring/mechanics/DisruptionActionNode.gd",
    "src/missions/iso/dev/Phase14EncounterProofHarness.gd",
    "scenes/dev/mission_authoring/Phase14EncounterProofRoom.tscn",
    "scenes/missions/iso/authoring/EncounterControllerTemplate.tscn",
    "scenes/missions/iso/authoring/ChallengeObjectiveNodeTemplate.tscn",
    "scenes/missions/iso/authoring/DisruptionActionNodeTemplate.tscn",
    "tests/mission_authoring/Phase14EncounterTest.gd",
]

REQUIRED_BUTTONS = [
    "Run Clean Social Route",
    "Run Bentley Route",
    "Run Evidence Route",
    "Run Messy Route",
]

REQUIRED_FACTS = [
    "encounter_phase",
    "encounter_meter",
    "encounter_result_tag",
]

REQUIRED_EFFECTS = [
    "RECORD_ENCOUNTER_EVENT",
    "SET_ENCOUNTER_PHASE",
    "ADJUST_ENCOUNTER_METER",
    "SET_ENCOUNTER_RESULT_TAG",
]

FORBIDDEN_COMBAT_TERMS = [
    "player_health",
    "enemy_health",
    "damage_amount",
    "apply_damage",
    "take_damage",
    "weapon_damage",
]


def read_text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def main() -> int:
    failures: list[str] = []
    checks: list[dict[str, object]] = []

    for rel in REQUIRED_FILES:
        exists = (ROOT / rel).exists()
        checks.append({"check": "required_file", "path": rel, "ok": exists})
        if not exists:
            failures.append(f"Missing required file: {rel}")

    if not failures:
        scene_text = read_text("scenes/dev/mission_authoring/Phase14EncounterProofRoom.tscn")
        for button in REQUIRED_BUTTONS:
            ok = button in scene_text
            checks.append({"check": "proof_button", "button": button, "ok": ok})
            if not ok:
                failures.append(f"Proof room missing button: {button}")

        fact_bridge = read_text("src/missions/iso/authoring/core/MissionFactBridge.gd")
        for fact in REQUIRED_FACTS:
            ok = fact in fact_bridge
            checks.append({"check": "fact_bridge", "fact": fact, "ok": ok})
            if not ok:
                failures.append(f"MissionFactBridge missing fact: {fact}")

        effect_text = read_text("src/missions/iso/authoring/core/MissionEffect.gd") + read_text("src/missions/iso/authoring/core/MissionEffectApplier.gd")
        for effect in REQUIRED_EFFECTS:
            ok = effect in effect_text
            checks.append({"check": "effect_bridge", "effect": effect, "ok": ok})
            if not ok:
                failures.append(f"MissionEffect bridge missing effect: {effect}")

        dock_text = read_text("addons/mission_dock/MissionDock.gd")
        for class_name in ["EncounterController", "ChallengeObjectiveNode", "DisruptionActionNode"]:
            ok = class_name in dock_text
            checks.append({"check": "mission_dock", "class": class_name, "ok": ok})
            if not ok:
                failures.append(f"Mission Dock missing {class_name}")

        result_text = read_text("src/autoload/GameState.gd") + read_text("src/ui/MissionResult.gd")
        for token in ["EncounterResultAdapterScript", "encounter_state", "Encounter Challenge"]:
            ok = token in result_text
            checks.append({"check": "result_integration", "token": token, "ok": ok})
            if not ok:
                failures.append(f"Result integration missing token: {token}")

        runtime_text = "\n".join(
            read_text(path)
            for path in [
                "src/missions/iso/encounters/EncounterController.gd",
                "src/missions/iso/authoring/mechanics/ChallengeObjectiveNode.gd",
                "src/missions/iso/authoring/mechanics/DisruptionActionNode.gd",
            ]
        ).lower()
        for term in FORBIDDEN_COMBAT_TERMS:
            ok = term.lower() not in runtime_text
            checks.append({"check": "no_default_combat_term", "term": term, "ok": ok})
            if not ok:
                failures.append(f"Encounter runtime includes forbidden combat/default-HP term: {term}")

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps({"ok": not failures, "failures": failures, "checks": checks}, indent=2),
        encoding="utf-8",
    )

    if failures:
        print("Phase 14 encounter validation FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Phase 14 encounter validation PASS ({len(checks)} checks)")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
