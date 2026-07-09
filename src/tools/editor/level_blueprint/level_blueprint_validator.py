"""Static validator for the dev-only level blueprint system.

Validates:
- Required system files exist (layer script, spec helper, guide generator, docs, tests).
- AuthoringBlueprintLayer stays dev-only (runtime self-free, draw-only, no scene writes).
- LevelBlueprintSpec CATEGORY_BY_TYPE stays in parity with Mission Dock MECHANIC_TYPES.
- Mission Dock carries the blueprint integration tokens.
- Every docs/blueprints/*.blueprint.json spec is well-formed (schema, unique ids,
  known mechanic types, resolvable depends_on) and has an up-to-date build guide file.

Writes a JSON run report to docs/reports/level_blueprint/level_blueprint_validator_run.json.
"""

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
REPORT_PATH = ROOT / "docs" / "reports" / "level_blueprint" / "level_blueprint_validator_run.json"

REGION_KINDS = {"floor", "wall", "cover", "collision_barrier", "marker"}


def read_text(path: str) -> str:
    file_path = ROOT / path
    return file_path.read_text(encoding="utf-8") if file_path.exists() else ""


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def parse_mechanic_types(dock_text: str) -> list[str]:
    match = re.search(r"const MECHANIC_TYPES: Array\[String\] = \[(.*?)\]", dock_text, re.DOTALL)
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))


def parse_category_types(spec_helper_text: str) -> list[str]:
    match = re.search(r"const CATEGORY_BY_TYPE: Dictionary = \{(.*?)\n\}", spec_helper_text, re.DOTALL)
    if not match:
        return []
    return re.findall(r'"([^"]+)":\s*"[^"]+"', match.group(1))


