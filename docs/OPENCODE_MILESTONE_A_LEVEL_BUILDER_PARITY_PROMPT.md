# OpenCode Prompt — Milestone A: Level Builder Parity (Grouped Packet)

How to use: paste everything below the line into OpenCode (ChatGPT 5.5) as a single prompt. It is self-contained. It follows `docs/Prompt_Improvement.md` conventions and is written for autonomous start-to-finish execution.

---

```text
Before doing any work, read and follow the repo-local `AGENTS.md`. It is the highest-priority project source of truth for workflow, scope, permissions, validation requirements, reporting requirements, and handoff rules. If this prompt conflicts with `AGENTS.md`, follow `AGENTS.md` and report the conflict.

Also read `docs/Prompt_Improvement.md` and treat it as mandatory supplemental operating context. If it conflicts with `AGENTS.md`, follow `AGENTS.md`.

You are working in Jake's Godot 4.6.2 project. The only authorized writable workspace is:

`C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game`

Do not access, modify, delete, rename, move, print, or expose any file outside this repository. Do not read `.env` files, credentials, API keys, tokens, SSH folders, browser data, or shell history. Do not commit, push, pull, stage, change branches, rebase, reset, stash, or alter git history — Jake has NOT asked for a commit in this packet. Do not modify `project.godot` or autoload registrations except where this prompt explicitly authorizes it (it does not; if you believe a `project.godot` change is unavoidable, stop that sub-task, leave it undone, and document why).

Your priorities, in order:
1. Protect Jake's computer, private files, and unrelated data.
2. Protect the existing working game (especially canonical Taco Bell flow).
3. Preserve modular architecture and prevent spaghetti code.
4. Preserve the plug-and-play mission authoring architecture:
   `Placed mechanic node -> RequirementSet checks -> EffectSet applies -> thin bridge/adapters -> existing authoritative managers`
5. Successfully implement this packet.
6. Verify with LSP diagnostics, GdUnit4 tests, static validators, and Godot runtime/playtest checks.
7. Use the `ask_kimi_k2_6` MCP advisory tool (if available) as a second-brain reviewer, never as an unquestioned authority, and never send it secrets or files outside the repo.
8. Report honestly what changed, what was tested, what passed, what failed, and what remains risky.

======================================================================
MISSION STATEMENT
======================================================================

This packet is "Milestone A — Level Builder Parity". Its purpose: after this packet, Jake must be able to create a brand-new mission scene, register it with ONE catalog dictionary entry, place EVERY authorable mechanic type (including security, collectibles, scheme cards, hide spots, presentation, player start, teleport, and music zones) through the Mission Dock, press play, and have all placed systems actually run — with no mission-ID-gated code silently ignoring his scene and no edits to resolver or runtime scripts required per mission.

This is a grouped milestone under the repo's accelerated grouped-milestone mode. It has four implementation workstreams (A1–A4) and one validation workstream (A5). Complete all of them in one autonomous pass. If a workstream proves unstable, fall back per `AGENTS.md` (finish the stable workstreams, document the unstable one precisely), but do not silently skip anything.

======================================================================
CONTEXT SNAPSHOT AND FUTURE-PROOFING RULE
======================================================================

The facts below were verified on 2026-07-05 but the project evolves quickly. Treat them as a starting map, NOT guaranteed truth. Before editing each file, re-inspect it and confirm the described code still exists. Line numbers are approximate; search by function name and code pattern, never by line number alone.

Verified facts:

- Canonical playable Taco scene: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (mission id `taco_bell_drop`). Phase0J/Phase0K remain authoritative for canonical bag/manifest-code/Louis flow. Preserve them completely.
- `src/levels/IsoMissionBase.gd` (very large, ~4400+ lines) contains mission-runtime setup functions gated on `mission_id == "taco_bell_drop"`. Known gated functions (verify each):
  - `_ensure_d5_attempt_security_beam_runtime()` (~line 320)
  - `_apply_layout_profile()` (~line 664) — calls `_apply_taco_bell_layout_profile()`
  - `_ensure_d6_fix5_runtime_helpers()` (~line 2698) — removes Taco test-warp/stale-beam nodes
  - `_setup_d6_03_authoring_security_runtime()` (~line 2758)
  - `_setup_d6_06_collectible_authoring_runtime()` (~line 2782)
  - `_setup_fix7_ambush_beam_runtime()` (~line 4376)
  - const `D6_02_SECURITY_AUTHORING_ROOT_PATH := "GameplayRoot/SecurityAuthoringRoot"` (~line 91)
  - `_find_security_authoring_root()` (~line 4254)
  - const `PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS: Array[String] = ["taco_bell_drop"]` (~line 99) with a comment forbidding additions without design review.
- `src/missions/MissionSceneResolver.gd` (~67 lines, `class_name MissionSceneResolver`, static funcs, not an autoload) hardcodes taco and corner store playable scene constants and returns them from `resolve_playable_scene_path()`.
- `src/autoload/GameState.gd` has `var mission_catalog: Dictionary` (~line 14) with entries shaped like:
  `{"name": ..., "description": ..., "scene_path": ..., "reward_cards": [], "reward_polaroids": [], "friend": ""}`
  and helper funcs `get_mission_info()`, `get_mission_scene_path()`.
- `addons/mission_dock/MissionDock.gd` (~1785 lines) has `MECHANIC_TYPES` (38 entries) and `MECHANIC_SCRIPTS`, typed-coordinate placement plus a "Place With Mouse" arming flow, forbidden-parent checks, "Ensure MissionMechanics Parent" logic, and an Assist Browser audit tab with readiness checks. Static validator: `src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`.
- Types with runtime code and tests that are NOT currently in the dock catalog (verify): `SchemeCardTriggerNode`, `HideSpotNode`, `PresentationSequencePlayer`, the six security authorables (`SecurityBeamAuthor`, `SecurityCameraAuthor`, `GuardSpawnAuthor`, `GuardPatrolRouteAuthor`, `AreaTriggerAuthor`, `SecurityEffectSetAuthor`), and the four collectible authors (PoopBag, CaseCash, Clue, GlowGuy variants of `CollectibleAuthorBase`).
- Template locations: mechanic templates under `scenes/missions/iso/authoring/` (~31 files); security templates under `scenes/missions_iso/security_authoring_templates/` (8 files); collectible templates under `scenes/missions_iso/authoring_templates/` (4 files). Missing templates for dock types `SearchZone`, `RewardNode`, `ExtractionZone`, `TriggerZone`, `SideObjectiveNode`, `InteractiveContainer` (verify).
- Bare mission shell template: `scenes/templates/IsoMissionTemplate.tscn`. Richer starter: `scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn`.
- GdUnit4 suite: `tests/mission_authoring/` — approximately 328 passing tests at last count. Get the actual current baseline count yourself before editing and report it.
- Corner Store Cashout (`corner_store_cashout`, `scenes/missions_iso/CornerStoreCashout_Editable.tscn`) is PARKED by Jake's decision. Do not repair, extend, or QA it. Do not break it either; it must still load.

Do not assume any roadmap-named system exists. Verify every class/scene/resource before using it.

======================================================================
SCOPE
======================================================================

IN SCOPE (this packet):
- A1: De-gate mission runtime setup in `IsoMissionBase.gd` from `mission_id == "taco_bell_drop"` to scene-content-driven activation.
- A2: Data-driven mission registration (catalog field + resolver rewrite + dock readiness check).
- A3: Complete the Mission Dock palette (existing strays + security + collectibles) and add three new thin authorables (PlayerStartMarker integration, TeleportZone, MusicTriggerZone) with templates and tests.
- A4: Placement quality-of-life in the dock (mechanic_id auto-suggestion, sticky placement mode).
- A5: Validation — GdUnit, LSP, static validators, Taco regression, a non-Taco security-runtime smoke, a `MilestoneAProofMission` scene prepared for Jake's manual session, report, and Nowledge Mem handoff.

OUT OF SCOPE (do NOT do these, even if tempting):
- Corner Store Cashout repair or QA.
- Guard investigation/pathfinding AI.
- Editor gizmo overlays, graph audit rules, Inspector string pickers (future Milestone B slices).
- Mission Result/rating work, controller input, prompt-glyph work (future Milestone C).
- Any new global manager or autoload. Any parallel mission file format.
- Drag-from-dock-to-viewport rewrite of the placement flow. Extend the existing "Place With Mouse" arming flow only.
- Renaming/moving existing nodes, scenes, exported properties, signals, flags, or resources unless a sub-task explicitly requires it.

======================================================================
WORKSTREAM A1 — DE-GATE MISSION RUNTIME (IsoMissionBase.gd)
======================================================================

Goal: security, collectible, and beam authoring runtimes must activate in ANY mission whose scene contains the authoring content, not only `taco_bell_drop`.

Required approach — scene-content gating:

1. Read each target function COMPLETELY before changing it. For each, produce (in your working notes and final report) a two-column split: (a) generic authorable logic, (b) Taco-specific literals (hardcoded node names, marker names, hallway labels, taco flags, `pp_taco_*` strings, Phase0J/0K references).
2. `_setup_d6_03_authoring_security_runtime()`: remove the `mission_id != "taco_bell_drop"` early return. The remaining natural gate is already present: `_find_security_authoring_root()` returning non-null AND `runtime_enabled` being true on that root. Keep the `mission_definition == null` null-guard.
3. `_setup_d6_06_collectible_authoring_runtime()`: same de-gating. IMPORTANT: this function currently sets `_attempt_runtime_state["d6_06_authoring_root_found"] = false` on the mission-ID early return. Preserve the state-reporting semantics: scenes WITHOUT a security authoring root must still record `false` exactly as before; scenes WITH a root (any mission) now proceed.
4. `_setup_fix7_ambush_beam_runtime()` and `_ensure_d5_attempt_security_beam_runtime()`: these are the highest-risk functions. The fix7 function is described as a "canonical AMBUSH beam rebuild" that "prefers hand-placed SecurityBeamAuthor when enabled". De-gate ONLY the hand-placed-`SecurityBeamAuthor` path so authored beams work in any mission. If the function contains a Taco-specific fallback rebuild path (hardcoded positions/names for the Taco ambush beam), keep that fallback behind an explicit `mission_id == "taco_bell_drop"` check. The physics_frame signal connect/disconnect handling in `_ensure_d5_attempt_security_beam_runtime()` must remain correct for both Taco and non-Taco missions — trace every connect/disconnect pair.
5. Keep FULLY Taco-gated (do not de-gate): `_ensure_d6_fix5_runtime_helpers()` (Taco cleanup), `_apply_layout_profile()` / `_apply_taco_bell_layout_profile()` (inherently Taco), and `PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS` (explicit design-review comment — do not touch).
6. Search `IsoMissionBase.gd` for ALL other occurrences of `"taco_bell_drop"` beyond the functions listed above. For each occurrence, classify it: (a) canonical Phase0J/0K/story logic — leave untouched; (b) authorable-runtime gating missed by this prompt — de-gate it using the same scene-content pattern and document it; (c) unclear — leave untouched and document. Do not guess.
7. If the same `mission_id == "taco_bell_drop"` guard pattern appears 3+ times among the de-gated functions, you may extract ONE small private helper (e.g. `_has_enabled_security_authoring_root() -> bool`) — but do not build any broader abstraction.

Tests for A1 (new GdUnit tests under `tests/mission_authoring/`, following the existing test style in that folder):
- A non-Taco `IsoMissionBase` scene (built in-test or via a minimal fixture scene) containing a `GameplayRoot/SecurityAuthoringRoot` with `runtime_enabled = true` and at least one security author child: assert the runtime setup produces the same observable state keys/nodes it produces for Taco (inspect what `_setup_d6_03_authoring_security_runtime()` actually creates/records and assert on that).
- A non-Taco scene WITHOUT a security root: assert no security runtime is built and no errors occur.
- Do not weaken or delete any existing Taco test.

======================================================================
WORKSTREAM A2 — DATA-DRIVEN MISSION REGISTRATION
======================================================================

Goal: registering a new playable iso mission = one dictionary entry in `GameState.mission_catalog`. No per-mission edits to `MissionSceneResolver.gd` ever again.

Exact design (smallest reversible version — no manifest resource, no autoload, no scene scanning):

1. In `src/autoload/GameState.gd`, add an OPTIONAL key `"playable_iso_scene"` to catalog entries. Populate it for exactly two existing entries:
   - `taco_bell_drop`: `"res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"`
   - `corner_store_cashout`: `"res://scenes/missions_iso/CornerStoreCashout_Editable.tscn"`
   Do not change any other key of any entry. Do not change `scene_path` values (they are the classic/fallback paths and other systems may read them).
2. Rewrite `src/missions/MissionSceneResolver.gd` internals while PRESERVING its public API exactly (same class_name, same static function names, same signatures, same return shapes — other code and tests call these):
   - `resolve_playable_scene_path(mission_id, _context)`: return the catalog entry's `playable_iso_scene` when present and non-empty; otherwise `GameState.get_mission_scene_path(mission_id)`.
   - `get_debug_scene_path(mission_id)`: same rule (playable-iso from catalog, else default).
   - `get_scene_roles(mission_id)`: populate `playable_expanded_iso` from the catalog field for any mission that has it. The Taco-only `legacy_bake_output` and `classic_story_room` values may remain constants applied when `mission_id == "taco_bell_drop"` (they are historical Taco facts, not per-mission data).
   - `is_legacy_scene_path(path)`: leave behavior unchanged.
   - `get_resolution_report(mission_id)`: keep the existing Taco warning; add a generic warning when a catalog entry has a `playable_iso_scene` whose file does not exist (`ResourceLoader.exists`).
3. Mission Dock Assist Browser: add ONE new readiness check row — "Mission registration". Determine how the audit currently identifies the open scene's mission id (inspect how the dock reads the scene root / mission definition; use the same mechanism — do not invent a new one). The check passes when: the mission id exists in `GameState.mission_catalog` AND the entry's `playable_iso_scene` resolves to the currently open scene's file path. It reports a clear actionable failure message otherwise (e.g. "mission_id 'x' has no catalog entry" / "catalog playable_iso_scene points at a different file"). If the open scene has no detectable mission id, report that state honestly rather than passing or crashing.

Tests for A2:
- GdUnit: `resolve_playable_scene_path("taco_bell_drop")` still returns the RedesignTest path; `corner_store_cashout` still returns its path; an unknown mission id falls back to `GameState.get_mission_scene_path`; a temporary catalog entry injected in-test with `playable_iso_scene` resolves to it; `get_resolution_report` warns on a nonexistent playable path.
- Search the repo for every caller of `MissionSceneResolver` and every test referencing the old constants; update tests ONLY if they asserted implementation details (constants) rather than behavior. Report each such change.

======================================================================
WORKSTREAM A3 — COMPLETE THE MISSION DOCK PALETTE
======================================================================

Goal: every authorable the game supports is placeable from the Mission Dock with a safe parent, sensible defaults, and a template.

A3.1 — Add existing types to the dock catalog (no new runtime code):

1. Add to `MECHANIC_TYPES` / `MECHANIC_SCRIPTS` (and any per-type metadata structures — study how the 38 existing entries are defined and mirror the pattern exactly, including any category/grouping, default-size, and required-field metadata):
   - `SchemeCardTriggerNode`, `HideSpotNode`, `PresentationSequencePlayer`, `DisruptionActionNode` if genuinely absent (verify each first — the snapshot says they are absent but confirm).
   - The six security authorables: `SecurityBeamAuthor`, `SecurityCameraAuthor`, `GuardSpawnAuthor`, `GuardPatrolRouteAuthor`, `AreaTriggerAuthor`, `SecurityEffectSetAuthor`.
   - The four collectible authors (use the actual class/template names found in `scenes/missions_iso/authoring_templates/`).
2. Parenting rules: mechanics parent under the existing `MissionMechanics` container (existing "Ensure MissionMechanics Parent" logic). Security authorables must parent under `GameplayRoot/SecurityAuthoringRoot` instead — implement an "ensure SecurityAuthoringRoot parent" path that mirrors the MissionMechanics logic (create the root at `GameplayRoot/SecurityAuthoringRoot` if missing, with `runtime_enabled` defaulting to `true` and any other exports matching the Taco scene's root configuration — inspect the Taco scene to copy correct defaults). Collectible authors: inspect where the Taco/authoring scenes parent them and follow that existing convention.
3. Respect and extend the existing forbidden-parent checks for the new types.
4. Where a placed type has a template scene, instantiate the template; where it doesn't, instantiate script-on-node with defaults the way the dock already does — follow the dock's existing precedent per type.

A3.2 — New thin authorables (the ONLY new runtime code in this packet). For each: a small typed-GDScript script in the same folder/pattern as existing mechanics, a template `.tscn` under `scenes/missions/iso/authoring/`, a dock entry, and GdUnit tests.

1. `PlayerStartMarker`:
   - FIRST inspect how `IsoMissionBase` currently determines the player spawn position (the `MARKER_CATEGORIES` array includes "Spawns" — find the consuming code). 
   - If an existing spawn-marker convention exists, do NOT invent a new node type; instead make the dock place a correctly-named/grouped marker node that the existing spawn logic already consumes, and document the convention.
   - Only if no consumable convention exists: create a minimal `PlayerStartMarker` (Marker2D-based) and add the smallest possible hook in `IsoMissionBase` spawn logic to prefer it when present, preserving current behavior when absent.
2. `TeleportZone` + `TeleportTargetMarker`:
   - `TeleportZone` extends `MechanicAreaBase` (follow an existing simple subclass like `TriggerZone` as the structural model). Exports: `target_marker_path: NodePath`, plus the standard `RequirementSet`/`EffectSet`/prompt fields inherited from the base.
   - Behavior: on successful activation (requirements pass through the standard base flow — do NOT bypass the base class), move the player node to the target marker's global position. Find the player the same way other mechanics/bridges do (inspect `MissionInteractionBridge` / existing mechanics for the established player-lookup pattern; reuse it).
   - Apply its `EffectSet` after teleporting (standard base behavior) so authors can set flags on teleport use.
   - Null-safety: missing/invalid target marker logs a clear warning via the project's existing debug path and does nothing (no crash, no partial teleport).
   - `TeleportTargetMarker` is a trivial Marker2D-based node (or plain Marker2D with a group — choose whichever matches project conventions; prefer the simplest that the dock can place and the zone can reference).
3. `MusicTriggerZone`:
   - FIRST inspect the Phase 12 presentation/audio bridge (search for the presentation audio bridge class used by `PresentationSequencePlayer`) and any existing music/audio manager or bus conventions.
   - The zone extends `MechanicAreaBase`. Exports: whatever minimal identifier the existing audio seam consumes (e.g. a track/state key string) plus an `on_exit_restore: bool`.
   - Behavior: on player enter (or activation — match whichever the audio design supports most simply), request the music change through the EXISTING audio seam. Do not create a music manager, autoload, or new bus. If no usable seam exists after inspection, implement the minimal self-contained version (an `AudioStreamPlayer` child with an exported stream, play on enter, optional stop/restore on exit) and explicitly document in the report that a proper music-system seam was absent.

A3.3 — Missing templates for existing dock types:
- Create template `.tscn` files under `scenes/missions/iso/authoring/` for: `SearchZone`, `RewardNode`, `ExtractionZone`, `TriggerZone`, `SideObjectiveNode`, `InteractiveContainer` (verify each is really missing first). Model them on the existing templates in that folder: same node structure conventions, same default export values, same collision shape conventions, placeholder `mechanic_id` values following whatever placeholder convention existing templates use.
- Wire the dock to prefer these templates for those types if that matches how other templated types are placed.

Tests for A3:
- GdUnit for `TeleportZone` (requirements-gated teleport happens; blocked when requirements fail; missing target is safe), `MusicTriggerZone` (enter triggers the seam call or player; exit restores when configured), and the player-start behavior you implemented.
- Extend `src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py` so it knows the new catalog size and any new parenting rules, and keep it passing.
- A dock-level test or validator check that every `MECHANIC_TYPES` entry has a resolvable script (and template where declared).

======================================================================
WORKSTREAM A4 — PLACEMENT QUALITY-OF-LIFE (Mission Dock)
======================================================================

1. `mechanic_id` auto-suggestion: when the dock places a mechanic that has a `mechanic_id`-style export, pre-fill it as `<mission_id>.<type_snake>.<nn>` where `<mission_id>` is the open scene's mission id (same detection as the A2 readiness check; fall back to `"mission"` when undetectable), `<type_snake>` is the snake_case type name, and `<nn>` is the lowest two-digit number that makes the id unique among nodes already in the scene. Never leave whatever `CHANGE_ME`-style placeholder the current flow produces when a real suggestion is computable. Keep the field fully editable — this is a default, not a lock.
2. Sticky placement mode: after a successful "Place With Mouse" placement, keep the same mechanic type armed so the next click places another instance (with a freshly incremented suggested id). Escape (or whatever cancel affordance the arming flow already has) disarms. Add a visible dock indicator of the armed state if one doesn't exist. Preserve the existing dry-run/report semantics of the arming flow, and preserve undo hygiene: each placement must remain ONE UndoRedo entry.
3. Do not restructure the dock UI beyond these two features.

======================================================================
WORKSTREAM A5 — VALIDATION, PROOF SCENE, REPORT, HANDOFF
======================================================================

Pre-edit baseline (do this FIRST, before any edit):
- [ ] `git status --short --branch`; record branch, modified/untracked files. Do not touch pre-existing dirty files beyond your scope.
- [ ] Run the full `tests/mission_authoring/` GdUnit suite once and record the exact baseline pass count.
- [ ] Run the Phase 2K dock static validator once; record baseline result.
- [ ] Search Nowledge Mem (HTTP API at `http://127.0.0.1:14242` via `Invoke-RestMethod`, per `AGENTS.md`, if the `nmem` CLI is unavailable) for recent Milestone A / level-builder / mission-dock handoffs and read the 3 most recent relevant files in `reports/ai/`.

