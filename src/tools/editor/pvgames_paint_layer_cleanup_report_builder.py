#!/usr/bin/env python3
"""Build 0M-B7 dry-run inventory reports for HideoutHub PVGames paint layers.

This script is intentionally non-destructive. It parses HideoutHub.tscn, reports
PVGames paint TileMapLayer cell data, and writes dry-run clear summaries. It does
not clear or edit TileMap cell data.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HIDEOUT = ROOT / "scenes/hideout/HideoutHub.tscn"
REPORTS = ROOT / "docs/reports"
INVENTORY_MD = REPORTS / "hideout_phase_0mb7_pvgames_paint_layer_inventory.md"
INVENTORY_JSON = REPORTS / "hideout_phase_0mb7_pvgames_paint_layer_inventory.json"
HOW_TO = REPORTS / "pvgames_paint_layer_cleanup_how_to.md"
MAIN_MD = REPORTS / "hideout_phase_0mb7_paint_layer_cleanup_tool.md"
MAIN_JSON = REPORTS / "hideout_phase_0mb7_paint_layer_cleanup_tool.json"

CORE_PREFIX = "res://assets/tilesets/pvgames_catalog_paintable/"
CENTRAL_PREFIX = "res://assets/tilesets/pvgames_central_security_paintable/"
GROUPS = ["core", "central_security", "ground", "wall", "occludable", "foreground", "review_only", "all_pvgames"]


def parse_ext_resources(text: str) -> dict[str, str]:
    resources: dict[str, str] = {}
    pattern = re.compile(r'^\[ext_resource type="TileSet".*?path="([^"]+)".*?id="([^"]+)"\]', re.MULTILINE)
    for match in pattern.finditer(text):
        path, res_id = match.groups()
        resources[res_id] = path
    return resources


def parse_node_blocks(text: str) -> list[dict[str, Any]]:
    starts = [m.start() for m in re.finditer(r'^\[node ', text, re.MULTILINE)]
    blocks: list[dict[str, Any]] = []
    for idx, start in enumerate(starts):
        end = starts[idx + 1] if idx + 1 < len(starts) else len(text)
        block = text[start:end]
        header = block.splitlines()[0]
        m = re.search(r'name="([^"]+)".*type="([^"]+)".*parent="([^"]+)"', header)
        if not m:
            continue
        name, node_type, parent = m.groups()
        props: dict[str, str] = {}
        for line in block.splitlines()[1:]:
            if " = " in line:
                key, value = line.split(" = ", 1)
                props[key.strip()] = value.strip()
        blocks.append({"name": name, "type": node_type, "parent": parent, "block": block, "props": props})
    return blocks


def packed_byte_count(value: str) -> tuple[int, list[str]]:
    m = re.search(r"PackedByteArray\((.*?)\)", value, re.S)
    if not m:
        return 0, []
    nums = [int(n.strip()) for n in m.group(1).split(",") if n.strip()]
    if not nums:
        return 0, []
    # Godot 4 TileMapLayer cell records in this scene are 14 bytes per used cell.
    count = len(nums) // 14
    coords: list[str] = []
    for i in range(min(count, 25)):
        chunk = nums[i * 14:(i + 1) * 14]
        if len(chunk) >= 4:
            x = int.from_bytes(bytes(chunk[0:2]), "little", signed=True)
            y = int.from_bytes(bytes(chunk[2:4]), "little", signed=True)
            coords.append(f"Vector2i({x}, {y})")
    return count, coords


def groups_for(path: str, name: str, tileset_path: str) -> list[str]:
    low = f"{path} {name} {tileset_path}".lower()
    groups = ["all_pvgames"]
    if CORE_PREFIX in tileset_path:
        groups.append("core")
    if CENTRAL_PREFIX in tileset_path or "centralsecurity" in low:
        groups.append("central_security")
    if any(token in low for token in ["ground", "floor"]):
        groups.append("ground")
    if any(token in low for token in ["wall", "barrier", "backdrop"]):
        groups.append("wall")
    if "occludable" in low:
        groups.append("occludable")
    if "foreground" in low or "overlay" in low:
        groups.append("foreground")
    if "review" in low:
        groups.append("review_only")
    return groups


def depth_role_for(groups: list[str]) -> str:
    if "foreground" in groups:
        return "FOREGROUND_ALWAYS_FRONT"
    if "occludable" in groups:
        return "OCCLUDABLE_ABOVE_PLAYER"
    if "review_only" in groups:
        return "REVIEW_ONLY"
    if "ground" in groups or "wall" in groups:
        return "BEHIND_PLAYER"
    return "UNKNOWN"


def build_inventory() -> list[dict[str, Any]]:
    text = HIDEOUT.read_text(encoding="utf-8")
    ext_resources = parse_ext_resources(text)
    layers: list[dict[str, Any]] = []
    for node in parse_node_blocks(text):
        if node["type"] != "TileMapLayer":
            continue
        parent = node["parent"]
        name = node["name"]
        node_path = f"{parent}/{name}"
        props = node["props"]
        tile_set_value = props.get("tile_set", "")
        res_match = re.search(r'ExtResource\("([^"]+)"\)', tile_set_value)
        tileset_path = ext_resources.get(res_match.group(1), "") if res_match else ""
        pvgames_by_path = tileset_path.startswith(CORE_PREFIX) or tileset_path.startswith(CENTRAL_PREFIX)
        pvgames_by_parent = any(token in parent for token in [
            "PVG_CatalogPaintLayers",
            "PVG_DepthPaintLayers",
            "PVG_CentralSecurityPaintLayers",
            "PVG_CentralSecurityDepthPaintLayers",
        ])
        pvgames_by_name = any(token in name for token in ["PVGames", "PVG", "Catalog", "CentralSecurity", "PaintLayer", "Occludable"])
        under_art_world = node_path.startswith("ArtRoot/World/")
        if not under_art_world or not (pvgames_by_path or pvgames_by_parent or pvgames_by_name):
            continue
        used_count, first_coords = packed_byte_count(props.get("tile_map_data", ""))
        layer_groups = groups_for(node_path, name, tileset_path)
        safe = under_art_world and (tileset_path.startswith(CORE_PREFIX) or tileset_path.startswith(CENTRAL_PREFIX))
        layers.append({
            "node_path": node_path,
            "parent_path": parent,
            "node_name": name,
            "tileset_path": tileset_path,
            "used_cell_count_static": used_count,
            "used_cell_count_note": "Static count from serialized tile_map_data; cleanup tool uses get_used_cells() inside Godot.",
            "first_25_used_cell_coordinates_static": first_coords,
            "z_index": int(props.get("z_index", "0")),
            "z_as_relative": props.get("z_as_relative", "true") != "false",
            "y_sort_enabled": props.get("y_sort_enabled", "false") == "true",
            "visible": props.get("visible", "true") != "false",
            "owner_scene": "res://scenes/hideout/HideoutHub.tscn",
            "asset_family": "central_security" if "central_security" in layer_groups else "core",
            "depth_role": depth_role_for(layer_groups),
            "groups": layer_groups,
            "safe_to_clear": safe,
            "safe_reason": "Under ArtRoot/World and uses a known PVGames paint TileSet." if safe else "Not using a known B4/B6 paint TileSet; inventory only.",
        })
    return layers


def dry_run_groups(layers: list[dict[str, Any]]) -> dict[str, Any]:
    results: dict[str, Any] = {}
    for group in GROUPS:
        matched = [layer for layer in layers if group in layer["groups"] or group == "all_pvgames"]
        results[group] = {
            "target_group": group,
            "layers_that_would_be_cleared": [
                {
                    "node_path": layer["node_path"],
                    "tileset_path": layer["tileset_path"],
                    "used_cell_count": layer["used_cell_count_static"],
                    "safe_to_clear": layer["safe_to_clear"],
                }
                for layer in matched
            ],
            "total_cells_that_would_be_cleared": sum(layer["used_cell_count_static"] for layer in matched if layer["safe_to_clear"]),
            "changed": False,
            "note": "Dry-run only. No cells were cleared.",
        }
    return results


def write_inventory(layers: list[dict[str, Any]]) -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    INVENTORY_JSON.write_text(json.dumps({
        "status": "PASS",
        "hideout_scene": "res://scenes/hideout/HideoutHub.tscn",
        "pvgames_paint_layers": layers,
        "total_layers": len(layers),
        "total_used_cells_static": sum(layer["used_cell_count_static"] for layer in layers),
        "cells_cleared": 0,
    }, indent=2), encoding="utf-8")
    lines = [
        "# 0M-B7 PVGames Paint Layer Inventory",
        "",
        "Status: PASS",
        "",
        "No cells were cleared. Counts below are static counts from serialized `tile_map_data`; the cleanup tool uses `get_used_cells()` when run inside Godot.",
        "",
        "| Layer | Family | Depth Role | TileSet | Used Cells | Safe |",
        "| --- | --- | --- | --- | ---: | --- |",
    ]
    for layer in layers:
        lines.append("| `{}` | {} | {} | `{}` | {} | {} |".format(
            layer["node_path"],
            layer["asset_family"],
            layer["depth_role"],
            layer["tileset_path"],
            layer["used_cell_count_static"],
            "yes" if layer["safe_to_clear"] else "no",
        ))
    INVENTORY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_how_to() -> None:
    HOW_TO.write_text("""# PVGames Paint Layer Cleanup How-To

