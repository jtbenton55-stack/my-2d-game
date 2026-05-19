# GODOT SCENE NODE AUDIT

Focused scene/node audit for Taco mission and HideoutHub.

## Scenes inspected

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://scenes/hideout/HideoutHub.tscn`
- `res://scenes/MainMenu.tscn`

## Taco scene findings

### Active mission roots (protected)

- `GameplayRoot`
- `ArtRoot`
- `EntityRoot`
- `GameplayRoot/SecurityAuthoringRoot`
- `GameplayRoot/GeneratedRuntimeInteractables`
- `GameplayRoot/RuntimeSystems`
- `GameplayRoot/MarkerRoot`

Classification:

- `PROTECTED_BASELINE` for root structure and runtime roots.

### Authoring cluster (active)

- Security author nodes present and referenced by active runtime builder pathways.
- Collectible author proof cluster present under:
  - `GameplayRoot/SecurityAuthoringRoot/CollectibleAuthoringProof/*`

Classification:

- `KEEP_ACTIVE` for authored security/collectible nodes used by current flow.

### Clutter/residue signals

- High density of auto-named label nodes (`@Label@#####`) around area triggers and lock-zone proof blocks.
- Very high label/collision shape counts from editor query.
- Runtime query shows very large `GeneratedRuntimeInteractables` and `GeneratedRuntimeMarkerDebugInteractables` surfaces.

Classification:

- Auto-label residue: `KEEP_BUT_REFACTOR_LATER` (not safe immediate cleanup).
- Debug marker bulk: `KEEP_BUT_REFACTOR_LATER`.
- Unknown subclusters with unclear runtime impact: `UNKNOWN_NEEDS_MANUAL_REVIEW`.

## Hideout scene findings

### Active roots and manager cluster

- `GameplayRoot` with navigation/spawn/manager children.
- `GameplayRoot/Managers/*` includes mission/evidence/scheme/store/character/debug/state/decoration controllers.
- `ArtRoot/World/*` has layered structure including `FloorLayer`, `WallLayer`, prop/decor/foreground/lighting/editor guide.

Classification:

- `PROTECTED_BASELINE` for manager cluster and core hideout structure.

### Paint and depth layer families

- `PVG_CatalogPaintLayers/*`
- `PVG_DepthPaintLayers/*`
- `PVG_CentralSecurityPaintLayers/*`
- `PVG_CentralSecurityDepthPaintLayers/*`

Classification:

- `KEEP_ACTIVE` or `FUTURE_USEFUL` depending on exact layer.
- Some potentially historical/experimental paint layers: `UNKNOWN_NEEDS_MANUAL_REVIEW`.

### Node-clutter risk profile

- Large number of art/depth layers and managed runtime helpers increases accidental-break risk for broad scene cleanup.
- Hideout manager does runtime child manipulation and deferred setup; structural edits can trigger race-like issues (`add_child` busy warning observed once in log traces).

Classification:

- `KEEP_BUT_REFACTOR_LATER` for orchestration complexity.

## Main menu scene findings

- Compact UI structure with buttons/settings panel and script hookup.
- Runtime main-scene tree check matches expected startup baseline.

Classification:

- `PROTECTED_BASELINE`.

## Missing-script/obvious breakage check

- No hard scene-open failure for Taco/Hideout/MainMenu during MCP inspection.
- No immediate missing-script crash in these scene opens.
- However, editor logs include warnings that merit later hardening pass.

## Node cleanup policy from this audit

- No node edits made.
- Candidate node cleanup deferred to later approved pass.
- Any future move/removal must use per-node manifest + rollback mapping and runtime parity checks.
