# Reusable module gap analysis

Compared the repo to the desired mission spine (20 rows). Classifications and notes live in `reusable_module_gap_analysis.json`.

## P0 before Taco Bell redesign (from gaps)

- Thin **mission adapter** boundary (remove Taco-only preloads from `IsoMissionBase`).
- **Player ↔ mission tool** boundary (`deploy_poop_bag_decoy_at` duck typing).
- **Objective / pause** single source of truth alignment.
- **Stamina/sprint** gameplay hook (even if UI is a placeholder bar).
- **Canonical Taco scene stack** decision (Editable vs RedesignTest controllers).
- **Attempt reset** semantics validated and fixed if in-scene retry is required.

## Can wait until after vertical slice

- Full **AnimationIntent** registry polish.
- **NoiseEvent** abstraction and fancy suspicion UI.
- CI headless Godot parse checks.
- Deep **assets/** enumeration in inventory (binaries skipped by static script).

## Hard assertions

See JSON `assertions`.
