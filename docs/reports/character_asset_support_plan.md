# Character / NPC / Creature Asset Support Plan

Status: planning only. No character replacement was performed.

## Recommended Asset Type

Use transparent PNG sprite sheets or frame sequences for 2D top-down, 3/4 top-down, isometric, or dimetric characters. Four-direction animation is the minimum; eight-direction animation is preferred.

## Folder Structure

```text
res://assets/characters/
  player/
  bentley/
  npcs/
    jake/
    mere/
    louis/
    ambient/
  enemies/
    guards/
  raw_source/
  licenses/
```

## Roles

- Player: idle, walk, interact/use, optional run/crouch/carry/hurt.
- Bentley: idle, walk, sit, sniff, happy/tail wag, optional sleep/pet reaction.
- Guards: idle, patrol/walk, alert, chase/run, attack, optional hurt/down.
- Ambient NPCs: idle, walk, talk/gesture, optional sit/stand.
- Jake/Mere/Louis: idle, talk/gesture, optional walk/special idle.

## Existing Character-Adjacent Assets Found

- `res://scenes/characters/guard.tscn`
- `res://assets/sprites/guard_sprite_frames.tres`
- `res://src/enemies/Guard.gd`
- Monogon imported character sidecars under `res://assets/tilesets/monogon_isometric_tilesets/.../Characters/` and `.../Nature&Character/`

No new character assets were downloaded, imported, or wired into gameplay during this pass. `res://assets/characters/` does not exist yet, so the recommended future folder structure remains a planning target.

## Good Future Search Terms

- 2D isometric animated character sprites
- 2D top-down animated character sprites
- 8 direction top-down character sprites
- top-down dog sprite sheet
- cyberpunk RPG character sprite sheet
- top-down guard sprite sheet

## Avoid

Avoid side-scrolling sprites, visual-novel-only front poses, non-transparent backgrounds, proprietary runtime plugins, one-direction-only packs, and character packs with no walking animation.

## Future Tool

Create `res://src/tools/editor/character_asset_audit.py` or `CharacterAssetAuditTool.gd` to inspect frame sizes, alpha, directions, animation rows, and suitability for player/NPC/guard/Bentley roles.
