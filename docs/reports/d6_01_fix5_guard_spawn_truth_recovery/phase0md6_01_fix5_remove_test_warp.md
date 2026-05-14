# Remove/deactivate purple warp

- Removed runtime creation by replacing helper entry with _ensure_d6_fix5_runtime_helpers() and deleting FIX4 warp setup hook invocation.
- Added runtime cleanup _remove_d6_fix_test_warp_nodes() to queue-free existing D6_FIX4_GarageCodeTestWarp and D6_FIX3_GarageCodeTestWarp nodes if present.
- F10 warp copy removed.
