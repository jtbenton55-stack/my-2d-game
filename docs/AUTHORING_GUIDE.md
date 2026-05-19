# Authoring Guide

Canonical guide for placing authored mission content in the Godot editor.

Use this guide for collectible/interactable authoring. Use `docs/SECURITY_AUTHORABLES_GUIDE.md` for beams, cameras, patrol routes, triggers, and security event wiring.

## Current Pattern

Mission content should be authored as editor nodes, then converted into runtime nodes by mission builders.

Flow:

```text
Author node in scene
  -> runtime builder discovers it
  -> generated Phase0J-style interactable/security object appears
  -> player interacts or trips it
  -> mission records pending state
  -> successful completion commits persistent rewards/sync
```

Do not place final generated runtime pickups directly in scenes for new work. Place author nodes and let the runtime builders create gameplay nodes.

## Collectible Templates

Collectible templates live in:

```text
scenes/missions_iso/authoring_templates/
```

Current templates:

- `PoopBagAuthorTemplate.tscn`
- `CaseCashAuthorTemplate.tscn`
- `ClueAuthorTemplate.tscn`
- `GlowGuyAuthorTemplate.tscn`

Use these in mission scenes such as:

```text
scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn
```

## How To Place Collectibles

1. Open the mission scene in Godot.
2. Find the existing authoring area. For Taco, use `GameplayRoot/SecurityAuthoringRoot/CollectibleAuthoringProof` as the model.
3. Drag a template from `scenes/missions_iso/authoring_templates/` into the authoring/proof area.
4. Move it to the desired pickup/interact position.
5. Rename it clearly, such as `PoopBagBathroom01` or `CaseCashRegister01`.
6. Replace all placeholder IDs with stable unique IDs.
7. Run the relevant static validator.
8. Playtest and check F10 debug output.

## ID Rules

Every placed authorable needs a stable unique ID.

Required fields:

- All collectable authorables: `collectible_id`
- `PolaroidAuthor`: `polaroid_id`
- `TinyIconAuthor`: `icon_id`
- `GlowGuyAuthor`: `glow_guy_id`
- `ClueAuthor`: `clue_id`
- `CaseCashAuthor`: `collectible_id` plus positive `case_cash_amount`

Good IDs:

```text
taco_poop_bathroom_01
taco_case_cash_register_01
```

Avoid:

- Empty IDs.
- `CHANGE_ME_UNIQUE_ID`.
- `TODO_ID`.
- Reusing the same ID for different placements.
- Runtime-generated IDs for persistent pickups.

Duplicate IDs are blocked or skipped at runtime and should be caught by validators.

## Collectible Types

Unique one-shot unlocks:

- `polaroid`
- `tiny_icon`
- `glow_guy`
- `clue`

Countable or amount-based pickups:

- `poop_bag`
- `case_cash`

Every placed instance still needs its own unique `collectible_id`, even if the pickup is countable.

## Case Cash

Use `CaseCashAuthor` for mission currency.

Important fields:

| Field | Purpose |
|---|---|
| `collectible_id` | Unique placement ID, such as `taco_case_cash_register_01` |
| `case_cash_amount` | Amount awarded on mission success |
| `display_name` | Optional readable label |

Case Cash becomes pending during the mission and commits only after mission success. It should not add funds on failure/restart.

Legacy note: `MoneyPickupAuthor` is deprecated and acts as a compatibility alias for Case Cash. Prefer `CaseCashAuthor` for new work.

## Clues

Use `ClueAuthorTemplate.tscn`.

Important fields:

| Field | Purpose |
|---|---|
| `collectible_id` | Unique placement ID |
| `clue_id` | Stable clue/corkboard ID |
| `clue_title` | Display name on the corkboard |
| `clue_text` | Optional detail text |
| `case_id` | Optional case grouping |
| `hideout_collection_key` | Optional explicit hideout flag override |

After mission success, clues should appear in F10 pending/commit state and sync to the hideout evidence board when wired.

## Glow Guys

Use `GlowGuyAuthorTemplate.tscn`.

Important fields:

| Field | Purpose |
|---|---|
| `collectible_id` | Unique placement ID |
| `glow_guy_id` | Stable shelf/display ID |
| `display_name` | Optional readable label |
| `hideout_collection_key` | Optional explicit display key |

After mission success, Glow Guys should sync to the hideout shelf when wired.

## Poop Bags

Use `PoopBagAuthorTemplate.tscn`.

Important fields:

| Field | Purpose |
|---|---|
| `collectible_id` | Unique placement ID |
| `poop_count` | Count granted, usually `1` |

Multiple poop bags are supported. Each placed instance needs a unique ID.

## Security Authorables

Security templates live in:

```text
scenes/missions_iso/security_authoring_templates/
```

Use `docs/SECURITY_AUTHORABLES_GUIDE.md` for the full security workflow.

Current security templates include beams, cameras, event guard spawns, patrol routes, patrol waypoints, and area triggers.

## Validators

Current validator families:

- `src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py`
- `src/tools/editor/d6_07_broader_interactable_authoring/phase0md6_07_static_validator.py`
- `src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py`
- `src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py`

Older D6-06 validators that require `AuthoredCollectiblePickup.gd` are superseded by the Phase0J interactable path and should not guide new work.

## Runtime Expectations

For Taco today:

- The playable scene is `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Author nodes should be under the mission authoring tree, not random UI/runtime parents.
- Collectible builder discovery walks under `SecurityAuthoringRoot` and nested children for nodes that implement `is_collectible_author()`.
- F10 should show useful pending counts/logs for authored collectibles and security authorables.

## Future Direction

Keep mission authoring templates separate from playable mission scenes. Once authorables become mission-agnostic, prefer a dedicated shared template home such as `scenes/templates/mission_authoring/` rather than mixing templates with playable scenes.
