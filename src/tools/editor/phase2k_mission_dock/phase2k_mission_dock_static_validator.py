"""Static validator for Phase 2K combined Mission Dock."""

from __future__ import annotations

import json
import re
from pathlib import Path


def find_repo_root() -> Path:
    path = Path(__file__).resolve()
    for parent in [path.parent, *path.parents]:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find repo root containing project.godot")


ROOT = find_repo_root()
REPORT_PATH = ROOT / "docs" / "reports" / "phase2k_mission_dock" / "phase2k_mission_dock_static_validator_run.json"


def rel(path: str) -> Path:
    return ROOT / path


def read_text(path: str) -> str:
    file_path = rel(path)
    return file_path.read_text(encoding="utf-8") if file_path.exists() else ""


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def forbidden_runtime_edit_hits(text: str) -> list[str]:
    patterns = [
        r"extends\s+IsoMissionBase",
        r"SaveManager",
        r"MissionManager",
        r"ResourceSaver\.save",
        r"FileAccess\.WRITE",
        r"OS\.shell_open",
        r"ProjectSettings\.set_setting",
        r"StaticBody2D\.new",
    ]
    hits: list[str] = []
    for pattern in patterns:
        if re.search(pattern, text):
            hits.append(pattern)
    return hits


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    required_files = [
        "addons/mission_dock/plugin.cfg",
        "addons/mission_dock/MissionDockPlugin.gd",
        "addons/mission_dock/MissionDock.gd",
        "docs/reports/phase2k_mission_dock/phase2k_mission_dock_plan.md",
        "docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md",
        "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md",
        "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md",
    ]
    for path in required_files:
        require(rel(path).exists(), f"Missing required file: {path}", failures)

    plugin_cfg = read_text("addons/mission_dock/plugin.cfg")
    plugin_text = read_text("addons/mission_dock/MissionDockPlugin.gd")
    dock_text = read_text("addons/mission_dock/MissionDock.gd")
    plan_text = read_text("docs/reports/phase2k_mission_dock/phase2k_mission_dock_plan.md")
    blueprint_text = read_text("docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md")
    roadmap_text = read_text("docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md")

    require('name="Mission Dock"' in plugin_cfg, "plugin.cfg name must be Mission Dock", failures)
    require('script="MissionDockPlugin.gd"' in plugin_cfg, "plugin.cfg script must point to MissionDockPlugin.gd", failures)
    require("extends EditorPlugin" in plugin_text, "plugin must extend EditorPlugin", failures)
    require("add_control_to_dock" in plugin_text, "plugin must add dock", failures)
    require("remove_control_from_docks" in plugin_text, "plugin must remove dock", failures)
    require("set_input_event_forwarding_always_enabled" in plugin_text, "plugin must enable canvas forwarding", failures)
    require("@tool" in dock_text, "dock must be @tool", failures)
    require("extends VBoxContainer" in dock_text, "dock must extend VBoxContainer", failures)
    require("Mission Authoring Palette" in dock_text, "dock missing Mission Authoring Palette section", failures)
    require("Mission Assist Browser" in dock_text, "dock missing Mission Assist Browser section", failures)
    require("Dry Run Placement" in dock_text, "dock missing Dry Run Placement", failures)
    require("Place At Typed Position" in dock_text, "dock missing Place At Typed Position", failures)
    require("Place With Mouse" in dock_text, "dock missing Place With Mouse", failures)
    require("Disarm" in dock_text, "dock missing Disarm", failures)
    require("Last Placement Summary" in dock_text, "dock missing Last Placement Summary panel", failures)
    require("Array[MissionRequirement]" in dock_text, "dock must build typed RequirementSet arrays", failures)
    require("Refresh Scene Audit" in dock_text, "dock missing Refresh Scene Audit", failures)
    require("Select Node" in dock_text, "dock missing Select Node", failures)
    require("Copy Node Path" in dock_text, "dock missing Copy Node Path", failures)
    require("Copy Issue Summary" in dock_text, "dock missing Copy Issue Summary", failures)
    require("Copy Full Audit Summary" in dock_text, "dock missing Copy Full Audit Summary", failures)
    require("get_undo_redo" in dock_text, "dock must use EditorUndoRedoManager for placement", failures)
    require("create_action" in dock_text and "commit_action" in dock_text, "dock must commit UndoRedo actions", failures)
    require("_refresh_scene_audit" in dock_text, "dock missing audit refresh helper", failures)
    require("_preview_placement" in dock_text, "dock missing non-mutating preview helper", failures)
    require("ResourceSaver" not in dock_text, "dock must not save resources in v1", failures)

    for mechanic in [
        "SearchZone.gd",
        "RewardNode.gd",
        "LockedInteractionNode.gd",
        "RouteUnlockNode.gd",
        "InteractiveContainer.gd",
        "ExtractionZone.gd",
        "SideObjectiveNode.gd",
        "TriggerZone.gd",
        "SchemeCardTriggerNode.gd",
        "HideSpotNode.gd",
        "PresentationSequencePlayer.gd",
        "PlayerStartMarker.gd",
        "TeleportZone.gd",
        "TeleportTargetMarker.gd",
        "MusicTriggerZone.gd",
        "SecurityBeamAuthor.gd",
        "SecurityCameraAuthor.gd",
        "GuardSpawnAuthor.gd",
        "GuardPatrolRouteAuthor.gd",
        "AreaTriggerAuthor.gd",
        "SecurityEffectSetAuthor.gd",
        "PoopBagAuthor.gd",
        "CaseCashAuthor.gd",
        "ClueAuthor.gd",
        "GlowGuyAuthor.gd",
    ]:
        require(mechanic in dock_text, f"dock missing mechanic script reference: {mechanic}", failures)

    for token in [
        "SECURITY_AUTHORING_ROOT_PATH",
        "Ensure SecurityAuthoringRoot Parent",
        "Mission registration",
        "playable_iso_scene",
        "Sticky placement remains armed",
        "_suggest_next_id",
        "_apply_authoring_preset",
        "search_done",
        "reward_done",
        "route_open",
        "PLAYER_START_PARENT_PATH",
        "_identity_property_for_node",
    ]:
        require(token in dock_text, f"dock missing Milestone A support token: {token}", failures)

    template_paths = [
        "scenes/missions/iso/authoring/SearchZoneTemplate.tscn",
        "scenes/missions/iso/authoring/RewardNodeTemplate.tscn",
        "scenes/missions/iso/authoring/ExtractionZoneTemplate.tscn",
        "scenes/missions/iso/authoring/TriggerZoneTemplate.tscn",
        "scenes/missions/iso/authoring/SideObjectiveNodeTemplate.tscn",
        "scenes/missions/iso/authoring/InteractiveContainerTemplate.tscn",
        "scenes/missions/iso/authoring/PlayerStartMarkerTemplate.tscn",
        "scenes/missions/iso/authoring/TeleportZoneTemplate.tscn",
        "scenes/missions/iso/authoring/TeleportTargetMarkerTemplate.tscn",
        "scenes/missions/iso/authoring/MusicTriggerZoneTemplate.tscn",
    ]
    for path in template_paths:
        require(rel(path).exists(), f"Missing Milestone A template: {path}", failures)

    for phrase in ["Combined Mission Dock", "Mission Authoring Palette", "Mission Assist Browser", "Completion criteria"]:
        require(phrase in plan_text, f"plan missing phrase: {phrase}", failures)

    require("Phase 2K" in blueprint_text and "Mission Dock" in blueprint_text, "blueprint must mention Phase 2K Mission Dock", failures)
    require("Phase 2K" in roadmap_text and "Mission Dock" in roadmap_text, "roadmap must mention Phase 2K Mission Dock", failures)

    for pattern in forbidden_runtime_edit_hits(dock_text + plugin_text):
        failures.append(f"Forbidden runtime/edit pattern found in Mission Dock code: {pattern}")

    # Help/safety text may mention Phase0J/Phase0K; do not fail on those words alone.
    if re.search(r"extends\s+Phase0J", dock_text + plugin_text):
        failures.append("Mission Dock appears to extend Phase0J runtime code")

    report = {
        "pass_fail_partial": "PASS" if not failures else "FAIL",
        "failures": failures,
        "warnings": warnings,
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
