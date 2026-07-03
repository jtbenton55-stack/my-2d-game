#!/usr/bin/env python3
"""Static validation for Phase 15 bounded reactive NPC/social consequence authoring."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
REPORT_DIR = ROOT / "docs" / "reports" / "phase15_reactive_npc"
REPORT_PATH = REPORT_DIR / "phase15_reactive_npc_validation.json"

REQUIRED_FILES = [
    "src/missions/iso/ai/SocialSignalEvent.gd",
    "src/missions/iso/ai/NpcAttentionBudget.gd",
    "src/missions/iso/ai/SocialReactionRuleSet.gd",
    "src/missions/iso/ai/ReactiveNpcBrainAdapter.gd",
    "src/missions/iso/ai/ReactiveNpcFallbackDriver.gd",
    "src/missions/iso/ai/ReactiveNpcResultAdapter.gd",
    "src/missions/iso/authoring/mechanics/InvestigationPointNode.gd",
    "src/missions/iso/authoring/mechanics/RoutineOverrideNode.gd",
    "src/missions/iso/dev/Phase15ReactiveNpcProofHarness.gd",
    "scenes/dev/mission_authoring/Phase15ReactiveNpcProofRoom.tscn",
    "scenes/missions/iso/authoring/InvestigationPointNodeTemplate.tscn",
    "scenes/missions/iso/authoring/RoutineOverrideNodeTemplate.tscn",
    "tests/mission_authoring/Phase15ReactiveNpcTest.gd",
]

REQUIRED_BUTTONS = [
    "Run Ignored Signal",
    "Run Investigation Reaction",
    "Run Authority Report",
    "Run Routine Override",
]

REQUIRED_FACTS = [
    "reactive_signal_recorded",
    "reactive_signal_type_count",
    "reactive_reaction_recorded",
    "reactive_authority_reported",
    "reactive_result_tag",
]

REQUIRED_EFFECTS = [
    "RECORD_SOCIAL_SIGNAL",
    "EVALUATE_REACTIVE_NPC_SIGNAL",
    "SET_REACTIVE_NPC_RESULT_TAG",
]

FORBIDDEN_AI_OVERREACH_TERMS = [
    "global npc manager",
    "gossip network",
    "faction reputation",
    "behavior tree",
    "combat ai",
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
        scene_text = read_text("scenes/dev/mission_authoring/Phase15ReactiveNpcProofRoom.tscn")
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
        for class_name in ["InvestigationPointNode", "RoutineOverrideNode"]:
            ok = class_name in dock_text
            checks.append({"check": "mission_dock", "class": class_name, "ok": ok})
            if not ok:
                failures.append(f"Mission Dock missing {class_name}")

        result_text = read_text("src/autoload/GameState.gd") + read_text("src/ui/MissionResult.gd")
        for token in ["ReactiveNpcResultAdapterScript", "reactive_npc_state", "Reactive NPC Consequences"]:
            ok = token in result_text
            checks.append({"check": "result_integration", "token": token, "ok": ok})
            if not ok:
                failures.append(f"Result integration missing token: {token}")

        runtime_text = "\n".join(
            read_text(path)
            for path in [
                "src/missions/iso/ai/ReactiveNpcBrainAdapter.gd",
                "src/missions/iso/ai/ReactiveNpcFallbackDriver.gd",
                "src/missions/iso/authoring/mechanics/InvestigationPointNode.gd",
                "src/missions/iso/authoring/mechanics/RoutineOverrideNode.gd",
            ]
        ).lower()
        for term in FORBIDDEN_AI_OVERREACH_TERMS:
            ok = term.lower() not in runtime_text
            checks.append({"check": "no_ai_overreach_term", "term": term, "ok": ok})
            if not ok:
                failures.append(f"Reactive NPC runtime includes forbidden overreach term: {term}")

        limbo_direct = "limboai" in runtime_text or "limbo_ai" in runtime_text
        checks.append({"check": "no_direct_limbo_dependency", "ok": not limbo_direct})
        if limbo_direct:
            failures.append("Reactive NPC runtime has a direct LimboAI dependency instead of adapter-gated context injection")

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps({"ok": not failures, "failures": failures, "checks": checks}, indent=2), encoding="utf-8")

    if failures:
        print("Phase 15 reactive NPC validation FAILED")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Phase 15 reactive NPC validation PASS ({len(checks)} checks)")
    print(f"Report: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
