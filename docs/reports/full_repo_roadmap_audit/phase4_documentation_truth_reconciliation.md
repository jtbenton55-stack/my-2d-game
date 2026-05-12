# GAME-ROADMAP-01 — Phase 4: Documentation / Report Truth Reconciliation

This phase audits the top-level design docs, the 26 phase-report subfolders, and the README. Verdicts follow this scheme:

- **CURRENT** — matches code; safe to follow.
- **STALE** — written before later passes that supersede it; mostly accurate but partially outdated.
- **CONFLICTED** — actively contradicted by code or a newer report.
- **STALE_BUT_FOUNDATIONAL** — older but still gives correct architectural framing.
- **NOISE** — internal artifact / process record, not gameplay-guiding.

## 1. Top-level documents

| Path | Verdict | Says | Matches code? | How future prompts should treat |
|------|---------|------|---------------|---------------------------------|
| `docs/MISSION_BIBLE.md` | **CURRENT** (vision) | 11-mission Sterling arc, per-mission checklist, build order | Yes, as **intent**; iso framework decision not reflected | Treat as guiding vision; add Bible Addendum after Phase 1 |
| `README.md` | **CONFLICTED** | "5 missions complete, 16 scheme cards, gift-game ready" | No — only 1 playable mission today | **Rewrite** or replace with a current-state README; do not let it guide planning |
| `FOLLOWUPS.md` | **STALE_BUT_FOUNDATIONAL** | Jazz Club deferred Phase 2/4 items | Code agrees (Jazz Club still LevelBase-style) | Reference when Jazz Club becomes active again |
| `ASSET_MANIFEST.md` | **CURRENT** | local asset install policy | Yes | Keep as-is |
| `RESCUE_NOTES.md` | **NOISE** | recovery scratch | n/a | Ignore |
| `debug-755971.log` | **NOISE** | leftover log | n/a | Ignore / delete in a cleanup pass |

## 2. Phase-report subfolders — currency table

### Foundational architecture audits (still useful)

| Folder | Verdict | Why it still matters |
|---|---|---|
| `docs/reports/mission_module_audit/` | **CURRENT** (still useful) | Established categories A–O, spaghetti risks, ownership map. Still the right framing. |
| `docs/reports/pre_taco_module_hardening/` | **MIXED** | Most items honored in code (dialogue boundary, tool surface helper, objective bridge name, stamina). **BUT** `phase0md1b_canonical_taco_scene_decision.md` says "canonical = `TacoBellIso_Editable.tscn`" — **superseded by D1C**. |
| `docs/reports/pre_taco_module_hardening_runtime/` | **MIXED** | RT2 reports correctly note canonical = Editable.tscn at the time. Now refers to a no-longer-canonical scene. |

### Recent reconciliation pass

| Folder | Verdict | Why it still matters |
|---|---|---|
| `docs/reports/taco_canonical_scene_correction/` | **CURRENT** | D1C — corrected the canonical/playable to `RedesignTest`. Resolver matches. |

### Mission foundation (sprint + bridges)

| Folder | Verdict | Why it still matters |
|---|---|---|
| `docs/reports/mission_foundation_d2/` | **STALE_BUT_FOUNDATIONAL** | Introduces sprint input map, bridges, pause provider. Code matches. |
| `docs/reports/mission_foundation_d2a_sprint_fix/` | **SUPERSEDED** | Re-do of sprint wiring. |
| `docs/reports/mission_foundation_d2a_fix1_sprint_runtime/` | **SUPERSEDED** | Intermediate fix. |
| `docs/reports/mission_foundation_d2a_fix2_sprint_runtime_debug/` | **CURRENT** | Final sprint runtime + debug overlay; validators PASS. |

### Taco redesign current plan

| Folder | Verdict | Why it still matters |
|---|---|---|
| `docs/reports/taco_bell_redesign_d4/` | **CURRENT** | Most recent, evidence-based plan. Recommends D5-01 (objective reset contract). |

### Character animation pipeline

| Folder | Verdict | Why it still matters |
|---|---|---|
| `docs/reports/character_animation_c2a/` | **SUPERSEDED** | Older pass. |
| `docs/reports/character_animation_c2b/` | **MIXED** | Contains the discovery; partially superseded by c2b_fix1. |
| `docs/reports/character_animation_c2b_fix1/` | **CURRENT** | Latest contextual-action classifier outputs. Not yet imported as SpriteFrames. |
| `docs/reports/character_sprite_replacement/` | **STALE_BUT_FOUNDATIONAL** | early decision record. |

### Hideout & art

