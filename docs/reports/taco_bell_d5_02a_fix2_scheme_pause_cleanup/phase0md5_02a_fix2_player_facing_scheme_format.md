# Phase 2 — Player-facing scheme format

- **Title:** "Scheme Cards for This Run"
- **Per equipped card:** display name (catalog / card resource / Title Case), `Slot: Plan|Trick|Comfort / Chaos`, `Status: Equipped`, honest **Bonus:** line using `GameState.has_selected_card(id)` as the only “may apply” signal.
- **Empty:** "No scheme cards equipped…" + Planning Table hint.
- **Separate mission card list:** Only if `legacy_selected_card_ids` contains IDs not in loadout slots — player language, no internal API names.
- **Excluded from pause:** Autoload names, `CardEffects`, `has_scheme_card`, raw ID dumps, merged/unlocked ID lists.
