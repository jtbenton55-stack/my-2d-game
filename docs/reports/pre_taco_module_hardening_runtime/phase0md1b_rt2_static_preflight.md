# 0M-D1B-RT2 — Static preflight (Phase 3)

## Commands run

```text
python src/tools/editor/pre_taco_module_hardening/phase0md1b_static_validator.py
python src/tools/editor/pre_taco_module_hardening_runtime/phase0md1b_rt_static_validator.py
python src/tools/editor/pre_taco_module_hardening_runtime/phase0md1b_rt2_static_validator.py
```

All returned **PASS** at RT2 completion time.

## `project.godot`

Not present in `git diff --name-only HEAD` after this pass’s intentional edits.

## RT2 validator

`src/tools/editor/pre_taco_module_hardening_runtime/phase0md1b_rt2_static_validator.py` delegates to the RT static validator and writes `phase0md1b_rt2_static_preflight_machine.json`.
