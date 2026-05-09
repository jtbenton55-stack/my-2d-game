# Phase 0M-C1 Hideout CyberCity Storefront Icons

**Status:** PASS

Neon Nook is a CyberCity-icon storefront for furniture, cozy decor, gadgets, plants, Bentley items, Jake gag items, Parmida/Mere birthday items, Louis delivery nonsense, and mission-room knick-knacks.

## Key Results

- Store item count: 39
- CyberCity icons used: 39
- Doomsday icons used: 0
- Doomsday exceptions: none
- Store station wired: yes (`store_terminal` opens `HideoutStorefrontPanel`)
- Purchase flow: integrated with existing `purchase_placeholder()` / `purchase_item()` / Case Cash path
- Source PNGs modified: no
- TileSets modified: no
- Collision modified: no
- Taco Bell scenes modified: no

## Theme Coverage

- Furniture / cozy hideout: 12/5 (PASS)
- Neon lights / signs / wall decor: 12/5 (PASS)
- Desk gadgets / terminals / screens: 13/4 (PASS)
- Plants / greenhouse / cozy items: 6/3 (PASS)
- Bentley items: 7/4 (PASS)
- Jake sweet-tooth / poop-bag / forgetfulness: 9/4 (PASS)
- Parmida/Mere birthday / kindness / soft-strength: 11/4 (PASS)
- Louis delivery nonsense: 6/3 (PASS)
- General heist / mission-room knick-knacks: 15/3 (PASS)

## Important Paths

- Item catalog: `res://data/store/birthday_store_items.json`
- Storefront scene: `res://scenes/ui/HideoutStorefrontPanel.tscn`
- Storefront script: `res://src/ui/HideoutStorefrontPanel.gd`
- Store controller: `res://src/hideout/HideoutStoreController.gd`
- Test scene: `res://scenes/hideout/tools/HideoutStorefrontIconTest.tscn`
- Curated icon report: `res://docs/reports/hideout_storefront_icons/phase0mc1_curated_store_icons.md`

## Manual Test Checklist

1. Open `HideoutHub.tscn`.
2. Run HideoutHub.
3. Walk to the store station and press E.
4. Confirm Neon Nook opens with CyberCity icon item cards.
5. Buy an affordable item and confirm Case Cash decreases and the button becomes Owned.
6. Confirm Jake/Mere/Bentley C3 dialogue still opens with portraits.
7. Confirm MissionBoard still launches Taco Bell.
8. Pause and exit back to HideoutHub.
