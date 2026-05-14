# FIX7A Marker Anchor Audit
- ASSERT marker_anchor_audit_completed == true
- ASSERT ambush_marker_location_identified_or_missing_reported == true
- ASSERT authoring_marker_failure_explained == true
- ASSERT fallback_coordinate_usage_identified == true

## Findings
1. `Debug_AMBUSH_security_beam` exists in canonical scene under `GameplayRoot/GeneratedRuntimeMarkerDebugInteractables`.
2. Node type: Area2D.
3. Has `marker_id = "AMBUSH_security_beam"` and metadata marker_id.
4. Label twin exists under `GameplayRoot/GeneratedRuntimeMarkerLabels/Label_AMBUSH_security_beam`.
5. `_find_authoring_marker()` fails because authoring index scans marker roots requiring `marker_type`; generated runtime debug markers are not indexed there.
6. Prior beam code still contained legacy fallback paths and stale visuals from earlier FIX passes.
