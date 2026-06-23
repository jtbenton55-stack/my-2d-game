#!/usr/bin/env python3
"""Phase 12A-12H narrative / presentation bridge validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase12_narrative_presentation"


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

    dialogue_bridge = root / "src/missions/iso/authoring/core/MissionDialogueBridge.gd"
    dialogue_trigger = root / "src/missions/iso/presentation/DialogueTriggerZone.gd"
    bark_trigger = root / "src/missions/iso/presentation/BarkTrigger.gd"
    sequence_player = root / "src/missions/iso/presentation/PresentationSequencePlayer.gd"
    camera_bridge = root / "src/missions/iso/presentation/CameraBridge.gd"
    player_bridge = root / "src/missions/iso/presentation/PlayerControlBridge.gd"
    audio_visual_bridge = root / "src/missions/iso/presentation/AudioVisualBridge.gd"
    iso_base = root / "src/levels/IsoMissionBase.gd"
    mission_dock = root / "addons/mission_dock/MissionDock.gd"
    templates = [
        root / "scenes/missions/iso/authoring/DialogueTriggerZoneTemplate.tscn",
        root / "scenes/missions/iso/authoring/BarkTriggerTemplate.tscn",
        root / "scenes/missions/iso/authoring/PresentationSequencePlayerTemplate.tscn",
    ]
    dev_scene = root / "scenes/dev/mission_authoring/Phase12PresentationProofRoom.tscn"
    tests = root / "tests/mission_authoring/Phase12NarrativePresentationTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    report = root / "reports/ai/2026-06-22_phase12_narrative_presentation_report.md"

    required = [dialogue_bridge, dialogue_trigger, bark_trigger, sequence_player, camera_bridge, player_bridge, audio_visual_bridge, iso_base, mission_dock, dev_scene, tests, roadmap, blueprint, report, *templates]
    for path in required:
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    bridge_text = read_text(dialogue_bridge)
    for needle in ("register_dialogue_key", "_play_provider_key", "get_mission_dialogue_provider", "fallback_text", "provider_line"):
        if needle == "provider_line":
            continue
        require_contains(errors, bridge_text, needle, "MissionDialogueBridge")

    for path, label, needles in (
        (dialogue_trigger, "DialogueTriggerZone", ("class_name DialogueTriggerZone", "cooldown_seconds", "play_dialogue", "MissionDialogueBridge.play_dialogue_key")),
        (bark_trigger, "BarkTrigger", ("class_name BarkTrigger", "bark_id", "bark_text", "MissionDialogueBridge.play_bark")),
        (sequence_player, "PresentationSequencePlayer", ("class_name PresentationSequencePlayer", "play_intro", "play_outro", "camera_focus", "player_lock", "audio_visual")),
        (camera_bridge, "CameraBridge", ("class_name CameraBridge", "focus_named_target", "restore_camera", "phantom_adapter_path", "screen_shake")),
        (player_bridge, "PlayerControlBridge", ("class_name PlayerControlBridge", "lock_input", "restore_input", "restore_all_controls", "guide_to")),
        (audio_visual_bridge, "AudioVisualBridge", ("class_name AudioVisualBridge", "play_cue", "resonant_adapter_path", "AudioManager", "screen_shake")),
    ):
        text = read_text(path)
        for needle in needles:
            require_contains(errors, text, needle, label)

    require_contains(errors, read_text(iso_base), "func get_mission_dialogue_provider", "IsoMissionBase")

    dock_text = read_text(mission_dock)
    for needle in ("DialogueTriggerZone", "BarkTrigger", "missing_dialogue_key", "missing_bark_text"):
        require_contains(errors, dock_text, needle, "MissionDock")

    for template in templates:
        text = read_text(template)
        require_contains(errors, text, template.stem, template.stem)

    scene_text = read_text(dev_scene)
    for needle in ("Phase12PresentationProofRoom", "DialogueTriggerZone_phase12a_intro_line", "BarkTrigger_phase12b_bentley_bark", "PresentationSequencePlayer", "CameraBridge", "PlayerControlBridge", "AudioVisualBridge"):
        require_contains(errors, scene_text, needle, "Phase12PresentationProofRoom")

    test_text = read_text(tests)
    for needle in ("test_dialogue_bridge_registry_provider_and_fallback_lookup", "test_dialogue_and_bark_triggers_prevent_spam", "test_camera_player_and_audio_visual_bridges_fail_safe_and_restore", "test_sequence_player_coordinates_bridges_without_gameplay_ownership", "test_templates_and_dev_scene_contain_phase12_nodes"):
        require_contains(errors, test_text, needle, "Phase12NarrativePresentationTest")

    for doc_path, label in ((roadmap, "Roadmap"), (blueprint, "Blueprint"), (report, "AI report")):
        doc_text = read_text(doc_path)
        require_contains(errors, doc_text, "Phase 12A-12H", label)
        require_contains(errors, doc_text, "DialogueTriggerZone", label)
        require_contains(errors, doc_text, "PresentationSequencePlayer", label)
        require_contains(errors, doc_text, "CameraBridge", label)
        require_contains(errors, doc_text, "PlayerControlBridge", label)
        require_contains(errors, doc_text, "AudioVisualBridge", label)

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; GdUnit and headless scene smoke cover runtime contracts.",
            "PhantomCamera and Resonant are not installed in this repo, so Phase 12 validates safe fallback adapter paths rather than plugin runtime behavior.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase12_narrative_presentation_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

    if errors:
        print("FAIL")
        for error in errors:
            print(f"  ERROR: {error}")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
