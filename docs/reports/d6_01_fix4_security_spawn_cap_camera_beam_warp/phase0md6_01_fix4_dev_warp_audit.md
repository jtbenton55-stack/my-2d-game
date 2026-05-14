# Dev warp visibility audit

## Instantiation

- `IsoMissionBase.call_deferred("_ensure_d6_fix4_test_helpers")` → `_setup_d6_fix4_garage_code_test_warp`.

## Gating (previous gap)

- Previously required **`dev_harness_enabled`** only; scene export could disable harness → **no warp**.

## Visibility gap

- **`Label`** under **`Area2D`** does not render as a world-space HUD; primary fix is **`Polygon2D`** purple fill.

## Placement

- Near **`start_main`** spawn + **(96, 0)** offset under **`EntityRoot/DynamicProps`**.

## Destination

- **`MissionDevTestWarp.resolve_garage_warp_position`** targets generated SAFE_CODE_INPUT_ZONE.

See `phase0md6_01_fix4_dev_warp_audit.json`.
