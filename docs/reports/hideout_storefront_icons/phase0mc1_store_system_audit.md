# Phase 0M-C1 Store System Audit

- Store station id: `store_terminal`
- Existing store script: `res://src/hideout/HideoutStoreController.gd`
- Existing fallback panel: `res://src/hideout/ScrollableStationPanel.gd`
- Store opening path: `HideoutInteractable -> HideoutManager.open_station('store_terminal')`
- Purchase function: `HideoutStoreController.purchase_placeholder(...) -> HideoutStateController.purchase_item(...)`
- Currency source: `HideoutStateController.case_cash`
- Owned storage: `purchased_store_items`, `delivered_store_items`, `owned_placeable_items`
- Available storage: `available_store_items`; 0M-C1 birthday catalog items are treated as enabled store items and are appended before calling the existing purchase method.

The existing store was functional but text-card/debug-feeling. 0M-C1 keeps the purchase path and adds a store-only icon storefront UI.
