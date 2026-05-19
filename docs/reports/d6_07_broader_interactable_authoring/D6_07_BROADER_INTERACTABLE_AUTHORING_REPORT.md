# D6-07 — Broader Interactable Authoring (Glow Guy, Clue, Case Cash)

**Date:** 2026-05-18  
**Verdict:** **PASS** (pipeline + MCP runtime); HideoutHub **visual** shelf/corkboard/store UI **PARTIAL** (flags + bank verified; full manual return pass recommended)

## Audit summary

| System | Finding |
|--------|---------|
| **Glow Guy** | `HideoutStateController.glow_guy_taco_bell_found` + `mark_collectible_display_found("glow_guy_taco_bell")`; shelf station exists |
| **Clues** | Evidence corkboard via `clue_*_found` flags; default proof key `clue_sauce_packet` |
| **Case Cash** | Source of truth: `HideoutStateController.case_cash` + `add_case_cash()`; store UI reads via `HideoutStorefrontPanel` |
| **D6-06 money** | Previously only `d6_06_money:*` flags; did not add spendable Case Cash |
| **D6-06 pipeline** | Unchanged flow: author → builder → Phase0J interactable → pending → success commit |

## Implementation

### New author nodes
- `GlowGuyAuthor.gd` — type `glow_guy`, default hideout `glow_guy_taco_bell`
- `ClueAuthor.gd` — type `evidence_clue`, clue metadata, default hideout `clue_sauce_packet`
- `CaseCashAuthor.gd` — type `case_cash`, amount via `case_cash_amount`

### Case Cash bridge
- `MissionCollectibleHideoutSync.commit_case_cash()` — calls `HideoutStateController.add_case_cash` when in hideout; otherwise banks in `GameState.dialogue_flags["d6_06_case_cash_bank"]`
- `HideoutManager._apply_mission_collectible_flags_to_state()` — applies bank on hideout load
- `MoneyPickupAuthor.commits_as_case_cash` — existing money authors also commit as Case Cash (default true)

### Runtime / mission
- `CollectibleAuthoringRuntimeBuilder` — spawns glow/clue/case_cash; extended author counts
- `IsoMissionBase` — pending case cash amount, glow/clue author counts, commit path for `case_cash`
- `AuthoredPhase0JInteractablePickup` — passes clue/glow/case cash payload fields
- F10 (`IsoMissionDebugPanel`) — glow/clue/case cash pending, bank, corkboard/shelf sync lines

### Taco proof cluster
Added at `CollectibleAuthoringProof` (~8950, 620): `D6_07_GlowGuy_Author`, `D6_07_Clue_Author`, `D6_07_CaseCash_Author` (7 total spawned interactables).

## Validation

| Check | Result |
|-------|--------|
| Static validator `phase0md6_07_static_validator.py` | **PASS** |
| D6-06 validator (regression) | **PASS** |
| GdUnit4 `tests/d6_06/` | **4/4 PASS** (incl. Case Cash bank) |
| MCP spawn count | **7** (4 D6-06 + 3 D6-07) |
| MCP commit glow+clue+case_cash | `committed:3`, `bank=15`, hideout flags set |
| MCP fail_level | pending cleared, bank unchanged |
| Godot LSP | 0 issues |

## D6-06 regression

- Poop/polaroid/tiny/money authors unchanged in scene
- `commit_authored_collectibles_for_success` idempotency preserved
- Taco Louis fallback allowlist untouched
- Failure no-commit preserved

## Kimi K2.6

- **Used:** `implementation_plan` for Case Cash mission→hideout bridge
- **Adopted:** Bank in `GameState` when hideout controller absent; apply on hideout load (via `d6_06_case_cash_bank` flag, not full GameState API rewrite)
- **Rejected:** Modifying `GameState.gd` with deposit/withdraw methods (narrower dialogue_flags bank used instead)
- Advisory only; no secrets sent

## Known limitations

- Full E-interaction playthrough of all 7 proof items + Louis + HideoutHub visuals not repeated in MCP (method-based commit validated)
- Hideout store Case Cash label not visually confirmed in hideout scene this pass
- `CaseCashAuthor` extends `MoneyPickupAuthor` (validator accepts both bases)

## Manual checklist

1. Play Taco iso; collect all 7 proof interactables (E).
2. F10: pending glow/clue/case cash counts.
3. Complete mission via Louis; confirm Case Cash in store terminal.
4. Confirm corkboard clue + glow shelf in hideout.
5. Replay: one-shot items should not duplicate.