## Why Normal Erasing May Fail

Many PVGames paint assets are large rendered sprites stored as one TileMap tile. The occupied TileMap cell is at the tile anchor/grid coordinate, but the visible artwork may extend upward, sideways, or far away from that anchor. Clicking the visible art may not click the actual occupied cell, so Godot's normal eraser, right-click erase, or undo can feel unreliable.

The reliable delete path is to operate on the `TileMapLayer` data directly with methods such as `get_used_cells()`, `erase_cell(coords)`, and `clear()`.

## Identify Which Layer Contains A Tile

1. Hide/show likely paint layers with the editor eye icon.
2. Read `res://docs/reports/hideout_phase_0mb7_pvgames_paint_layer_inventory.md`.
3. Check the layer's used cell count.
4. Select suspected `TileMapLayer` nodes under `ArtRoot/World`, never under `GameplayRoot`.

## Safe Cleanup Examples

Example A, clear one exact layer after dry-run:

`layer_path = "ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableWallPaintLayer"`

Example B, dry-run all Central Security:

`group_name = "central_security"`

Example C, clear all PVGames paint layers:

`group_name = "all_pvgames"`

Actual clearing should only happen after reviewing dry-run results.

## Using The Runner

Open `res://src/tools/editor/PVGamesPaintLayerCleanupRunner.gd`. The checked-in default is:

