# Next Repo And Scene Organization Steps

This roadmap starts from the cleanup branch after `cleanup up batch #1` and the Cursor post-cleanup regression result:

```text
PASS_WITH_KNOWN_PREEXISTING_ISSUES
```

Backup branch:

```text
backup/pre-cleanup-2026-05-19
```

Cleanup branch:

```text
cleanup/repo-organization-2026-05-19
```

## Current Safety Baseline

- MainMenu, HideoutHub, and playable Taco opened/ran in Cursor validation.
- Taco still resolves to `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- D6-07, D6-07B, and D6-08A validators passed.
- GdUnit D6-06 passed after cleanup.
- No cleanup-caused regressions were found.
- Known separate issue: D6-06B validator fails on missing `D6_06_CaseCash_LegacyAlias_Author`; treat as scene/validator drift, not a repo cleanup blocker.

## Remaining Low-Risk Repo Cleanup Slices

Do these before medium/high-risk gameplay or scene-node cleanup.

### 1. Generated Report Ignore Policy

Goal: prevent future generated GdUnit folders from becoming tracked clutter.

Recommended actions:

- Add/confirm `.gitignore` entry for `reports/report_*/`.
- Keep important test summaries in `reports/ai/` or `docs/reports/<phase>/`.
- Do not rely on generated HTML report folders as source of truth.

Risk: very low.

### 2. MCP Bisect Shim/Stub Quarantine

Goal: remove MCP bisection artifacts from the active autoload folder.

Candidate files:

- `src/autoload/GameState_McpBisectShim.gd`
- `src/autoload/GameState_McpBisectShim.gd.uid`
- `src/autoload/GameState_McpBisectStub.gd`
- `src/autoload/GameState_McpBisectStub.gd.uid`

Recommended actions:

- Verify no references in `project.godot`, `src/`, `scenes/`, and active tooling reports.
- Move to a clearly named debug harness archive, such as `src/tools/debug_harnesses/mcp_bisect/`.
- Add README explaining they are not active autoloads and are kept only for MCP playmode bisection history.

Risk: low-medium.

### 3. Authoring Template Boundaries

Goal: make template folders visibly separate from playable mission scenes.

Recommended actions:

- Add README files under:
  - `scenes/missions_iso/authoring_templates/`
  - `scenes/missions_iso/security_authoring_templates/`
- Explain these are drag/drop authoring templates, not playable scenes.
- Document when future shared templates should move to `scenes/templates/mission_authoring/`.

Risk: very low.

### 4. Docs/Reports Index

Goal: make it obvious which reports are historical and which docs represent current truth.

Recommended actions:

- Add `docs/reports/README.md`.
- Explain phase reports vs current docs vs generated test reports.
- Point current readers to:
  - `docs/AUTHORING_GUIDE.md`
  - `docs/REPO_ORGANIZATION_GUIDE.md`
  - `docs/REPORTING_AND_BACKUP_POLICY.md`
  - latest relevant `reports/ai/` summaries.

Risk: very low.

### 5. Superseded Validator Archive Or Stronger Classification

Goal: stop old validators from misleading future cleanup/feature work.

Candidate folders:

- `src/tools/editor/d6_06_collectible_authoring/`
- `src/tools/editor/d6_06b_collectible_physical_pickup/`

Recommended options:

- Lowest risk: keep in place and improve README/classification.
- Slightly higher but still low-medium: move to `src/tools/editor/_superseded/phase_history/` after reference scans.

Do not delete yet.

Risk: low-medium.

## Medium/High-Risk Cleanup After Low-Risk Slices

Only start these after another runtime validation pass.

### 1. Deprecated Runtime Pickup Quarantine

Candidate:

- `src/missions/iso/runtime/AuthoredCollectiblePickup.gd`

Why risky:

- Current runtime uses `AuthoredPhase0JInteractablePickup.gd`, but older validators/reports still reference the deprecated file.

Do first:

- Retire or archive stale validator expectations.
- Run reference scans.
- Run GdUnit and current validators.

### 2. Taco Scene Variant Classification

Candidates:

- `TacoBellIso_Editable.tscn`
- `TacoBellIso_Editable_Test.tscn`
- `TacoBellIso_Editable2.tscn`
- `TacoBellIsoBlockout.tscn`
- `TacoBellIsoHandEditTest.tscn`

Why risky:

- Bake helpers, old validators, and docs still reference these.

Recommended action:

- Keep until every bake/test/tooling reference is understood.
- Prefer README classification over movement/deletion.

### 3. Hideout Tool Scene Rationalization

Candidates:

- `scenes/hideout/tools/`
- `scenes/hideout/tests/`

Why risky:

- Cursor found active tooling references.

Recommended action:

- Do not delete.
- Classify active tools vs historical review scenes.
- Validate with Godot editor before any move.

### 4. `IsoMissionBase.gd` Modularization

Why risky:

- Central mission orchestration with broad runtime dependencies.

Future seams:

- Mission lifecycle.
- Authoring runtime setup.
- Security runtime setup.
- Completion/exit flow.
- Debug panel setup.
- Marker/debug generation.

Do not do this as cleanup. Treat as a separate refactor feature with full runtime parity checks.

### 5. D6-06B Validator / Taco Proof Drift

Known issue:

```text
Taco scene missing proof node D6_06_CaseCash_LegacyAlias_Author
```

Treat as gameplay/validator follow-up, not cleanup. Decide whether to restore the proof node, update validator expectations, or document the drift.

## Godot Scene / Node Decluttering Plan

The repo cleanup does not significantly improve the Godot Scene tree clutter inside open scenes. Scene/node decluttering should be separate and safer than moving/deleting nodes.

The preferred approach is visibility organization, not deletion.

### Phase 1. Audit-Only Scene Tree Visibility Map

Goal: classify what must remain visible to run/play the game and what can be hidden with the eye icon.

Scenes to inspect first:

- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `scenes/hideout/HideoutHub.tscn`

Classify nodes as:

- Must stay visible for gameplay/readability.
- Safe-to-hide visual/editor clutter.
- Debug/proof visibility optional.
- Runtime/generated parent; do not hide without validation.
- Nonvisual manager/helper; visibility not relevant.
- Unknown/risky; leave as-is.

No scene edits in this phase.

### Phase 2. Build A Visibility Toggle Plan

Goal: produce a checklist Cursor can apply later.

For each candidate node, record:

- Scene path.
- Node path.
- Current visibility.
- Proposed visibility.
- Reason.
- Reference-scan result.
- Risk level.
- Required validation.

Avoid hiding parents unless every child is safe to hide.

### Phase 3. Apply Only Low-Risk Visibility Changes

Safe first candidates:

- Debug labels.
- Proof labels.
- Editor annotation labels.
- Clearly visual-only guide markers.
- Review-only palette/helper visuals.

Do not hide yet:

- `GameplayRoot`
- `SecurityAuthoringRoot`
- `RuntimeSystems`
- `GeneratedRuntimeInteractables`
- `RuntimeHelpers`
- `MarkerRoot`
- `Phase0KMissionCompletionController`
- Hideout manager paths.
- PVG paint/depth layers.
- Any node with a script or exact path references unless validated.

### Phase 4. Validate After Every Small Visibility Batch

Use Cursor/Godot MCP Pro to validate:

- Scene opens.
- Scene runs.
- Runtime tree still has expected systems.
- No missing-node/path/resource errors.
- Screenshots before/after if visual output changes.
- MainMenu -> Hideout -> Taco smoke if visibility batch affects playable content.

### Phase 5. Optional Manual Playtest

Jake should manually test:

- Mission board opens.
- Taco launches.
- Player can move.
- One authored pickup can be collected.
- Louis/exit flow still works.
- Hideout sync display updates after return.

## Suggested Next Prompt Topic

When ready, ask Cursor for:

```text
Audit-only Godot scene visibility classification for TacoBellIso_Editable_RedesignTest.tscn and HideoutHub.tscn. Do not edit scenes. Produce must-stay-visible, safe-to-hide, and unknown-risk node lists with validation evidence.
```
