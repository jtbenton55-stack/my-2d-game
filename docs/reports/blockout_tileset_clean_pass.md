# Blockout TileSet Clean Pass

Date: 2026-05-05  
Phase: 0F Global Clean Blockout Tileset Pass

## Asset manifest

- Original atlas:
  - `res://assets/tilesets/iso_blockout/iso_blockout_atlas.png`
- Original TileSet:
  - `res://assets/tilesets/iso_blockout/IsoBlockoutTileset.tres`
- Duplicated clean atlas:
  - `res://assets/tilesets/iso_blockout_clean/iso_blockout_atlas_clean.png`
- Duplicated clean TileSet:
  - `res://assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres`

## Recolor strategy

- Atlas dimensions preserved: `384x192`
- Atlas grid preserved: `64x64` regions
- Recolored by alpha mask only (non-transparent pixels changed, transparency preserved):
  - floor tile region `(0,0)` -> white (`#FFFFFF`)
  - wall tile region `(1,0)` -> black (`#000000`)
- Pixel counts changed:
  - floor non-transparent pixels recolored: `1208`
  - wall non-transparent pixels recolored: `1211`

## Scene and runtime updates

### Updated to use clean atlas/tileset

- Runtime blockout source switched in:
  - `src/levels/IsoMissionBase.gd`
    - `BLOCKOUT_TILESET_PATH` -> clean TileSet
    - `BLOCKOUT_ATLAS_PATH` -> clean atlas

### Inspected but not directly changed

- `scenes/missions_iso/TacoBellIso_Editable.tscn`
- `scenes/missions_iso/TacoBellIso_Editable_Test.tscn`
- `scenes/missions_iso/TacoBellIso_Editable2.tscn`
- `scenes/missions_iso/TacoBellIsoBlockout.tscn`
- `scenes/missions_iso/TacoBellIsoHandEditTest.tscn`
- `scenes/templates/IsoMissionTemplate.tscn`

Reason: these rely on `IsoMissionBase` runtime TileSet application.  
Note: editable scenes embed an internal `ImageTexture` in scene subresources; direct ext-resource swap to a PNG caused loader/import failures in runtime. For safety, scene-local embedded textures were left untouched and runtime application now points to the clean atlas globally.

## Originals preserved

- Original atlas untouched.
- Original TileSet untouched.
- Clean pass is reversible by restoring runtime constants and embedded atlas texture references to original resources.
