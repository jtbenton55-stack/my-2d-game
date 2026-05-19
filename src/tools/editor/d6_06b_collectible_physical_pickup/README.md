# D6-06B Physical Pickup Validator

This folder contains the early D6-06B physical-overlap pickup validator.

Status: superseded for new cleanup/feature decisions.

Reason:

- This validator checks the deprecated `AuthoredCollectiblePickup.gd` overlap path.
- Current authored collectible runtime uses the Phase0J interactable path through `AuthoredPhase0JInteractablePickup.gd` and mission completion persistence.
- New work should use `src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py` and later authorable validators.

Keep this folder for historical phase evidence unless a later cleanup pass archives superseded validators.
