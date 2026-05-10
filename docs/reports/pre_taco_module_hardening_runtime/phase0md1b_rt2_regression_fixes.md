# 0M-D1B-RT2 — Regression triage (Phase 10)

## Issue

Hideout mission launch constants used **`TacoBellIso_Editable_RedesignTest.tscn`** while D1B canonical documentation and `SceneManager`’s `taco_bell_drop` path target **`TacoBellIso_Editable.tscn`**.

## Classification

Routing mismatch vs D1B canonical decision — **not** a Taco layout or gameplay redesign.

## Fix (minimal)

- `src/hideout/HideoutMissionBoardController.gd` — `TACO_BELL_SCENE` → canonical editable scene
- `src/hideout/HideoutStationCatalog.gd` — same (mission slot 0 `scene_path`)

## Re-verify

- `grb_runtime_info` while in-mission: **TacoBellIso_Editable**
- Static validators: **PASS**
