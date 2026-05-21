# Y-Sort Roadmap / Blueprint Update Report

Date: 2026-05-21

Scope: Documentation update only.

## Goal

Add the planned 2.5D Y-sort visual-depth system to the plug-and-play roadmap and implementation blueprint, specifically in the PVGames, tile painting, and visual authoring pipeline sections.

## Files changed

| File | Change |
|---|---|
| `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` | Added 2.5D depth sorting decision, visual depth bands, Y-sortable world-object layer requirements, PVGames palette evolution notes, and near-term build-order mention. |
| `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` | Added visual depth preservation row, 2.5D visual-depth contract, recommended containers, Y-sort rules, pivot/origin rules, PVGames palette routing rules, and initial Z-band guidance. |

## Key decisions captured

- Use fixed-Z paint layers for floor, decals, lighting, always-behind art, always-front overlays, and debug/authoring visuals.
- Use a dedicated Y-sortable visual container for player/NPC/guard visuals and PVGames props that should dynamically sort in front of or behind the player.
- Treat `OccludableObjects` as a temporary staging route until a real sortable 2.5D object route exists.
- Avoid child `Sprite2D.z_index` hacks such as `-90` as the primary depth system.
- Require meaningful sortable-object origins, ideally at feet or floor-contact points.

## Validation

| Check | Result |
|---|---|
| `git diff --check` for the two docs | Passed |
| Search for new Y-sort / 2.5D terms in roadmap and blueprint | Passed |
| Godot runtime/editor check | Not applicable; docs only |

## Next discussion

Decide the concrete current-scene container strategy for Taco, including whether to pilot the sortable layer under `EntityRoot`, under a new shared visual root, or as a staged child under the current `ArtRoot/PVG_EditableObjects` structure.