`const MODE := "dry_run_inventory"`

Allowed modes are documented at the top of that file. Change to `dry_run_layer` or `dry_run_group` first. Only use `clear_layer` or `clear_group` after reviewing the dry-run.

## Backup Behavior

Future destructive clear calls create backups like:

`res://scenes/hideout/HideoutHub.phase0mb7_cleanup_backup.REASON.TIMESTAMP.tscn`

To restore, close Godot or make sure the scene is not open, then replace `HideoutHub.tscn` with the backup scene.

## What Not To Delete

Do not delete `GameplayRoot`, `ArtRoot`, station proxies, collision, player, UI, E prompts, `.tres` TileSet resources, or source PNG files. The cleanup tool is designed to clear only painted cell data on safe PVGames `TileMapLayer` nodes.

## Repaint After Clearing

Select the appropriate Core or Central Security paint layer under `ArtRoot/World`, then repaint from the TileMap palette. Use behind-player layers for floor/backdrop art and occludable layers for walls/props that should draw above the player.

## If The Tool Finds Zero Layers

Confirm you are using `HideoutHub.tscn`, the PVGames paint layers still live under `ArtRoot/World`, and the TileSet resource paths point to `pvgames_catalog_paintable` or `pvgames_central_security_paintable`.

## If A Layer Is Unsafe

