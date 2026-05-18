# D6-06 Collectible Authoring — Implementation Report

## Summary

Functional collectible authoring foundation added: four author node types, shared base, runtime builder, auto-pickup runtime nodes, F10 debug section, and Taco proof cluster.

## New files

- `src/missions/iso/authoring/CollectibleAuthorBase.gd`
- `src/missions/iso/authoring/PoopBagAuthor.gd`
- `src/missions/iso/authoring/MoneyPickupAuthor.gd`
- `src/missions/iso/authoring/PolaroidAuthor.gd`
- `src/missions/iso/authoring/TinyIconAuthor.gd`
- `src/missions/iso/runtime/AuthoredCollectiblePickup.gd`
- `src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd`
- `src/tools/editor/d6_06_collectible_authoring/phase0md6_06_static_validator.py`

## Modified files

- `src/missions/iso/authoring/SecurityAuthoringRoot.gd` — deep `collect_collectible_authors()`
- `src/levels/IsoMissionBase.gd` — `_setup_d6_06_collectible_authoring_runtime()`, record/store helpers, debug summary fields
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` — `--- Collectible Authoring ---` F10 section
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` — proof cluster under `CollectibleAuthoringProof`

## Protected files

Untouched: `project.godot`, `Player.gd`, `player.tscn`, save/load, HUD input bindings.

## Systems reused

- **Poop:** `TypedMissionCollectible.collect(..., "poop_bag")` + `GameState.add_poop_bag()` for extra `poop_count`
- **Polaroid:** `TypedMissionCollectible` → `CollectibleManager.collect_polaroid()`
- **Tiny icon:** `TypedMissionCollectible` typed flag + attempt counter
- **Money:** proof-only (`d6_06_money:*` dialogue flag + attempt counter `d6_06_authored_money_cash`)

## GlowGuyAuthor

Not added — no dedicated safe runtime pickup; typed collect exists but deferred to D6-06A.

## Bug fixed during validation

`CollectibleAuthoringRuntimeBuilder._store_counts` used invalid `bool(authoring_root)`; changed to `authoring_root != null`.
