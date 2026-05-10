# 0M-D1C — Canonical Taco scene correction (final)

## Verdict: **PASS**

MissionBoard / hideout catalog / debug iso entry points now load **`TacoBellIso_Editable_RedesignTest.tscn`**, which file evidence and GRB confirm is the **expanded** map. **`TacoBellIso_Editable.tscn`** remains as **legacy / bake-output** (unchanged on disk).

## Evidence (expanded vs old)

See `phase0md1c_scene_comparison.json`:

- **RedesignTest** ≈ 1.43M bytes, **1875** `[node` lines, **39** `ext_resource`, contains **Phase0J / Phase0K** substrings.
- **Editable** ≈ 706k bytes, **856** nodes, **14** `ext_resource`, **no** Phase0J/K markers.

## What changed

Routing constants / debug overrides only — **no** Taco map edits.

## Validation

- **Static:** `phase0md1c_static_validator.py` **PASS**; `phase0md1b_rt_static_validator.py` **PASS**.
- **Runtime (GRB):** After `launch_taco_bell()`, `grb_runtime_info.current_scene` == `…RedesignTest.tscn`; **Player** present in tree.

## Follow-ups

Optional doc cleanup in older `docs/reports/pre_taco_module_hardening*` artifacts if you want the word “canonical” to distinguish **playable** vs **bake-output** everywhere.
