# 0M-D2A — Sprint canonicalization (final)

**Verdict:** PARTIAL — static validation PASS; GRB/editor playtest not executed here.

**Summary:** Corrected `sprint` input map (Space + real Ctrl keycode), centralized `is_sprint_requested()` on `PlayerStaminaController`, removed the `(not combat_on)` stamina sprint gate, and suppressed stamina sprint during combat dash / legacy dodge burst to avoid double movement effects.

See `phase0md2a_sprint_canonicalization.json` for machine-readable fields.
