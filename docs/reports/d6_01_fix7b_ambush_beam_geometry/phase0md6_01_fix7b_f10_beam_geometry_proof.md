# F10 beam geometry proof

`IsoMissionDebugPanel.gd` adds a **“FIX7B beam geometry”** subsection:

- Beam status (`fix7b_ambush_beam_status` fallback `beam_status`)
- Orientation (`fix7b_ambush_beam_orientation`)
- Beam center + center offset
- Height, visual width, trigger size
- FIX7B mismatch px

`_runtime_debug_summary()` exposes `fix7b_*` keys for the panel and any other consumers.

Policy strings unchanged: mid-run alarms; persistent heat only on mission failure (existing note).
