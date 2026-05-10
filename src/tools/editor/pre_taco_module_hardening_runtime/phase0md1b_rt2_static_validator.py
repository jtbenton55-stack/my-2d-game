#!/usr/bin/env python3
"""0M-D1B-RT2 static preflight: delegates to RT validator + records RT2 report path."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
RT = ROOT / "src/tools/editor/pre_taco_module_hardening_runtime/phase0md1b_rt_static_validator.py"
REPORTS = ROOT / "docs/reports/pre_taco_module_hardening_runtime"


def main() -> int:
    if not RT.exists():
        print("phase0md1b_rt2_static_validator: FAIL missing phase0md1b_rt_static_validator.py")
        return 1
    r = subprocess.run([sys.executable, str(RT)], cwd=str(ROOT), capture_output=True, text=True)
    ok = r.returncode == 0
    out = {
        "pass_name": "0M-D1B-RT2",
        "delegates_to": str(RT.relative_to(ROOT)),
        "subprocess_ok": ok,
        "stdout": (r.stdout or "").strip(),
        "stderr": (r.stderr or "").strip()[-2000:],
    }
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / "phase0md1b_rt2_static_preflight_machine.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("phase0md1b_rt2_static_validator:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
