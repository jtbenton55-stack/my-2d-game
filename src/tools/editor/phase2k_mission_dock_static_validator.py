"""Stable entry point for the Phase 2K Mission Dock validator."""

from __future__ import annotations

import runpy
from pathlib import Path


VALIDATOR = (
    Path(__file__).resolve().parent
    / "phase2k_mission_dock"
    / "phase2k_mission_dock_static_validator.py"
)


if __name__ == "__main__":
    runpy.run_path(str(VALIDATOR), run_name="__main__")
