# 0M-D5-00 — Phase 6: Louis bypass

## Router parity (STATIC_ONLY)

`Phase0JMechanicRouter.gd` maps **all** `ROUTE_*` categories to **`INSPECT_ONLY_DEFERRED`**:

- `route_marker` returns `real_mechanic_ran: false` for deferred categories (only `PARITY_IMPLEMENTED` would be true).

## Markers / layout (STATIC_ONLY + scene tree names)

- Runtime search found `RouteAccess_louis_delivery_route_future_shortcut` and related route markers under Taco scene tree (names consistent with Louis delivery shortcut intent).

## Gameplay effect

- **Louis route does not currently execute a distinct bypass mechanic** through `Phase0JMechanicRouter` — markers remain inspect-only with deferred parity.
- **Beam neutralization:** **NOT implemented** in router (no `PARITY_IMPLEMENTED` for ROUTE); any Louis beam story must live elsewhere or is **not active** — **STATIC_ONLY**.

## Runtime flags

- **NOT_TESTED** walking Louis route in this pass (movement automation unreliable).

## Conclusion

**Louis bypass is primarily marker/layout + inspect plumbing, not an active alternate mechanic** per `Phase0JMechanicRouter` source. Manual walk still useful to confirm no hidden side-channel.
