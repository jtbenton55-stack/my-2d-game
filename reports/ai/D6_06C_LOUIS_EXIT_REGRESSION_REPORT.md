# D6-06C Louis Exit Regression — AI Summary

**Verdict:** PASS

## Root cause
`Phase0JInteractionBridge` stole E/Q and ignored Louis (`Phase0K`); debug markers at (800,848) won focus over `LouisExitToken`. Collected authored pickups stayed interaction-eligible.

## Fix
- Bridge includes `phase0k_louis_exit` / Phase0K candidates.
- Collected Phase0J pickups no longer compete for focus.
- Louis exit commits D6-06 pending collectibles via mission fallback when Phase0K bag+gate requirements met.

## Files
`Phase0JInteractionBridge.gd`, `Phase0JInteractablePickup.gd`, `Phase0KLouisExitInteractable.gd`, `Phase0KMissionCompletionController.gd`

Full report: `docs/reports/d6_06b_interactable_collectible_hideout_sync/D6_06C_LOUIS_EXIT_REGRESSION_REPORT.md`
