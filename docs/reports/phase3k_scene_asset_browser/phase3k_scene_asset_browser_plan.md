# Phase 3K Scene/Asset Browser Plan

Date: 2026-06-09

## Goal

Phase 3K defines a larger Scene/Asset Browser that unifies proven project categories in a read/search/select/open workflow. It must help designers find existing resources without becoming a placement tool, generator, mission authoring palette, or category-invention surface.

## Source Rules

- Follow `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`, especially the Larger Scene/Asset Browser section.
- Do not let the larger browser become the first place where asset categories, target routes, or mechanic defaults are invented.
- Keep scope read/search/select/open only.
- Do not invent target routes, mechanic defaults, sequence formats, or asset taxonomies.
- Use only categories backed by current repo files.
- Mark legacy, diagnostic, review, or deferred entries honestly.

## Included Categories

| Category | Status | Source paths |
|---|---|---|
| PVGames objects | ready/read-only | `docs/reports/pvgames_editable_object_asset_index.json`, `docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json` |
| PVGames icons | ready/read-only | `docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json` |
| Mission authoring templates | ready/read-only | `scenes/missions_iso/authoring_templates/*.tscn`, `scenes/templates/IsoMissionTemplate.tscn` |
| Security templates | ready/read-only with caveats | `scenes/missions_iso/security_authoring_templates/*.tscn`, `docs/SECURITY_AUTHORABLES_GUIDE.md` |
| Animation maps | ready/read-only | `resources/character_animation_maps/*.json` |
| Preview SpriteFrames | review/legacy/read-only | `resources/character_animation_maps/generated_preview/*.tres` |
| Dev validation scenes | ready/read-only | `scenes/dev/**/*.tscn` |
| Validation reports | ready/read-only | `reports/ai/*.md`, selected `docs/reports/**/*.md`, selected validator run JSON files |

## Deferred Or Hidden By Default

| Candidate | Reason |
|---|---|
| Sequence templates | No real sequence template resources found yet. |
| Mission Authoring Palette plugin | Planned separately; not a real plugin category yet. |
| Mission Assist Browser plugin | Planned separately; not a real plugin category yet. |
| Idle guard template | Explicitly not implemented in security guide. |
| Alarm group template | Explicitly not implemented in security guide. |
| Door/keypad template | Audit-only today, not production-ready. |
| Sortable PVGames placement route | Phase 3J proved the rule, but palette route wiring is not implemented. |
| Raw asset folders | Too broad/noisy for Phase 3K; use existing indexes instead. |

## Browser Result Schema

The browser normalizes entries internally to:

```gdscript
{
    "id": "stable_id",
    "label": "Human readable name",
    "category": "pvgames_object | icon | authoring_template | security_template | animation_map | spriteframes_preview | validation_report | dev_scene",
    "status": "ready | review | legacy | diagnostic | deferred",
    "path": "res://...",
    "source": "index/report/template folder",
    "tags": [],
    "details": {},
}
```

## Initial UI Contract

- Title and status label.
- Search box.
- Category filter.
- Status filter.
- Source filter if useful after first prototype.
- Result count.
- Result list.
- Details panel.
- Safe action buttons only:
  - Refresh
  - Copy `res://` Path
  - Select In FileSystem
  - Open Scene / Resource when Godot editor APIs support it safely

Forbidden buttons in Phase 3K:

- Place
- Stamp
- Paint
- Generate
- Apply
- Promote
- Fix
- Create default
- Write index

## Implementation Shape

Initial skeleton lives under:

```text
addons/scene_asset_browser/
  plugin.cfg
  SceneAssetBrowserPlugin.gd
  SceneAssetBrowserDock.gd
```

The first pass keeps loading logic in the dock to stay small. Split into providers only if the dock becomes hard to maintain:

```text
addons/scene_asset_browser/providers/
  PVGamesObjectIndexProvider.gd
  IconCatalogProvider.gd
  TemplateProvider.gd
  AnimationMapProvider.gd
  ValidationReportProvider.gd
```

## Validation Plan

Static validator path:

```text
src/tools/editor/phase3k_scene_asset_browser/phase3k_scene_asset_browser_static_validator.py
```

Validator checks:

- Plugin files exist.
- Plugin extends `EditorPlugin` and adds/removes a dock.
- Dock is `@tool` and read-only.
- Expected source indexes exist.
- Exposed categories map to real source files.
- Deferred categories are not marked `ready`.
- Legacy `parmida_manual_preview_spriteframes.tres` is not marked ready.
- No write APIs are present in the dock.
- No production scenes, `project.godot`, or runtime scripts are required to change.

Manual editor validation:

1. Enable `Scene/Asset Browser` plugin.
2. Confirm the dock appears.
3. Search for a PVGames object.
4. Search for an icon.
5. Search for a security template.
6. Search for an animation map.
7. Search for the Phase 3J report.
8. Use Copy Path and Select In FileSystem.
9. Confirm no scene file changes after browsing.
10. Confirm no new Godot output errors.

## Safety Notes

- This browser is not a placement UI.
- It is not the Mission Authoring Palette.
- It is not the Mission Assist Browser.
- It does not replace focused tools such as PVGames Object Palette, Mission Paint Dock, or Character Animation Mapper.
- It should surface proven files and reports, not make design decisions.

## Completion Criteria

- Planning document exists.
- Read-only browser skeleton exists.
- Static validator passes.
- AI report records what was implemented and what remains deferred.
- `project.godot`, production scenes, player scripts, Taco scenes, and animation sandbox files are untouched.
