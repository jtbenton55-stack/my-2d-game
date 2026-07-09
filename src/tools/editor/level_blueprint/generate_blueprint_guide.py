"""Generate a Markdown build guide from a level blueprint spec.

Usage:
    python src/tools/editor/level_blueprint/generate_blueprint_guide.py docs/blueprints/starter_room.blueprint.json
    python src/tools/editor/level_blueprint/generate_blueprint_guide.py --all

Output is written next to the spec as <name>.build_guide.md and is fully
deterministic: the same spec always produces the same guide.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def find_repo_root() -> Path:
    path = Path(__file__).resolve()
    for parent in [path.parent, *path.parents]:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find repo root containing project.godot")


ROOT = find_repo_root()
BLUEPRINT_DIR = ROOT / "docs" / "blueprints"

PAINT_LAYER_BY_KIND = {
    "floor": "GameplayRoot/LayoutRoot/FloorLayer",
    "wall": "GameplayRoot/LayoutRoot/WallLayer",
    "cover": "GameplayRoot/LayoutRoot/CoverLayer",
    "collision_barrier": "GameplayRoot/LayoutRoot/CollisionBarrierLayer",
    "marker": "GameplayRoot/LayoutRoot/MarkerTileLayer",
}

SECURITY_PARENT_TYPES = {
    "SecurityBeamAuthor", "SecurityCameraAuthor", "GuardSpawnAuthor",
    "GuardPatrolRouteAuthor", "AreaTriggerAuthor", "SecurityEffectSetAuthor",
    "PoopBagAuthor", "CaseCashAuthor", "ClueAuthor", "GlowGuyAuthor",
}


def parent_path_for_type(mechanic_type: str) -> str:
    if mechanic_type in SECURITY_PARENT_TYPES:
        return "GameplayRoot/SecurityAuthoringRoot"
    if mechanic_type == "PlayerStartMarker":
        return "GameplayRoot/MarkerRoot/Spawns"
    return "MissionMechanics"


def topological_slot_order(slots: list[dict]) -> list[dict]:
    """Order slots so dependencies come before dependents; stable otherwise."""
    by_id = {str(slot.get("slot_id", "")): slot for slot in slots}
    visited: dict[str, bool] = {}
    ordered: list[dict] = []

    def visit(slot_id: str) -> None:
        if visited.get(slot_id):
            return
        visited[slot_id] = True
        slot = by_id.get(slot_id)
        if slot is None:
            return
        for dependency in slot.get("depends_on", []):
            visit(str(dependency))
        ordered.append(slot)

    for slot in slots:
        visit(str(slot.get("slot_id", "")))
    return ordered


def format_position(slot: dict) -> str:
    position = slot.get("position", [0, 0])
    return f"({position[0]}, {position[1]})"


def generate_guide(spec_path: Path) -> Path:
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    blueprint_id = str(spec.get("blueprint_id", ""))
    mission_id = str(spec.get("mission_id", ""))
    canvas = spec.get("canvas", {})
    regions = spec.get("regions", [])
    slots = spec.get("mechanic_slots", [])
    ordered_slots = topological_slot_order(slots)

    lines: list[str] = []
    lines.append(f"# Build Guide: {blueprint_id}")
    lines.append("")
    try:
        spec_rel = spec_path.relative_to(ROOT).as_posix()
    except ValueError:
        spec_rel = spec_path.name
    lines.append(f"Generated from `{spec_path.name}`. Do not edit by hand; re-run "
                 f"`python src/tools/editor/level_blueprint/generate_blueprint_guide.py {spec_rel}` after changing the spec.")
    lines.append("")
    lines.append(f"- Mission ID: `{mission_id}`")
    lines.append(f"- Canvas: {canvas.get('width', '?')} x {canvas.get('height', '?')} px")
    lines.append(f"- Grid size: {spec.get('grid_size', '?')} px")
    description = str(spec.get("description", "")).strip()
    if description:
        lines.append(f"- Description: {description}")
    lines.append("")
    lines.append("## Setup")
    lines.append("")
    lines.append("1. Open your mission scene (start from `scenes/templates/IsoMissionTemplate.tscn` for a new mission).")
    lines.append("2. Add a `Node2D` named `AuthoringBlueprintLayer` with the script `res://src/tools/authoring/AuthoringBlueprintLayer.gd` (a good parent is `GameplayRoot/LayoutRoot`). Keep the node at position (0, 0).")
    lines.append(f"3. Set its `blueprint_path` to `res://docs/blueprints/{spec_path.name}`. The blueprint appears in the editor viewport.")
    lines.append("4. Tune `opacity`, `draw_on_top`, and the `show_*` toggles while you work. The layer frees itself at runtime and is never visible to players.")
    lines.append("")
    lines.append("## Trace Layout (Mission Paint Dock)")
    lines.append("")
    lines.append("Paint each region onto its LayoutRoot tile layer:")
    lines.append("")
    lines.append("| Region | Kind | Paint layer |")
    lines.append("| --- | --- | --- |")
    for region in regions:
        kind = str(region.get("kind", ""))
        label = str(region.get("label", ""))
        lines.append(f"| {label} | {kind} | `{PAINT_LAYER_BY_KIND.get(kind, '?')}` |")
    lines.append("")
    lines.append("## Place Mechanics (Mission Dock)")
    lines.append("")
    lines.append("Slots are listed in dependency order; place them top to bottom. "
                 "Use the Mission Dock palette's \"Place From Blueprint\" section to prefill each slot, "
                 "then place at the typed position or with the mouse.")
    lines.append("")
    for index, slot in enumerate(ordered_slots, start=1):
        slot_id = str(slot.get("slot_id", ""))
        mechanic_type = str(slot.get("mechanic_type", ""))
        lines.append(f"### {index}. `{slot_id}` - {mechanic_type}")
        lines.append("")
        lines.append(f"- Suggested ID: `{slot.get('suggested_id', '')}`")
        lines.append(f"- Position: {format_position(slot)}")
        size = slot.get("size")
        if size:
            lines.append(f"- Zone size: {size[0]} x {size[1]}")
        lines.append(f"- Parent: `{parent_path_for_type(mechanic_type)}`")
        depends = slot.get("depends_on", [])
        if depends:
            depends_text = ", ".join(f"`{dep}`" for dep in depends)
            lines.append(f"- Depends on: {depends_text}")
        note = str(slot.get("note", "")).strip()
        if note:
            lines.append(f"- Instructions: {note}")
        lines.append("")
    lines.append("## Completion Checklist")
    lines.append("")
    for slot in ordered_slots:
        lines.append(f"- [ ] `{slot.get('slot_id', '')}` ({slot.get('mechanic_type', '')}) placed with id `{slot.get('suggested_id', '')}`")
    lines.append("")
    lines.append("When everything is placed, run Mission Dock's Assist Browser \"Refresh Scene Audit\" - "
                 "the blueprint coverage entry should report all slots placed. "
                 "Then hide or delete the `AuthoringBlueprintLayer` node.")
    lines.append("")

    guide_path = spec_path.with_name(spec_path.name.replace(".blueprint.json", ".build_guide.md"))
    guide_path.write_text("\n".join(lines), encoding="utf-8")
    return guide_path


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Markdown build guides from blueprint specs.")
    parser.add_argument("spec", nargs="?", help="Path to a .blueprint.json file")
    parser.add_argument("--all", action="store_true", help="Generate guides for every spec in docs/blueprints/")
    args = parser.parse_args()

    specs: list[Path] = []
    if args.all:
        specs = sorted(BLUEPRINT_DIR.glob("*.blueprint.json"))
    elif args.spec:
        spec_path = Path(args.spec)
        if not spec_path.is_absolute():
            spec_path = ROOT / spec_path
        specs = [spec_path]
    else:
        parser.error("Provide a spec path or --all")

    for spec_path in specs:
        if not spec_path.exists():
            print(f"ERROR: spec not found: {spec_path}", file=sys.stderr)
            return 1
        guide_path = generate_guide(spec_path)
        print(f"Wrote {guide_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
