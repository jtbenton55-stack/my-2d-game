# 0M-D5-00 — Phase 10: Static validation

## Script

`src/tools/editor/taco_bell_d5_00_runtime_truth/phase0md5_00_static_validator.py`

## Checks

1. Required JSON reports exist and parse.
2. Each report `assertions` object values are `true`.
3. RedesignTest scene file exists.
4. `MissionSceneResolver.gd` contains `taco_bell_drop` and `TacoBellIso_Editable_RedesignTest.tscn`.
5. Git status / diff do not touch protected gameplay paths or `assets/`.
6. Final report JSON includes `d5_01_recommendation`, `evidence_level_summary`, `runtime_limitations`.

## Run

Machine-readable output: `phase0md5_00_static_validator_run.json`.

## Assertions

See `phase0md5_00_validation.json`.
