# Phase 0M-C2A — Frame/Layer Alignment Matrix

**Phase:** 0M-C2A
**Phase Name:** Frame/Layer Alignment Proof

## Grid Alignment Summary

**[PASS] All C2 layers share the SAME grid — SAFE for animation compositing**

**Common Frame Size:** 100 x 200
**Common Grid:** 50 rows x 100 columns
**Total Frames per Layer:** 5000

## Per-Layer Analysis

### Base
- **Path:** `assets/characters/pvgames_cyber_city_character_creator_kit/CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Base/CyberCity_3/Spritesheet.png`
- **Dimensions:** 10000 x 10000
- **Frame Size:** 100 x 200
- **Grid:** 50 rows x 100 cols = 5000 frames
- **Detection Confidence:** high (matches C2 probe)
- **Other Candidates:** 6 other viable grids detected
- **Populated Rows:** 12 of 12

### Bottoms
- **Path:** `assets/characters/pvgames_cyber_city_character_creator_kit/CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Bottoms/CyberCity_13/Spritesheet.png`
- **Dimensions:** 10000 x 10000
- **Frame Size:** 100 x 200
- **Grid:** 50 rows x 100 cols = 5000 frames
- **Detection Confidence:** high (matches C2 probe)
- **Other Candidates:** 6 other viable grids detected
- **Populated Rows:** 12 of 12

### Tops
- **Path:** `assets/characters/pvgames_cyber_city_character_creator_kit/CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Tops/CyberCity_24/Spritesheet.png`
- **Dimensions:** 10000 x 10000
- **Frame Size:** 100 x 200
- **Grid:** 50 rows x 100 cols = 5000 frames
- **Detection Confidence:** high (matches C2 probe)
- **Other Candidates:** 6 other viable grids detected
- **Populated Rows:** 12 of 12

### Head
- **Path:** `assets/characters/pvgames_cyber_city_character_creator_kit/CyberCity_CharacterCreatorKit_2/CyberCity Character Creator Kit/Female/Head/CyberCity_4/Spritesheet.png`
- **Dimensions:** 10000 x 10000
- **Frame Size:** 100 x 200
- **Grid:** 50 rows x 100 cols = 5000 frames
- **Detection Confidence:** high (matches C2 probe)
- **Other Candidates:** 6 other viable grids detected
- **Populated Rows:** 12 of 12

### Hair
- **Path:** `assets/characters/pvgames_cyber_city_character_creator_kit/CyberCity_CharacterCreatorKit_1/CyberCity Character Creator Kit/Female/Hair/CyberCity_7/Spritesheet.png`
- **Dimensions:** 10000 x 10000
- **Frame Size:** 100 x 200
- **Grid:** 50 rows x 100 cols = 5000 frames
- **Detection Confidence:** high (matches C2 probe)
- **Other Candidates:** 6 other viable grids detected
- **Populated Rows:** 12 of 12

## Animation Structure Inference

**Primary Inference Source:** base

**Structure Hypothesis:** 8-directional with idle + walk
**Direction Count:** 8
**Animation Types:** idle, walk
**Confidence:** medium-low

**Note:** May have separate rows for idle vs walk animations

## Hard Assertions

- **layer_alignment_matrix_created:** [PASS]
- **selected_layers_grid_match:** [PASS]
- **selected_layers_have_required_frames:** [PASS]
- **mismatched_layers_rejected_or_reported:** [PASS]

## Phase 3 Animation Target Recommendation

**Recommended Target: OPTION C — Generic Idle + Walk**
Layers aligned but direction confidence is low. Avoid directional assumptions.