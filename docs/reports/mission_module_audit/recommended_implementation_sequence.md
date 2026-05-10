# Recommended implementation sequence

Machine-readable phases: `recommended_implementation_sequence.json`.

## Immediate next pass (copy into Cursor)

**PHASE 0M-D1b — Mission spine boundaries:** remove `TacoBellDialogue` preload from `IsoMissionBase` via injectable dialogue provider; replace Player poop duck-typing with `IToolMissionSurface` (or thin autoload); **decide and document** canonical Taco scene (`TacoBellIso_Editable` vs `TacoBellIso_Editable_RedesignTest`) and merge plan for Phase0J/K; add **stamina + sprint** as numeric hook without final animations; verify **attempt counter reset** on every supported restart path (add explicit reset if in-scene retry is a requirement).

## Priority legend

- **P0** — before Taco art-heavy redesign (framework boundaries).
- **P1** — during Taco redesign (UI + objectives + code gate UX alignment).
- **P2/P3** — after vertical slice (noise bus, heat module, CI polish).

## Hard assertions

JSON `assertions` all `true`.
