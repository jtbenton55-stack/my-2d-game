# Hallway placement / offset strategy

- **Anchor:** Resolved `AMBUSH_security_beam` global position (FIX7A unchanged).
- **Beam center:** `anchor_pos + D6_FIX7B_AMBUSH_BEAM_CENTER_OFFSET` with named constant `Vector2(-180, -48)` to shift **left and up** from the marker cluster toward the narrow vertical choke described in FIX7B brief.
- **Height:** Fixed `560` px vertical span (`D6_FIX7B_AMBUSH_BEAM_HEIGHT`) — conservative wall-to-wall intent without map raycasts.
- **Trigger width:** `56` px (`D6_FIX7B_AMBUSH_BEAM_TRIGGER_WIDTH`) slightly wider than visual `32` px for reliable `body_entered`.
- **Automatic wall detection:** Not used (brittle); re-tune offset/height in a future pass if art/layout shifts.
- **F10 proof:** `fix7b_*` keys + IsoMissionDebugPanel “FIX7B beam geometry” block.