| Folder | Verdict |
|---|---|
| `docs/reports/hideout_dialogue_portraits/` | **CURRENT** |
| `docs/reports/hideout_storefront_icons/` | **CURRENT** |
| `docs/reports/pvgames_catalog_paintable_palettes/` | **CURRENT** |
| `docs/reports/pvgames_catalog_paintable_verification/` | **CURRENT** |
| `docs/reports/pvgames_central_security_palettes/` | **CURRENT** |
| `docs/reports/pvgames_central_security_verification/` | **CURRENT** |
| `docs/reports/pvgames_editable_object_palette/` | **CURRENT** |
| `docs/reports/pvgames_icon_library/` | **CURRENT** |
| `docs/reports/pvgames_object_palette_dock/` | **CURRENT** |
| `docs/reports/pvgames_palettes/` | **STALE_BUT_FOUNDATIONAL** |
| `docs/reports/reveal_safety/` | **NOISE/CURRENT** — safe-mode utility |

## 3. Conflict matrix (the contradictions that matter)

| Conflict | Older report | Newer report / code | Truth | Action for future prompts |
|---|---|---|---|---|
| Canonical playable Taco scene | `pre_taco_module_hardening/phase0md1b_canonical_taco_scene_decision.md` says `TacoBellIso_Editable.tscn` | `taco_canonical_scene_correction/phase0md1c_canonical_taco_scene_correction.md` + `MissionSceneResolver.gd` say `TacoBellIso_Editable_RedesignTest.tscn` | **RedesignTest is canonical/playable** | Cite D1C, ignore D1B canonical decision |
| `taco_bell_drop` scene_path source of truth | `GameState.mission_catalog` says classic story room | Resolver overrides for `taco_bell_drop` | **Resolver wins for playable launches; catalog still drives non-launch paths** | Document the override; do not "fix" catalog without testing all consumers |
| Sprint input wiring | `mission_foundation_d2a_sprint_fix` + `_fix1_sprint_runtime` describe one path | `_d2a_fix2_sprint_runtime_debug` is final | **fix2 wins** | Cite fix2 only |
| README mission completion claims | `README.md` says 5 missions / 16 cards complete | Code has 1 playable mission | **README is wrong** | Rewrite or warn against the README |
| Triple objective writes | `mission_module_audit/spaghetti_risk_audit.json` flagged it | D4 spec still describes it as P0 | **Still open** | This is the P0 for D5-01 |

## 4. Whether D4 should still guide D5

**Yes, with one nuance.** D4 was design-only and evidence-based; its P0 list (attempt reset + objective truth + Louis bypass parity + validators) is still correct.

However, this roadmap audit suggests a small re-scoping:

- **D5-01 (P0)** — implement attempt reset + single objective writer — proceed exactly as D4 spec.
- **D5-02 (P0)** — pause payload Taco mission_id — proceed as D4 spec.
- **D5-03 (P0)** — Louis bypass parity — **defer one slot**: do D5-01 + D5-02 + a small **runtime smoke gate** before D5-03, because if reset is broken, bypass parity tests are meaningless.
- **D5-04/05** — keep as D4 outlined.

## 5. Whether the recent sprint conclusion is correctly reflected

**Yes.** `mission_foundation_d2a_fix2_sprint_runtime_debug` is the latest. Code matches: Ctrl primary + C fallback, `PlayerStaminaController` instance, parallel sprint debug overlay. Static validators passed. Runtime PASS was not claimed (GRB couldn't move the player synthetically — known harness limitation, not a gameplay bug).

## 6. Whether the Taco playable scene correction is consistently reflected

**Mostly yes.** `MissionSceneResolver`, `HideoutMissionBoardController`, `HideoutStationCatalog`, `IsoMissionDebugPanel._on_restart`, and `SceneManager.start_mission` all use the resolver. D1B docs still call Editable.tscn "canonical" though — **those reports should not be cited going forward without an explicit "(superseded)" note**.

## 7. Stale reports — quick action list

The following can be annotated (or referenced with a "superseded by …" pointer) but should NOT be deleted:

- `pre_taco_module_hardening/phase0md1b_canonical_taco_scene_decision.md` — superseded by `taco_canonical_scene_correction/phase0md1c_canonical_taco_scene_correction.md`.
- `mission_foundation_d2a_sprint_fix/`, `mission_foundation_d2a_fix1_sprint_runtime/` — superseded by `_fix2_sprint_runtime_debug`.
- `character_animation_c2a/`, `character_animation_c2b/` — partially superseded by `c2b_fix1`.
- `README.md` — needs a current-state rewrite (or a "STATUS: outdated" banner).

## 8. How future prompts should treat each layer

1. **Code in `src/`, scenes in `scenes/`, `project.godot`** — primary source of truth.
2. `taco_bell_redesign_d4/`, `taco_canonical_scene_correction/`, `mission_foundation_d2a_fix2_sprint_runtime_debug/` — current secondary truth.
3. `mission_module_audit/` — current framework framing.
4. `MISSION_BIBLE.md` — vision-level guidance.
5. Everything else under `docs/reports/` — historical context only.
6. `README.md` — do not trust until rewritten.

## 9. Hard assertions

- `documentation_reconciled`: **true**
- `stale_reports_identified`: **true**
- `conflicting_guidance_identified_or_none`: **true** (5 conflicts catalogued)

See `phase4_documentation_truth_reconciliation.json`.
