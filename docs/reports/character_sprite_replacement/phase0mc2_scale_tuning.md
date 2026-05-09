# 0M-C2-SCALE Player Visual Scale Tuning

Status: PASS

- Player scene: `res://scenes/characters/player.tscn`
- Backup: `res://scenes/characters/player.phase0mc2_scale_backup.20260509_165530.tscn`
- Scale comparison sandbox: `res://scenes/hideout/tools/PlayerVisualScaleComparison_0MC2.tscn`
- Previous scale: `(1, 1)`
- Previous offset: `(0, -20)`
- Candidate A: scale `1.25`, offset `(0, -32)`
- Candidate B: scale `1.35`, offset `(0, -37)` - selected
- Candidate C: scale `1.50`, offset `(0, -44)`
- Collision changed: no
- `Player.gd` changed: no
- Taco Bell scenes changed: no

## Baseline Calculation

The generated sprite is 46x96 and `Sprite2D` is centered. The current feet/base point is `-20 + 96 / 2 = 28`. For scale `1.35`, the matching offset is `28 - (96 * 1.35 / 2) = -36.8`, rounded to `-37`.

## Manual Test Checklist

1. Open `HideoutHub.tscn`.
2. Run HideoutHub.
3. Confirm the player is larger and easier to see.
4. Confirm she does not look giant.
5. Confirm her feet/base look grounded.
6. Move up/down/left/right.
7. Confirm controls feel unchanged.
8. Confirm collision feels unchanged.
9. Walk near walls/props.
10. Confirm nothing visually catastrophic happens.
11. Talk to Jake/Mere/Bentley.
12. Open Neon Nook.
13. Launch Taco Bell.
14. Pause/exit back to HideoutHub.
