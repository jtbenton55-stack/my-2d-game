# Phase 2 — Scheme card selection / equip / effect truth

## Storage

| Store | Owner | Contents |
|-------|--------|----------|
| `HideoutStateController` equipped_* fields | Hideout runtime | Planning Table slots: plan / trick / comfort_chaos |
| `GameState.current_scheme_loadout` | Autoload | Copied from hideout state when confirming mission start (`HideoutManager._write_scheme_loadout_to_game_state`) |
| `GameState.selected_cards` | Autoload | Legacy up-to-3 card picker (`SchemeCardMenu` → `GameState.set_selected_cards`) |
| `GameState.unlocked_cards` + `unlocked_scheme_cards` | Autoload | Unlocks / scheme registry |
| `CardManager` | Autoload | `.tres` card resources; `get_selected_cards()` reads **only** `GameState.selected_cards` |

## Why pause showed "equipped: none"

- `MissionSchemeBridge` only enumerated `CardManager.get_selected_cards()` → `selected_cards`.
- Hideout Planning Table **never wrote** into `selected_cards`; it wrote hideout loadout → `GameState` only on confirm launch (and **not** on some replay/legacy launch paths before fix).

## Effect application

- **`CardEffects.gd`** gates on `GameState.has_selected_card(...)` → **legacy `selected_cards` only**.
- **Taco iso placeholders** use `GameState.has_scheme_card` / unlock APIs — separate from loadout slots.
- **HideoutSchemeCardController** already states gameplay effects are placeholders.

## Classification (pre-fix → post-fix intent)

| Topic | Classification |
|-------|----------------|
| Loadout visible in pause | **STORED_BUT_NOT_VISIBLE_IN_PAUSE** → addressed by merging loadout into bridge snapshot |
| CardEffects / Taco gates | **VISIBLE_BUT_NOT_APPLIED** for most Planning Table cards until wired |
| `Engine.has_singleton` false negative | **BROKEN** diagnostic → **fixed** |