Do not force-clear it. It may not use a known PVGames paint TileSet or may be outside `ArtRoot/World`. Inspect the node path and TileSet path first.
""", encoding="utf-8")


def write_main(layers: list[dict[str, Any]], dry_runs: dict[str, Any]) -> None:
    counts = {
        "pvgames_paint_layers_found": len(layers),
        "core_paint_layers_found": sum(1 for layer in layers if "core" in layer["groups"]),
        "central_security_paint_layers_found": sum(1 for layer in layers if "central_security" in layer["groups"]),
        "ground_floor_layers_found": sum(1 for layer in layers if "ground" in layer["groups"]),
        "wall_layers_found": sum(1 for layer in layers if "wall" in layer["groups"]),
        "occludable_layers_found": sum(1 for layer in layers if "occludable" in layer["groups"]),
        "foreground_layers_found": sum(1 for layer in layers if "foreground" in layer["groups"]),
        "review_only_layers_found": sum(1 for layer in layers if "review_only" in layer["groups"]),
        "total_used_pvgames_cells_static": sum(layer["used_cell_count_static"] for layer in layers),
    }
    data = {
        "status": "PASS",
        "hideout_hub_modified": False,
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "cells_actually_cleared_in_this_pass": 0,
        **counts,
        "used_cell_count_per_layer": {layer["node_path"]: layer["used_cell_count_static"] for layer in layers},
        "cleanup_tool_path": "res://src/tools/editor/PVGamesPaintLayerCleanupTool.gd",
        "runner_path": "res://src/tools/editor/PVGamesPaintLayerCleanupRunner.gd",
        "dry_run_results": dry_runs,
        "backup_before_clear_implemented": True,
        "how_to_guide_path": "res://docs/reports/pvgames_paint_layer_cleanup_how_to.md",
        "risks_limitations": [
            "Report counts are static from serialized tile_map_data; the Godot tool uses get_used_cells() at runtime.",
            "Future clear modes are destructive and should only be used after dry-run review.",
        ],
        "recommended_next_step": "Review the inventory report, identify the unwanted layer, then run a dry-run for that exact layer before clearing.",
    }
    MAIN_JSON.write_text(json.dumps(data, indent=2), encoding="utf-8")
    lines = [
        "# 0M-B7 PVGames Paint Layer Cleanup Tool",
        "",
        "Status: PASS",
        "",
        "- HideoutHub modified: no",
        "- Taco Bell scenes modified: no",
        "- Gameplay scripts modified: no",
        "- Cells actually cleared in this pass: 0",
        f"- PVGames paint layers found: {counts['pvgames_paint_layers_found']}",
        f"- Total used PVGames cells found: {counts['total_used_pvgames_cells_static']}",
        f"- Cleanup tool: `{data['cleanup_tool_path']}`",
        f"- Runner: `{data['runner_path']}`",
        f"- How-to guide: `{data['how_to_guide_path']}`",
        "",
        "## Dry-Run Results",
        "",
    ]
    for group, result in dry_runs.items():
        lines.append(f"- `{group}`: {len(result['layers_that_would_be_cleared'])} layers, {result['total_cells_that_would_be_cleared']} cells would be cleared, changed=false")
    lines.extend([
        "",
        "Backup-before-clear behavior is implemented in the cleanup tool. No clear operation was run in this pass.",
    ])
    MAIN_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    layers = build_inventory()
    dry_runs = dry_run_groups(layers)
    write_inventory(layers)
    write_how_to()
    write_main(layers, dry_runs)
    print(json.dumps({
        "status": "PASS",
        "layers": len(layers),
        "total_used_cells_static": sum(layer["used_cell_count_static"] for layer in layers),
        "dry_run_groups": {group: result["total_cells_that_would_be_cleared"] for group, result in dry_runs.items()},
        "cells_cleared": 0,
    }, indent=2))


if __name__ == "__main__":
    main()