Post-implementation validation (all required unless technically blocked; document any blocker honestly):
- [ ] Godot LSP diagnostics clean on every modified/created `.gd` file.
- [ ] Full `tests/mission_authoring/` suite: exact pass/fail counts vs baseline. All new tests pass, no previously-passing test fails.
- [ ] All existing Python static validators that cover touched systems still pass (at minimum: phase2k mission dock, any security/taco validators found under `src/tools/editor/`).
- [ ] TACO REGRESSION (critical): launch `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` via Godot MCP Pro (or headless fallback). Verify: scene loads with no new errors; player spawns and moves; canonical bag pickup, manifest/code clue, and Louis exit nodes still present; security runtime builds exactly as before (compare `_attempt_runtime_state` keys and the generated security nodes against pre-change behavior); `PlugAndPlayPilot` chain intact; `MissionInteractionBridge.include_legacy_candidates` unchanged; no double-interaction between Phase0J bridge and the pilot bridge. Screenshot evidence into a task folder under `reports/ai/`.
- [ ] NON-TACO SECURITY SMOKE (the core proof of A1): create `scenes/dev/mission_authoring/MilestoneASecuritySmoke.tscn` (or reuse a suitable existing dev scene) — an `IsoMissionBase`-derived scene with a NON-taco mission id containing a `SecurityAuthoringRoot` (runtime_enabled = true) with at least one camera author, one beam author, and one guard spawn + patrol route. Run it; verify the security runtime builds, the camera/beam/guard exist at runtime, and tripping a beam or camera raises the same alert/event behavior as in Taco. Screenshot evidence.
- [ ] Corner Store still LOADS without new errors (load-only check; no QA, no fixes beyond load-breakage you yourself caused).
- [ ] MainMenu global smoke: `res://scenes/MainMenu.tscn` loads with no new autoload/parse/scene errors.
- [ ] Editor smoke for the dock: with the Godot editor open, confirm the dock lists all new types, places at least one security authorable (auto-creating `SecurityAuthoringRoot`), one collectible author, one `TeleportZone`, and shows the A2 registration readiness row. Use Godot MCP Pro editor tools; if editor control is unavailable, document the limitation and provide the exact manual steps Jake should run instead.

