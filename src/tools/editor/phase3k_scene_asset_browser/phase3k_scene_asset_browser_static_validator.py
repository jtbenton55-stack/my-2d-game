"""Static validator for Phase 3K Scene/Asset Browser.

This validator intentionally checks the Phase 3K browser as a read-only
planning/search/select surface. It should not become proof of runtime behavior.
"""

from __future__ import annotations

import json
from pathlib import Path


def find_repo_root() -> Path:
    path = Path(__file__).resolve()
    for parent in [path.parent, *path.parents]:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find repo root containing project.godot")


ROOT = find_repo_root()
REPORT_PATH = ROOT / "docs" / "reports" / "phase3k_scene_asset_browser" / "phase3k_scene_asset_browser_static_validator_run.json"


def rel(path: str) -> Path:
    return ROOT / path


def read_text(path: str) -> str:
    file_path = rel(path)
    return file_path.read_text(encoding="utf-8") if file_path.exists() else ""


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    required_files = [
        "addons/scene_asset_browser/plugin.cfg",
        "addons/scene_asset_browser/SceneAssetBrowserPlugin.gd",
        "addons/scene_asset_browser/SceneAssetBrowserDock.gd",
        "docs/reports/phase3k_scene_asset_browser/phase3k_scene_asset_browser_plan.md",
        "docs/reports/pvgames_editable_object_asset_index.json",
        "docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json",
        "docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json",
        "docs/SECURITY_AUTHORABLES_GUIDE.md",
        "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md",
        "resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres",
    ]
    for path in required_files:
        require(rel(path).exists(), f"Missing required file: {path}", failures)

    plugin_cfg = read_text("addons/scene_asset_browser/plugin.cfg")
    plugin_text = read_text("addons/scene_asset_browser/SceneAssetBrowserPlugin.gd")
    dock_text = read_text("addons/scene_asset_browser/SceneAssetBrowserDock.gd")
    plan_text = read_text("docs/reports/phase3k_scene_asset_browser/phase3k_scene_asset_browser_plan.md")

    require('name="Scene/Asset Browser"' in plugin_cfg, "plugin.cfg name is incorrect", failures)
    require('script="SceneAssetBrowserPlugin.gd"' in plugin_cfg, "plugin.cfg script is incorrect", failures)
    require("extends EditorPlugin" in plugin_text, "plugin does not extend EditorPlugin", failures)
    require("add_control_to_dock" in plugin_text, "plugin does not add a dock", failures)
    require("remove_control_from_docks" in plugin_text, "plugin does not remove the dock", failures)
    require("extends VBoxContainer" in dock_text, "dock does not extend VBoxContainer", failures)
    require("@tool" in dock_text, "dock is not marked @tool", failures)
    require("Read-only Phase 3K browser" in dock_text, "dock help text does not state read-only scope", failures)
    require("Copy res:// Path" in dock_text, "copy path action missing", failures)
    require("Select In FileSystem" in dock_text, "select action missing", failures)
    require("Open Scene / Resource" in dock_text, "open action missing", failures)
    require("DEFERRED_NOTES" in dock_text, "deferred notes are not represented", failures)
    require("LEGACY_PREVIEW" in dock_text, "legacy preview handling missing", failures)
    require("parmida_manual_preview_spriteframes.tres" in dock_text, "legacy preview path missing", failures)
    require("source_png_path" in dock_text, "dock does not prefer PVGames source_png_path over bare filename", failures)
    require("object_id" in dock_text, "dock does not prefer PVGames object_id labels", failures)
    require("icon_id" in dock_text, "dock does not prefer PVGames icon_id labels", failures)
    require("_path_can_be_selected" in dock_text, "dock lacks safe path selection/open guard", failures)
    require("not path.begins_with(\"res://\")" in dock_text, "dock does not reject non-res paths before select/open", failures)

    for category in [
        "pvgames_object",
        "icon",
        "authoring_template",
        "security_template",
        "animation_map",
        "spriteframes_preview",
        "dev_scene",
        "validation_report",
    ]:
        require(category in dock_text, f"Category missing from dock: {category}", failures)

    for phrase in [
        "Do not let the larger browser become the first place",
        "Forbidden buttons in Phase 3K",
        "Sequence templates",
        "Mission Authoring Palette plugin",
        "Mission Assist Browser plugin",
        "Completion Criteria",
    ]:
        require(phrase in plan_text, f"Plan missing phrase: {phrase}", failures)

    forbidden_dock_terms = [
        "FileAccess.WRITE",
        "ResourceSaver",
        "EditorUndoRedoManager",
        "create_action",
        "commit_action",
        "OS.shell_open",
        "ProjectSettings.globalize_path",
        "set_owner",
        "PackedScene.new",
        "CollisionShape2D.new",
        "StaticBody2D.new",
        "Area2D.new",
    ]
    for term in forbidden_dock_terms:
        require(term not in dock_text, f"Dock contains forbidden write/placement term: {term}", failures)

    if "project.godot" in plugin_text + dock_text:
        failures.append("Plugin/dock unexpectedly references project.godot")

    if "scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn" in plugin_text + dock_text:
        failures.append("Plugin/dock unexpectedly references the Phase 3I sandbox dirty file")

    sequence_dir = rel("resources/mission_sequences")
    if sequence_dir.exists() and any(sequence_dir.rglob("*")):
        warnings.append("resources/mission_sequences now has content; revisit Phase 3K sequence-template deferral")

    result = {
        "phase": "3K",
        "validator": "phase3k_scene_asset_browser_static_validator.py",
        "pass_fail_partial": "PASS" if not failures else "FAIL",
        "failures": failures,
        "warnings": warnings,
        "checked_files": required_files,
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
