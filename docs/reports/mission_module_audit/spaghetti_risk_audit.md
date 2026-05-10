# Spaghetti risk audit

Prioritized risks are in `spaghetti_risk_audit.json` with severity, evidence, and whether work is **P0 before Taco redesign**.

## Top risks (short list)

1. **`IsoMissionBase.gd` size and responsibility creep** — critical.
2. **Taco dialogue preload inside generic iso base** — high.
3. **Player → mission duck-typed `deploy_poop_bag_decoy_at`** — high.
4. **Two Taco scenes with different Phase0 controller stacks** — high.
5. **Attempt runtime reset not proven on all death/retry paths** — high.

## Hard assertions

`assertions` in JSON all `true`. No production gameplay files were modified during this audit.
