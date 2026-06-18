#!/usr/bin/env python3
"""PHASE 0M-D6-08A security authorable foundation validator (read-only)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPORT_DIR = "d6_08a_security_authorables"
PLACEHOLDER_TOKENS = ("CHANGE_ME", "TODO_ID")

READY_TEMPLATES = (
    "SecurityBeamAuthorTemplate.tscn",
    "AmbushBeamAuthorTemplate.tscn",
    "SecurityCameraAuthorTemplate.tscn",
    "GuardSpawnAuthorTemplate.tscn",
    "GuardPatrolRouteAuthorTemplate.tscn",
    "PatrolWaypointTemplate.tscn",
    "AreaTriggerAuthorTemplate.tscn",
    "SecurityEffectSetAuthorTemplate.tscn",
)

PROTECTED_PATHS = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def extract_stringname(line: str, key: str) -> str | None:
    if f"{key} = &" not in line:
        return None
    m = re.search(rf'{key} = &"([^"]*)"', line)
    return m.group(1).strip() if m else None


def parse_security_authoring_section(scene_text: str) -> str:
    """Return text from SecurityAuthoringRoot node block through next top-level sibling."""
    lines = scene_text.splitlines()
    start = -1
    for i, line in enumerate(lines):
        if '[node name="SecurityAuthoringRoot"' in line:
            start = i
            break
    if start < 0:
        return ""
    depth = 0
    out: list[str] = []
    for line in lines[start:]:
        if line.startswith("[node "):
            if "parent=" not in line and out:
                break
            if 'parent="GameplayRoot/SecurityAuthoringRoot"' in line or (
                'parent=".' in line and "SecurityAuthoringRoot" in lines[start]
            ):
                out.append(line)
            elif line.startswith('[node name="SecurityAuthoringRoot"'):
                out.append(line)
                depth = 1
            elif depth > 0:
                out.append(line)
        elif depth > 0:
            out.append(line)
        if line.startswith("[node ") and "SecurityAuthoringRoot" not in line:
            if 'parent="GameplayRoot"' in line and out and i > start:
                break
    # Simpler: scan all lines under SecurityAuthoringRoot path prefix in parent attrs
    out = []
    in_root = False
    for line in lines:
        if '[node name="SecurityAuthoringRoot"' in line:
            in_root = True
        if in_root:
            out.append(line)
            if line.startswith("[node ") and "SecurityAuthoringRoot" not in line:
                if 'parent="GameplayRoot"' in line:
                    in_root = False
                    out.pop()
    return "\n".join(out)


def collect_ids_in_section(section: str, key: str) -> list[tuple[str, str]]:
    current_name = ""
    out: list[tuple[str, str]] = []
    for line in section.splitlines():
        if line.startswith("[node name="):
            m = re.search(r'name="([^"]+)"', line)
            current_name = m.group(1) if m else ""
        val = extract_stringname(line, key)
        if val is not None:
            out.append((current_name, val))
    return out


def collect_patrol_routes(section: str) -> dict[str, int]:
    routes: dict[str, int] = {}
    lines = section.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("[node name=") and i + 2 < len(lines) and "GuardPatrolRouteAuthor.gd" in lines[i + 2]:
            name_m = re.search(r'name="([^"]+)"', line)
            node_name = name_m.group(1) if name_m else ""
            rid = ""
            for j in range(i, min(i + 12, len(lines))):
                v = extract_stringname(lines[j], "route_id")
                if v:
                    rid = v
            wp = 0
            for j in range(i + 1, len(lines)):
                if lines[j].startswith("[node name="):
                    if f'parent="GameplayRoot/SecurityAuthoringRoot/{node_name}"' in lines[j] and "Waypoint" in lines[j]:
                        wp += 1
                    elif j > i + 1 and f"/{node_name}/" not in lines[j]:
                        break
            routes[rid or node_name] = wp
        i += 1
    return routes


def find_duplicates(pairs: list[tuple[str, str]]) -> list[str]:
    seen: dict[str, str] = {}
    dups: list[str] = []
    for node, val in pairs:
        if not val:
            continue
        if val in seen:
            dups.append(val)
        else:
            seen[val] = node
    return sorted(set(dups))


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []
    warnings: list[str] = []

    guide = root / "docs" / "SECURITY_AUTHORABLES_GUIDE.md"
    report = rd / "D6_08A_SECURITY_AUTHORABLES_REPORT.md"
    templates_dir = root / "scenes/missions_iso/security_authoring_templates"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    required_scripts = [
        "src/missions/iso/authoring/SecurityAuthoringRoot.gd",
        "src/missions/iso/authoring/SecurityBeamAuthor.gd",
        "src/missions/iso/authoring/SecurityCameraAuthor.gd",
        "src/missions/iso/authoring/GuardSpawnAuthor.gd",
        "src/missions/iso/authoring/GuardPatrolRouteAuthor.gd",
        "src/missions/iso/authoring/AreaTriggerAuthor.gd",
        "src/missions/iso/authoring/SecurityEffectSetAuthor.gd",
        "src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd",
    ]
    for rel in required_scripts:
        if not (root / rel).is_file():
            errors.append(f"missing required script: {rel}")

    if not guide.is_file():
        errors.append("missing docs/SECURITY_AUTHORABLES_GUIDE.md")
    if not report.is_file():
        errors.append(f"missing docs/reports/{REPORT_DIR}/D6_08A_SECURITY_AUTHORABLES_REPORT.md")

    if not templates_dir.is_dir():
        errors.append("missing scenes/missions_iso/security_authoring_templates/")
    else:
        for name in READY_TEMPLATES:
            tpath = templates_dir / name
            if not tpath.is_file():
                errors.append(f"missing READY template: {name}")
            else:
                text = read_text(tpath)
                if name != "PatrolWaypointTemplate.tscn":
                    if not any(tok in text for tok in PLACEHOLDER_TOKENS):
                        warnings.append(f"template may lack placeholder IDs: {name}")

    # Protected files: only fail if modified in git diff sense - check existence untouched content hash optional
    for rel in PROTECTED_PATHS:
        p = root / rel
        if not p.is_file():
            warnings.append(f"protected path not found (skip): {rel}")

    if not taco.is_file():
        errors.append("missing TacoBellIso_Editable_RedesignTest.tscn")
    else:
        ttext = read_text(taco)
        if "SecurityAuthoringRoot" not in ttext:
            errors.append("Taco scene missing SecurityAuthoringRoot")
        if "runtime_enabled" not in ttext and "SecurityAuthoringRoot" in ttext:
            warnings.append("SecurityAuthoringRoot runtime_enabled not explicit in scene text")

        sec = parse_security_authoring_section(ttext)
        for key in ("beam_id", "spawn_id", "route_id", "camera_id", "trigger_id", "effect_id"):
            pairs = collect_ids_in_section(sec, key)
            for node, val in pairs:
                if any(tok in val for tok in PLACEHOLDER_TOKENS):
                    errors.append(f"Taco security author placeholder {key}={val} on {node}")
            dups = find_duplicates(pairs)
            if dups:
                errors.append(f"duplicate Taco security {key}: {dups}")

        routes = collect_patrol_routes(sec)
        for rid, wp_count in routes.items():
            if wp_count < 2:
                warnings.append(f"patrol route '{rid}' has {wp_count} waypoint(s); recommend >= 2")

        # Guard spawn patrol route references
        route_ids = {v for _, v in collect_ids_in_section(sec, "route_id") if v}
        for node, val in collect_ids_in_section(sec, "patrol_route_id"):
            if val and val not in route_ids:
                errors.append(f"spawn '{node}' references missing patrol_route_id '{val}'")

        # Beam trip events should have listeners (spawn or effect) - soft check
        beam_events = {v for _, v in collect_ids_in_section(sec, "on_trip_event") if v}
        trigger_events: set[str] = set()
        for _, val in collect_ids_in_section(sec, "trigger_events"):
            pass  # array form not parsed
        for line in sec.splitlines():
            if "trigger_events = Array" in line:
                for ev in re.findall(r'&"([^"]+)"', line):
                    trigger_events.add(ev)
        for line in sec.splitlines():
            if "on_enter_event = &" in line:
                trigger_events.add(extract_stringname(line, "on_enter_event") or "")
        for line in sec.splitlines():
            if "on_alarm_event = &" in line:
                trigger_events.add(extract_stringname(line, "on_alarm_event") or "")
        for ev in beam_events:
            if ev and ev not in trigger_events:
                warnings.append(
                    f"beam event '{ev}' has no obvious GuardSpawn/effect listener in SecurityAuthoringRoot text"
                )

        if "AMBUSH_security_beam" not in ttext:
            warnings.append("Taco ambush proof beam node name not found")
        if "AmbushGuardSpawn_Author" not in ttext:
            warnings.append("Taco ambush guard spawn author not found")

    ai_report = root / "reports/ai/D6_08A_SECURITY_AUTHORABLES_REPORT.md"
    if not ai_report.is_file():
        warnings.append("missing reports/ai/D6_08A_SECURITY_AUTHORABLES_REPORT.md")

    rd.mkdir(parents=True, exist_ok=True)
    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Cannot verify runtime spawn/collision without Godot playtest.",
            "trigger_events Array parsing is partial.",
            "Does not validate MarkerRoot Phase0K JSON guards.",
        ],
    }
    (rd / "phase0md6_08a_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    if errors:
        print("FAIL")
        for e in errors:
            print(f"  ERROR: {e}")
        for w in warnings:
            print(f"  WARN: {w}")
        return 1
    print("PASS")
    for w in warnings:
        print(f"  WARN: {w}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
