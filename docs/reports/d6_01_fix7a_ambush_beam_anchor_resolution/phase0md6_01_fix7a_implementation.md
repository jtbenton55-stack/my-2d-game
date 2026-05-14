# FIX7A Implementation
Implemented:
1. Added runtime debug marker resolver `_find_runtime_debug_marker(marker_id)`.
2. `_setup_fix7_ambush_beam_runtime()` now resolves in order: authoring marker -> runtime debug marker roots.
3. Added anchor resolution source tracking (`authoring_marker_root`, `runtime_debug_interactable_or_label`, `missing`).
4. Removed stale beam runtime nodes from prior D6_FIX* temp names.
5. Disabled legacy FIX6B fallback visual setup to prevent misleading beam placement.
6. Updated beam distance helper to report `missing_anchor` without coordinate fallback.
7. F10 now shows AMBUSH resolve source, anchor path, anchor/visual/trigger/mismatch proof.
