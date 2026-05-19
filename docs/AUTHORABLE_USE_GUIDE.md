# Authorable Use Guide

Practical guide for placing authored collectibles and interactables in mission scenes using drag-and-drop templates.

Templates are reusable starter nodes you drag into a mission scene. They are not automatically “smart” until you configure their IDs.

For taxonomy rules (one-shot vs countable, Case Cash policy), see also:
`docs/reports/d6_07b_authorable_standardization/D6_07B_AUTHORABLE_TAXONOMY_AND_PLACEMENT_GUIDE.md`

---

## Where the templates are

Templates live here:

`scenes/missions_iso/authoring_templates/`

Current templates:

- `PoopBagAuthorTemplate.tscn`
- `CaseCashAuthorTemplate.tscn`
- `ClueAuthorTemplate.tscn`
- `GlowGuyAuthorTemplate.tscn`

You use these inside mission scenes such as:

`scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

---

## Basic workflow

1. Open the mission scene in Godot.
2. Find the authoring area in the scene tree. For Taco, this is around the existing proof/authoring cluster, likely under something like `GameplayRoot/SecurityAuthoringRoot/CollectibleAuthoringProof`.
3. Drag a template `.tscn` from `scenes/missions_iso/authoring_templates/` into that authoring/proof node.
4. Move the new node where you want the collectible/interactable to appear in the level.
5. Rename the node to something readable, like `PoopBagBathroom01`.
6. In the Inspector, change all placeholder IDs to unique real IDs.
7. Run the validator (see [How to test](#how-to-test)).
8. Playtest and check F10.

---

## Important ID rule

Every placed authorable needs a **unique ID**. If you copy a poop bag five times, each one needs a different `collectible_id`.

**Good examples:**

- `taco_poop_bathroom_01`
- `taco_poop_bathroom_02`
- `taco_poop_parking_lot_01`

**Do not leave:**

- `CHANGE_ME_UNIQUE_ID`
- `TODO_ID`
- `collectible` (default placeholder)
- Empty IDs

Duplicate IDs are caught by the static validator and blocked at runtime (later duplicates may not spawn).

---

## How runtime works

When the mission starts, your placed author nodes are converted into real interactables.

The flow is:

```
Author template node in scene
  → runtime builder detects it
  → generated Phase0J-style interactable appears
  → player presses E/Q to collect
  → item becomes pending mission collection
  → mission success commits it
  → HideoutHub updates shelves / corkboard / Case Cash
```

You do **not** place the final runtime pickup directly. You place the authoring node, and the game builds the real interactable at runtime.

---

## How to place multiple poop bags

Yes, you can place multiple.

1. Drag `PoopBagAuthorTemplate.tscn` into the mission scene.
2. Rename it `PoopBagKitchen01`.
3. Set `collectible_id` to `taco_poop_kitchen_01`.
4. Duplicate the node.
5. Rename the duplicate `PoopBagKitchen02`.
6. Set the duplicate `collectible_id` to `taco_poop_kitchen_02`.

Each poop bag can use `poop_count = 1` (default).

---

## How to place Case Cash

Use `CaseCashAuthorTemplate.tscn` (preferred). Do not add new placements with the legacy money author unless you are maintaining an old scene node.

Set:

| Field | Purpose |
|-------|---------|
| `collectible_id` | Unique pickup ID, e.g. `taco_case_cash_register_01` |
| `case_cash_amount` | Amount awarded on **mission success** |
| `display_name` | Optional label, e.g. `Register Cash` |

Case Cash does **not** immediately add funds when picked up. It becomes pending and commits after mission success.

**Legacy note:** Older scenes may still reference `MoneyPickupAuthor`. That script is a compatibility alias and also commits as Case Cash. Prefer `CaseCashAuthorTemplate` for new work.

---

## How to place a clue

Use `ClueAuthorTemplate.tscn`.

Set:

| Field | Purpose |
|-------|---------|
| `collectible_id` | Unique placement ID |
| `clue_id` | Stable clue/corkboard ID |
| `clue_title` | Display name on the corkboard |
| `clue_text` | Optional detail text |
| `case_id` | Optional grouping (e.g. `the_big_case`) |
| `hideout_collection_key` | Only if you need a specific hideout flag override |

**Example:**

```
collectible_id: taco_clue_receipt_01
clue_id: clue_taco_receipt
clue_title: Suspicious Receipt
clue_text: A receipt linking Louis to the drop.
```

After mission success, it should appear on the corkboard if connected to existing hideout clue state.

---

## How to place a Glow Guy

Use `GlowGuyAuthorTemplate.tscn`.

Set:

| Field | Purpose |
|-------|---------|
| `collectible_id` | Unique placement ID |
| `glow_guy_id` | Stable shelf/display ID |
| `display_name` | Optional |
| `hideout_collection_key` | Optional override (default: `glow_guy_taco_bell`) |

**Example:**

```
collectible_id: taco_glow_guy_freezer_01
glow_guy_id: glow_guy_taco_freezer
```

After mission success, it should appear on the Glow Guy shelf if the hideout display key is wired correctly.

---

## Mission scene placement

Put authorables under the mission’s authoring/root area, not randomly under UI or unrelated nodes.

For Taco, use the existing proof/authoring area as your model (`CollectibleAuthoringProof` under `SecurityAuthoringRoot`). The important thing is that the runtime builder can discover the nodes. If you place them outside the expected authoring tree, they may not spawn.

The builder collects authors by walking the tree under `SecurityAuthoringRoot` (and nested children) for nodes that implement `is_collectible_author()`.

---

## How to test

After placing nodes:

1. Run the D6-07B validator:

   ```bash
   python src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py
   ```

2. Fix any duplicate, missing, or placeholder ID errors.
3. Run the mission scene in Godot.
4. Collect the item with normal player interaction (E/Q).
5. Open **F10** and confirm:
   - Pending counts by type
   - Pending Case Cash total and instance count
   - Last pickup ID/type
6. Complete the mission (e.g. talk to Louis on Taco).
7. Return to HideoutHub.
8. Confirm shelf, corkboard, and Case Cash updated as expected.

---

## Best practices

- Use **templates** for new placements.
- Use **copy/duplicate** only after you understand the ID rules (always change IDs on the copy).
- Give nodes readable scene names (`PoopBagKitchen01`, not `Node2D2`).
- Run the validator before playtesting a batch of new placements.
- For now, avoid placing authorables outside the known mission authoring area unless runtime discovery has been standardized for that mission scene.
- One authorable type per template — use the matching template for poop, Case Cash, clue, or Glow Guy.

---

## Quick reference: which template when

| You want | Template | Commits on success to |
|----------|----------|-------------------------|
| Poop bag pickup | `PoopBagAuthorTemplate.tscn` | Poop inventory / hideout display |
| Case Cash | `CaseCashAuthorTemplate.tscn` | HideoutHub spendable Case Cash |
| Evidence clue | `ClueAuthorTemplate.tscn` | Corkboard clue state |
| Glow Guy collectible | `GlowGuyAuthorTemplate.tscn` | Glow Guy shelf display |

---

## Related docs and tools

- Taxonomy and rules: `docs/reports/d6_07b_authorable_standardization/D6_07B_AUTHORABLE_TAXONOMY_AND_PLACEMENT_GUIDE.md`
- D6-07 implementation report: `docs/reports/d6_07_broader_interactable_authoring/D6_07_BROADER_INTERACTABLE_AUTHORING_REPORT.md`
- Validator: `src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py`
