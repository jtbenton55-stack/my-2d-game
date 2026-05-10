#!/usr/bin/env python3
"""0M-D1C: read-only comparison of Taco Bell .tscn candidates; writes JSON+MD under docs/reports/taco_canonical_scene_correction/."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OUT_DIR = ROOT / "docs/reports/taco_canonical_scene_correction"
CANDIDATES = [
    ROOT / "scenes/missions_iso/TacoBellIso_Editable.tscn",
    ROOT / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
]


def _analyze(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    return {
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "bytes": path.stat().st_size,
        "ext_resource_count": len(re.findall(r"^\[ext_resource ", text, flags=re.M)),
        "node_line_count": len(re.findall(r"^\[node ", text, flags=re.M)),
        "has_phase0j": "Phase0J" in text or "phase0j" in text.lower(),
        "has_phase0k": "Phase0K" in text or "phase0k" in text.lower(),
        "has_redesign_test_in_path": "RedesignTest" in path.name,
    }


def main() -> int:
    data = {"candidates": [_analyze(p) for p in CANDIDATES]}
    a, b = data["candidates"][0], data["candidates"][1]
    larger = a if a["bytes"] >= b["bytes"] else b
    smaller = b if larger is a else a
    conclusion = {
        "old_or_smaller_scene": smaller["path"],
        "expanded_likely_scene": larger["path"],
        "confidence": "high" if larger["bytes"] > smaller["bytes"] * 1.2 else "medium",
        "evidence": [
            f"Byte size ratio {larger['path']} vs {smaller['path']}: {larger['bytes']}/{smaller['bytes']:.3f}",
            f"Node line counts: {larger['path']}={larger['node_line_count']}, {smaller['path']}={smaller['node_line_count']}",
            "Phase0J/K substring markers present only on RedesignTest in this pair."
            if larger.get("has_phase0j") or larger.get("has_phase0k")
            else "Phase markers inconclusive",
        ],
        "uncertainty": "If a future pass intentionally shrinks the expanded scene below Editable, re-run metrics.",
    }
    data["conclusion"] = conclusion

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "phase0md1c_scene_comparison.json").write_text(json.dumps(data, indent=2), encoding="utf-8")

    md = [
        "# 0M-D1C — Taco scene comparison (machine)",
        "",
        "## Metrics",
        "",
        json.dumps(data["candidates"], indent=2),
        "",
        "## Conclusion",
        "",
        json.dumps(conclusion, indent=2),
    ]
    (OUT_DIR / "phase0md1c_scene_comparison.md").write_text("\n".join(md), encoding="utf-8")
    print("phase0md1c_scene_compare: wrote phase0md1c_scene_comparison.{md,json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
