# 0M-D5-02B-FIX3 — Stamina regen fix

## Change

In `PlayerStaminaController.process_frame`, regeneration upper clamp:

- **Before:** `current_stamina = mini(max_stamina, current_stamina + regen_rate_per_sec * delta)`
- **After:** `current_stamina = minf(max_stamina, current_stamina + regen_rate_per_sec * delta)`

## Rationale

`mini` targets integers; mixing floats caused truncation so fractional regen per physics frame did not accumulate — bar appeared stuck after sprint ended.

## Non-goals preserved

No input map edits, no HUD layout, no Taco scenes, no `Player.gd` logic change, no dash behavior change.

## Assertions

| Assertion | Value |
|-----------|--------|
| stamina_regen_fix_implemented | true |
| sprint_drain_preserved | true |
| ctrl_release_regen_supported | true |
| exhaustion_does_not_block_regen_forever | true |
| no_input_binding_changes | true |
