#!/usr/bin/env python3
"""Phase 5 inventory/heist-kit validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase5_inventory_heist_kit"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def require_contains(errors: list[str], text: str, needle: str, label: str) -> None:
    if needle not in text:
        errors.append(f"{label} missing `{needle}`")


def require_not_contains(errors: list[str], text: str, needle: str, label: str) -> None:
    if needle in text:
        errors.append(f"{label} should not contain `{needle}`")


def main() -> int:
    root = repo_root()
    errors: list[str] = []
    warnings: list[str] = []

    item_data = root / "src/inventory/items/ItemData.gd"
    inventory_entry = root / "src/inventory/items/InventoryEntry.gd"
    mission_inventory = root / "src/inventory/MissionInventory.gd"
    fact_bridge = root / "src/missions/iso/authoring/core/MissionFactBridge.gd"
    effect = root / "src/missions/iso/authoring/core/MissionEffect.gd"
    applier = root / "src/missions/iso/authoring/core/MissionEffectApplier.gd"
    game_state = root / "src/autoload/GameState.gd"
    mission_dock = root / "addons/mission_dock/MissionDock.gd"
    inventory_tests = root / "tests/mission_authoring/MissionInventoryTest.gd"
    pickup_node = root / "src/missions/iso/authoring/mechanics/InventoryPickupNode.gd"
    pickup_template = root / "scenes/missions/iso/authoring/InventoryPickupNodeTemplate.tscn"
    pickup_tests = root / "tests/mission_authoring/InventoryPickupNodeTest.gd"
    debug_panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    dev_scene = root / "scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    report_5a_5c = root / "reports/ai/2026-06-20_phase5a_5c_lite_inventory_heist_kit_report.md"
    report_5d_5f = root / "reports/ai/2026-06-20_phase5d_5f_lite_inventory_pickup_debug_report.md"

    for path in (
        item_data,
        inventory_entry,
        mission_inventory,
        fact_bridge,
        effect,
        applier,
        game_state,
        mission_dock,
        inventory_tests,
        pickup_node,
        pickup_template,
        pickup_tests,
        debug_panel,
        dev_scene,
        roadmap,
        blueprint,
        report_5a_5c,
        report_5d_5f,
    ):
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    item_text = read_text(item_data)
    for needle in ("class_name ItemData", "CATEGORY_CREDENTIAL", "mission_only", "get_stack_limit"):
        require_contains(errors, item_text, needle, "ItemData")

    entry_text = read_text(inventory_entry)
    for needle in ("class_name InventoryEntry", "configure_from_item", "to_summary"):
        require_contains(errors, entry_text, needle, "InventoryEntry")

    inventory_text = read_text(mission_inventory)
    for needle in ("class_name MissionInventory", "static var _entries", "add_item", "remove_item", "clear_mission_items", "get_snapshot"):
        require_contains(errors, inventory_text, needle, "MissionInventory")

    fact_text = read_text(fact_bridge)
    for needle in ("FACT_INVENTORY_HAS_ITEM", "FACT_INVENTORY_ITEM_COUNT", "FACT_INVENTORY_HAS_CATEGORY", "MissionInventoryScript.has_item"):
        require_contains(errors, fact_text, needle, "MissionFactBridge")

    effect_text = read_text(effect)
    for needle in ("GRANT_ITEM", "REMOVE_ITEM", "CLEAR_MISSION_ITEMS"):
        require_contains(errors, effect_text, needle, "MissionEffect")

    applier_text = read_text(applier)
    for needle in ("_apply_grant_item", "_apply_remove_item", "MissionInventoryScript.clear_mission_items"):
        require_contains(errors, applier_text, needle, "MissionEffectApplier")

    game_state_text = read_text(game_state)
    require_contains(errors, game_state_text, "MissionInventoryScript.clear_mission_items()", "GameState")
    require_not_contains(errors, game_state_text, '"mission_inventory"', "GameState save data")
    require_not_contains(errors, game_state_text, '"mission_items"', "GameState save data")

    dock_text = read_text(mission_dock)
    require_contains(errors, dock_text, "inventory_has_item", "MissionDock")
    require_contains(errors, dock_text, "MissionEffect.EffectType.GRANT_ITEM", "MissionDock")

    test_text = read_text(inventory_tests)
    for needle in ("test_inventory_requirements_read_mission_inventory", "test_inventory_effects_grant_remove_and_clear_items", "does_not_persist"):
        require_contains(errors, test_text, needle, "MissionInventoryTest")

    pickup_text = read_text(pickup_node)
    for needle in ("class_name InventoryPickupNode", "extends RewardNode", "MissionEffectScript.EffectType.GRANT_ITEM", "MissionEffectApplierScript.apply_effect"):
        require_contains(errors, pickup_text, needle, "InventoryPickupNode")

    pickup_template_text = read_text(pickup_template)
    for needle in ("InventoryPickupNodeTemplate", "InventoryPickupNode.gd", "CHANGE_ME_ITEM_ID"):
        require_contains(errors, pickup_template_text, needle, "InventoryPickupNodeTemplate")

    pickup_test_text = read_text(pickup_tests)
    for needle in ("test_successful_pickup_grants_item_once", "test_pickup_item_requirement_unlocks_route", "test_f10_debug_line_shows_mission_inventory_snapshot"):
        require_contains(errors, pickup_test_text, needle, "InventoryPickupNodeTest")

    debug_text = read_text(debug_panel)
    for needle in ("MissionInventoryScript", "_format_mission_inventory_line", "mission_inv"):
        require_contains(errors, debug_text, needle, "IsoMissionDebugPanel")

    dev_scene_text = read_text(dev_scene)
    for needle in ("InventoryPickupNode_phase5d_delivery_badge", "RouteUnlockNode_phase5d_badge_route", "inventory_has_item"):
        require_contains(errors, dev_scene_text, needle, "MechanicAuthoringTestRoom")

    require_contains(errors, dock_text, "InventoryPickupNode", "MissionDock")
    require_contains(errors, dock_text, "missing_item_id", "MissionDock")

    if "Phase 5A-5C-lite" not in read_text(roadmap):
        warnings.append("roadmap Phase 5A-5C-lite status note not found yet")
    if "Phase 5A-5C-lite" not in read_text(blueprint):
        warnings.append("blueprint Phase 5A-5C-lite status note not found yet")
    if "Phase 5D-5F-lite" not in read_text(roadmap):
        warnings.append("roadmap Phase 5D-5F-lite status note not found yet")
    if "Phase 5D-5F-lite" not in read_text(blueprint):
        warnings.append("blueprint Phase 5D-5F-lite status note not found yet")

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot execute GDScript; focused and full GdUnit cover runtime contracts.",
            "Persistent item save schema and production mission item placement remain intentionally deferred.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase5_inventory_validator_run.json").write_text(
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
