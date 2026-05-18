# D6-06B — Interactable Collectible + Hideout Sync (AI Summary)

**Verdict:** PASS  
**Branch:** `c2a-full-character-animation-20260509-172230`

## What changed

- Authored collectibles now spawn as `AuthoredPhase0JInteractablePickup` under `GeneratedRuntimeInteractables/AuthoredGeneratedInteractables`.
- Mission attempt tracking + commit-on-success in `IsoMissionBase.gd`.
- Hideout display flags via `MissionCollectibleHideoutSync` + `HideoutManager` deferred apply.
- Fixed blocking parse/compile bugs in `IsoMissionBase` and `MissionCollectibleHideoutSync`.

## Manual test

1. Open `TacoBellIso_Editable_RedesignTest.tscn`, play.
2. Go to proof cluster (~8950, 620); press **E** on each colored pickup.
3. F10 → Collectibles: pending counts, `phase0j_interactable` path.
4. Complete mission; confirm poop/polaroid/tiny persist and hideout flags.

Full report: `docs/reports/d6_06b_interactable_collectible_hideout_sync/FINAL_REPORT.md`
