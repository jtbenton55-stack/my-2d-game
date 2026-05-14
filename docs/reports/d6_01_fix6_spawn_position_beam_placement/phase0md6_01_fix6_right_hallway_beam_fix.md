# Right Hallway Beam Fix

Beam visual now uses GameplayRoot/RuntimeSystems instead of the hidden DebugLabels branch, with tag D6_FIX6_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS. Placement is derived from the retrieve_delivery_bag authoring marker minus an approach offset, falling back to map cell only if the marker cannot be found. Headless probe confirms the beam node exists at runtime. Trigger alignment reuses garage_entry_beam Area2D and F10 says how to test it.

## Assertions
- ASSERT right_hallway_beam_visual_added_or_deferred_with_reason == true
- ASSERT beam_f10_copy_player_readable == true
- ASSERT failed_fix5_beam_coordinate_not_blindly_reused == true