Jake's proof scene (deliverable, not optional):
- Create `scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: duplicate/derive from `scenes/templates/IsoMissionTemplate.tscn`, give it mission id `milestone_a_proof`, add a catalog entry (with `playable_iso_scene`) so it launches, and leave it INTENTIONALLY SPARSE — a small painted floor area and nothing else — because Jake's manual session is to place everything himself via the docks. Clearly mark it dev-only (follow the existing dev-scene conventions; it must not enter story progression — do not add it to `available_missions` defaults).

Final report — write `reports/ai/2026-XX-XX_milestone_a_level_builder_parity_report.md` (real date) following the full report format in `docs/Prompt_Improvement.md` (goal, files inspected, files changed, audit findings incl. the A1 generic-vs-taco split per function, implementation choices, systems preserved, exact test counts, MCP/LSP/GdUnit/DAP results, screenshots, Kimi usage, safety confirmation, rollback plan per workstream, known limitations, next step). Include this MANUAL QA CHECKLIST for Jake verbatim at the end:

  Milestone A manual session (~30–45 min):
  1. Open MilestoneAProofMission in the editor. Assist Browser "Mission registration" row is green.
  2. Paint a floor, walls, and a collision barrier with the Mission Paint Dock.
  3. From the Mission Dock place: PlayerStartMarker, ExtractionZone, one SearchZone -> RewardNode -> RouteUnlockNode chain, a SchemeCardTriggerNode, a HideSpotNode, a TeleportZone + target, a MusicTriggerZone, one collectible author, and (security) one camera, one beam, one guard spawn + patrol route. Confirm sticky placement and auto-suggested mechanic_ids.
  4. Audit tab shows no CHANGE_ME ids and no parenting errors.
  5. Press play from the mission board/dev launch. Verify: spawn at marker; music changes in zone; beam/camera trip raises alert; guard patrols the route; collectible collects; teleport moves the player; extraction completes the mission and returns to hideout.
  6. Launch Taco and play the canonical route for 5 minutes. Nothing regressed.

Nowledge Mem handoff (required by AGENTS.md): after finishing, save (or PATCH an existing related memory if creation is blocked) a handoff titled around "Milestone A level builder parity" containing: files changed, exact test counts before/after, validator results, Taco regression evidence summary, known risks, and the recommended next step (Jake's manual proof session, then Milestone B authoring + parallel slices: gizmos, prompt unification, graph audit rules, fact/ID pickers). Do NOT commit anything to git.

======================================================================
KIMI K2.6 SECOND-BRAIN USAGE (if `ask_kimi_k2_6` is available)
======================================================================

Recommended calls (advisory only; sanitize payloads per `docs/Prompt_Improvement.md` — no secrets, no full-repo dumps, short curated excerpts only):
1. Before editing A1: send the full text of `_setup_fix7_ambush_beam_runtime()` and `_ensure_d5_attempt_security_beam_runtime()` with the de-gating plan; ask for regression risks and missed Taco literals.
2. After implementation: send the diff summary of `IsoMissionBase.gd` changes; ask for a regression-risk review focused on Phase0J/0K and runtime init order.
Reconcile Kimi's advice against actual repo facts and runtime evidence. Report what was adopted or rejected. If the tool is unavailable, note that and proceed.

======================================================================
DECISION RULES AND FAILURE HANDLING
======================================================================

- Work autonomously start to finish. Do not stop to ask Jake questions unless a sub-task is impossible, unsafe, or contradictory; make the safest reasonable assumption and document it.
- Audit first, then implement. The audit is not a stopping point.
- Smallest safe change wins every tie. Reuse existing patterns; copy the structural style of the nearest existing peer (mechanic, template, test, validator) rather than inventing a new style.
- If A1's beam functions prove too entangled to de-gate safely within this packet: de-gate D6-03 (security) and D6-06 (collectibles) fully, leave the beam functions Taco-gated, and document exactly why plus the recommended follow-up slice. That is an acceptable fallback; silent partial work is not.
- If any single workstream fails validation and cannot be fixed, revert THAT workstream's edits (each workstream must remain independently revertible — keep diffs per workstream cleanly separable) and report it. Never leave the repo in a state where Taco or the test suite is broken.
- One user-visible dock action = one UndoRedo entry. No exceptions.
- Typed GDScript, clear naming, no magic values, no giant functions, comments only for non-obvious intent.
```
