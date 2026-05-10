# 0M-D1C — Static validation (Phase 4)

## Command

```text
python src/tools/editor/taco_canonical_scene_correction/phase0md1c_static_validator.py
python src/tools/editor/taco_canonical_scene_correction/phase0md1c_scene_compare.py
python src/tools/editor/pre_taco_module_hardening_runtime/phase0md1b_rt_static_validator.py
```

## Results

- **`phase0md1c_static_validator.py`:** **PASS** (see `phase0md1c_validation.json`)
- **`phase0md1c_scene_compare.py`:** wrote `phase0md1c_scene_comparison.{json,md}`
- **`phase0md1b_rt_static_validator.py`:** **PASS** after adding RedesignTest to the required scene list

## What the D1C validator enforces

Expanded + legacy `.tscn` files exist; hideout + `SceneManager` + debug panel strings match **RedesignTest**; `project.godot` / `player.tscn` not in working tree diff; taco scenes not in diff; `Player.gd` contains no `TacoBellIso` path strings.
