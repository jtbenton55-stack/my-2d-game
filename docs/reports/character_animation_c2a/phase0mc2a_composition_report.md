# Phase 0M-C2A — Composition Report

**Phase:** 0M-C2A
**Phase Name:** Compose Animated Parmida Spritesheet

## Output Files

- **Composite Sheet:** `assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png`
- **Individual Frames:** `assets/characters/generated_player_visuals/c2a_animation/frames`
- **Metadata:** `assets/characters/generated_player_visuals/c2a_animation/parmida_player_animation_metadata.json`
- **Contact Sheet:** `assets/characters/generated_player_visuals/c2a_animation/parmida_player_frame_contact_sheet_0mc2a.png`

## Animation Details

**Frame Size:** 100 x 200 pixels
**Layers Used:** base, bottoms, tops, head, hair

### Idle Animation
- **Frame Count:** 10
- **FPS:** 6
- **Loop:** True
- **Source Row in Kit:** 0

### Walk Animation
- **Frame Count:** 10
- **FPS:** 10
- **Loop:** True
- **Source Row in Kit:** 10

## Layer Composition Order

| Order | Layer | Variant | Kit |
|-------|-------|---------|-----|
| 1 | base | CyberCity_3 | CyberCity_CharacterCreatorKit_1 |
| 2 | bottoms | CyberCity_13 | CyberCity_CharacterCreatorKit_1 |
| 3 | tops | CyberCity_24 | CyberCity_CharacterCreatorKit_2 |
| 4 | head | CyberCity_4 | CyberCity_CharacterCreatorKit_2 |
| 5 | hair | CyberCity_7 | CyberCity_CharacterCreatorKit_1 |

## Hard Assertions

- **animated_composite_created_or_static_target_reported:** [PASS]
- **layer_order_documented:** [PASS]
- **selected_source_layers_documented:** [PASS]
- **generated_composite_has_transparency:** [PASS]
- **no_runtime_paperdoll_created:** [PASS]
- **no_raw_layers_modified:** [PASS]