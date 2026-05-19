# D6-07 — Broader Interactable Authoring (AI handoff)

**Verdict:** **PASS** (code + MCP); HideoutHub visuals **PARTIAL**

## Summary

Extended D6-06 authored interactable pipeline for **Glow Guy**, **clue/evidence**, and **Case Cash** without duplicate managers.

## Key files

- `src/missions/iso/authoring/GlowGuyAuthor.gd` (new)
- `src/missions/iso/authoring/ClueAuthor.gd` (new)
- `src/missions/iso/authoring/CaseCashAuthor.gd` (new)
- `MoneyPickupAuthor.gd`, `CollectibleAuthoringRuntimeBuilder.gd`, `MissionCollectibleHideoutSync.gd`, `IsoMissionBase.gd`, `IsoMissionDebugPanel.gd`, `HideoutManager.gd`
- Taco scene: 3 new proof authors (7 interactables total)

## Case Cash

Mission commit → `commit_case_cash()` → `HideoutStateController.add_case_cash` or `d6_06_case_cash_bank` → applied on hideout load.

## Tests

- GdUnit4: 4/4 PASS
- Validator: PASS

Full report: `docs/reports/d6_07_broader_interactable_authoring/D6_07_BROADER_INTERACTABLE_AUTHORING_REPORT.md`
