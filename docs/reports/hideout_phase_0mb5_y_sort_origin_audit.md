# 0M-B5 Y Sort Origin / Base Sorting Audit

Status: PARTIAL, documented for manual tile tuning.

## Player

- Node path: `HideoutHubRoot/GameplayRoot/Characters/Player`
- Parent: `GameplayRoot/Characters`
- Scene type: `CharacterBody2D`
- Visual child: `AnimatedSprite2D`
- Player z-index before: `30`
- Player y-sort before: `false`
- Player z-index after: `30`
- Player y-sort after: `false`
- Feet/base reference: the `Player` node origin is near the collision/body base. The `AnimatedSprite2D` is offset upward by `Vector2(0, -16)`, so sorting the full player from the body origin is preferable to sorting from the sprite center.

## Feasibility

True shared Y-sort was not implemented in this pass. The player lives under `GameplayRoot`, while art lives under `ArtRoot/World`. Moving the full player would risk camera, combat, collision, station interaction, and existing manager paths such as `../../Characters/Player`.

A visual proxy was also skipped for this pass because it would require keeping an art-only sprite synchronized with the gameplay body and hiding the original sprite. That is possible later, but it is more invasive than this cleanup requires.

## Chosen Model

The pass uses an occludable foreground approximation:

- Background/floor/backdrop paint layers stay below the player.
- New occludable wall/prop paint layers draw above the player for art that should cover the player.
- Foreground overlay paint layers draw above both player and occludable props.

## Tile Base Sorting

The new occludable layers do not rely on per-tile Y-sort origins. For now, use them for wall lips, counters, posts, large props, and foreground structures that should visually cover the player. If a later pass implements true Y-sort, each TileSet atlas source should be tuned so each tile sorts from its bottom/base rather than its image center.

## Manual Tuning Notes

- Paint floors/roads/ground decals on behind layers.
- Paint back walls that should never cover the player on backdrop layers.
- Paint wall fronts, counters, shelves, columns, and tall props on occludable layers when they should cover the player.
- Paint ceiling pieces, overhead pipes, hanging signs, and lighting overlays on foreground layers.