def validate_spec(spec_path: Path, known_types: list[str], failures: list[str]) -> None:
    label = spec_path.name
    try:
        spec = json.loads(spec_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        failures.append(f"{label}: invalid JSON ({error})")
        return
    if not isinstance(spec, dict):
        failures.append(f"{label}: spec must be a JSON object")
        return
    require(bool(str(spec.get("blueprint_id", "")).strip()), f"{label}: blueprint_id is required", failures)
    canvas = spec.get("canvas", {})
    require(
        isinstance(canvas, dict) and float(canvas.get("width", 0)) > 0 and float(canvas.get("height", 0)) > 0,
        f"{label}: canvas.width/height must be positive",
        failures,
    )
    require(float(spec.get("grid_size", 0)) > 0, f"{label}: grid_size must be positive", failures)

    for index, region in enumerate(spec.get("regions", [])):
        if not isinstance(region, dict):
            failures.append(f"{label}: regions[{index}] must be an object")
            continue
        kind = str(region.get("kind", ""))
        require(kind in REGION_KINDS, f"{label}: regions[{index}] unknown kind '{kind}'", failures)
        shape = str(region.get("shape", ""))
        if shape == "rect":
            rect = region.get("rect", [])
            require(isinstance(rect, list) and len(rect) == 4, f"{label}: regions[{index}] rect needs [x, y, w, h]", failures)
        elif shape == "polyline":
            points = region.get("points", [])
            require(isinstance(points, list) and len(points) >= 2, f"{label}: regions[{index}] polyline needs 2+ points", failures)
        elif shape == "circle":
            center = region.get("center", [])
            require(
                isinstance(center, list) and len(center) == 2 and float(region.get("radius", 0)) > 0,
                f"{label}: regions[{index}] circle needs center and positive radius",
                failures,
            )
        else:
            failures.append(f"{label}: regions[{index}] unknown shape '{shape}'")

    slot_ids: set[str] = set()
    suggested_ids: set[str] = set()
    slots = spec.get("mechanic_slots", [])
    for index, slot in enumerate(slots):
        if not isinstance(slot, dict):
            failures.append(f"{label}: mechanic_slots[{index}] must be an object")
            continue
        slot_id = str(slot.get("slot_id", "")).strip()
        require(bool(slot_id), f"{label}: mechanic_slots[{index}] missing slot_id", failures)
        require(slot_id not in slot_ids, f"{label}: duplicate slot_id '{slot_id}'", failures)
        slot_ids.add(slot_id)
        mechanic_type = str(slot.get("mechanic_type", ""))
        require(
            mechanic_type in known_types,
            f"{label}: slot '{slot_id}' unknown mechanic_type '{mechanic_type}'",
            failures,
        )
        position = slot.get("position", [])
        require(isinstance(position, list) and len(position) == 2, f"{label}: slot '{slot_id}' needs position [x, y]", failures)
        suggested_id = str(slot.get("suggested_id", "")).strip()
        require(bool(suggested_id), f"{label}: slot '{slot_id}' missing suggested_id", failures)
        require(suggested_id not in suggested_ids, f"{label}: duplicate suggested_id '{suggested_id}'", failures)
        suggested_ids.add(suggested_id)
    for slot in slots:
        if not isinstance(slot, dict):
            continue
        for dependency in slot.get("depends_on", []):
            require(
                str(dependency) in slot_ids,
                f"{label}: slot '{slot.get('slot_id', '')}' depends_on unknown slot '{dependency}'",
                failures,
            )

    guide_path = spec_path.with_name(spec_path.name.replace(".blueprint.json", ".build_guide.md"))
    require(
        guide_path.exists(),
        f"{label}: missing build guide {guide_path.name} (run generate_blueprint_guide.py)",
        failures,
    )
    if guide_path.exists():
        guide_text = guide_path.read_text(encoding="utf-8")
        for slot in slots:
            if isinstance(slot, dict) and str(slot.get("slot_id", "")):
                require(
                    f"`{slot.get('slot_id')}`" in guide_text,
                    f"{label}: build guide is stale, missing slot '{slot.get('slot_id')}' (re-run generate_blueprint_guide.py)",
                    failures,
                )


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    required_files = [
        "src/tools/authoring/AuthoringBlueprintLayer.gd",
        "src/tools/authoring/LevelBlueprintSpec.gd",
        "src/tools/editor/level_blueprint/generate_blueprint_guide.py",
        "docs/How to Use/Level Blueprints.md",
        "tests/mission_authoring/LevelBlueprintLayerTest.gd",
        "docs/blueprints/starter_room.blueprint.json",
        "docs/blueprints/laundromat_heist.blueprint.json",
    ]
    for path in required_files:
        require((ROOT / path).exists(), f"Missing required file: {path}", failures)

    layer_text = read_text("src/tools/authoring/AuthoringBlueprintLayer.gd")
    spec_helper_text = read_text("src/tools/authoring/LevelBlueprintSpec.gd")
    dock_text = read_text("addons/mission_dock/MissionDock.gd")
    hider_text = read_text("src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd")

    # Dev-only guarantees on the layer.
    require("@tool" in layer_text, "AuthoringBlueprintLayer must be @tool", failures)
    require("Engine.is_editor_hint()" in layer_text, "AuthoringBlueprintLayer must check Engine.is_editor_hint()", failures)
    require("queue_free()" in layer_text, "AuthoringBlueprintLayer must free itself at runtime", failures)
    for forbidden in ["ResourceSaver", "FileAccess.WRITE", "add_child", "set_owner", "ProjectSettings.set_setting"]:
        require(forbidden not in layer_text, f"AuthoringBlueprintLayer must stay draw-only; found '{forbidden}'", failures)

    # Redundant runtime guard.
    require("hide_authoring_blueprint_layers" in hider_text, "Phase0JRuntimeAuthoringHider missing blueprint layer guard", failures)
    require("AuthoringBlueprintLayer" in hider_text, "Phase0JRuntimeAuthoringHider must strip AuthoringBlueprintLayer nodes", failures)

    # Mission Dock integration tokens.
    for token in [
        "Place From Blueprint",
        "Refresh Blueprint Slots",
        "Prefill From Selected Slot",
        "_audit_blueprint_coverage",
        "blueprint_slot_missing",
        "blueprint_coverage",
        "BLUEPRINT_LAYER_SCRIPT_PATH",
    ]:
        require(token in dock_text, f"Mission Dock missing blueprint token: {token}", failures)

    # Type parity: every Mission Dock mechanic type must have a category and vice versa.
    mechanic_types = parse_mechanic_types(dock_text)
    category_types = parse_category_types(spec_helper_text)
    require(bool(mechanic_types), "Could not parse MECHANIC_TYPES from MissionDock.gd", failures)
    require(bool(category_types), "Could not parse CATEGORY_BY_TYPE from LevelBlueprintSpec.gd", failures)
    for mechanic_type in mechanic_types:
        require(
            mechanic_type in category_types,
            f"LevelBlueprintSpec.CATEGORY_BY_TYPE missing Mission Dock type: {mechanic_type}",
            failures,
        )
    for category_type in category_types:
        require(
            category_type in mechanic_types,
            f"LevelBlueprintSpec.CATEGORY_BY_TYPE has unknown type not in Mission Dock: {category_type}",
            failures,
        )

    # Validate every blueprint spec on disk.
    blueprint_dir = ROOT / "docs" / "blueprints"
    spec_paths = sorted(blueprint_dir.glob("*.blueprint.json")) if blueprint_dir.exists() else []
    if not spec_paths:
        warnings.append("No blueprint specs found under docs/blueprints/")
    for spec_path in spec_paths:
        validate_spec(spec_path, mechanic_types, failures)

    report = {
        "pass_fail_partial": "PASS" if not failures else "FAIL",
        "specs_checked": [path.name for path in spec_paths],
        "mechanic_type_count": len(mechanic_types),
        "failures": failures,
        "warnings": warnings,
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
