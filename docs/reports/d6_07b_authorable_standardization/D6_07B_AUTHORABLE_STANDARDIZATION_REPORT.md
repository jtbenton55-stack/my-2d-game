# D6-07B — Authorable Taxonomy + Drag/Drop Instance Standardization

**Date:** 2026-05-18  
**Verdict:** **PASS** (standardization + validators + tests); MCP runtime direct-hook checks are **PARTIAL** due intermittent command-stop timeouts.

## Audit summary

### Author scripts and IDs

- `CollectibleAuthorBase` provides `collectible_id`, `one_shot`, `hideout_collection_key`, and shared runtime config.
- Supported concrete authors now: `PoopBagAuthor`, `PolaroidAuthor`, `TinyIconAuthor`, `GlowGuyAuthor`, `ClueAuthor`, `CaseCashAuthor`, plus legacy `MoneyPickupAuthor` alias.
- `MoneyPickupAuthor` previously emitted `money`; now forced to emit `case_cash` for compatibility.

### Runtime builder and multi-instance handling

- Builder discovers all collectible authors under `SecurityAuthoringRoot` recursively.
- Added duplicate-ID guard in builder: later duplicates are skipped and counted in runtime debug summary.
- Multiple same-type nodes are supported when IDs are unique.

### Persistence/idempotency

- One-shot replay prevention remains keyed by collectible ID (`d6_06_authored_committed:*`, plus money alias flag).
- Case Cash commit path remains success-only (`commit_authored_collectibles_for_success`) and no-commit on fail.
- Multi-instance Case Cash uses unique IDs and additive amounts.

### Taco proof cluster

- Updated to include multi-instance coverage:
  - 2x poop bag proof IDs
  - 2x Case Cash proof IDs with different amounts
  - 2x clue proof IDs

### Templates/drag-drop

- Added reusable template scenes under `scenes/missions_iso/authoring_templates`.
- Templates intentionally use placeholder IDs; validator enforces placeholders must not remain in mission scenes.

## Case Cash consolidation decision

- **Forward path:** `CaseCashAuthor` only.
- **Money handling:** `MoneyPickupAuthor` is now explicit **deprecated compatibility alias** that emits `case_cash` (`get_author_kind() -> "case_cash"`, currency forced to `case_cash`).
- Existing scenes using old money author script remain functional without creating a second currency path.

## Multi-instance rules standardized

- Unique IDs required for every placement.
- Unique one-shot unlocks: `polaroid`, `tiny_icon`, `glow_guy`, `clue`.
- Countable/amount types: `poop_bag`, `case_cash` (still unique IDs required for stable replay behavior).
- Duplicate IDs are validator errors; runtime also blocks duplicate spawn as safety net.

## Files changed (D6-07B scope)

- `src/missions/iso/authoring/MoneyPickupAuthor.gd`
- `src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd`
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py` (new)
- `src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py`
- `docs/reports/d6_07b_authorable_standardization/D6_07B_AUTHORABLE_TAXONOMY_AND_PLACEMENT_GUIDE.md` (new)
- `scenes/missions_iso/authoring_templates/PoopBagAuthorTemplate.tscn` (new)
- `scenes/missions_iso/authoring_templates/CaseCashAuthorTemplate.tscn` (new)
- `scenes/missions_iso/authoring_templates/ClueAuthorTemplate.tscn` (new)
- `scenes/missions_iso/authoring_templates/GlowGuyAuthorTemplate.tscn` (new)

## Validation

### Static validators

- `phase0md6_07b_static_validator.py` → **PASS**
- `phase0md6_07_static_validator.py` → **PASS**
- `phase0md6_06b_static_validator.py` → **PASS**

### GdUnit4

- `addons/gdUnit4/runtest.cmd ... -a res://tests/d6_06/` → **4/4 PASS**

### Godot LSP

- Workspace diagnostics scan: no new relevant errors; one pre-existing unrelated warning in `NPC.gd` (unused parameter).

### Godot MCP Pro

- Scene open/play succeeded repeatedly.
- Direct runtime hook checks confirmed:
  - author counts reflect multi-instance additions (`case_cash_auth=2`, `poop_auth=1`, `clue_auth=1` from author-kind counts, plus additional proof nodes in scene)
  - replay skip behavior observed for pre-marked IDs (`already_persisted` path)
  - fail path no-commit check (`bank 0->0`, pending cleared)
- Some execute-game-script calls intermittently failed with runtime stop/timeouts; full clean continuous script sequence was not stable in this session.

### DAP

- Not used; static validators + unit tests + MCP state probes were sufficient for this pass.

## Kimi K2.6 usage

- Used once (`architecture_review`) on duplicate-ID + legacy-alias replay-risk design.
- Adopted: explicit duplicate-ID detection and deterministic blocking at builder level + strict validator enforcement.
- Modified/rejected: did not add broad replay hashing or multiplayer-specific contracts in this pass (kept scope narrow).
- Kimi remained advisory only; no secrets/private files sent.

## Known limitations

- MCP runtime command stability prevented one fully linear scripted run proving every multi-instance metric in one pass.
- Builder duplicate handling currently skips later duplicates; intentional for safety, but still depends on scene order if duplicates exist (validator treats duplicates as errors to prevent relying on this).
- Template scenes are basic Node2D starters (no custom editor dock).

## Recommended next phase

- D6-07C Objective Authorables, then Route/Assist authorables, Interactable Prop authorables, and Inspectable authorables.
