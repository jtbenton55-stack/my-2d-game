# 0M-D1C — Taco scene comparison (machine)

## Metrics

[
  {
    "path": "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "bytes": 706399,
    "ext_resource_count": 14,
    "node_line_count": 856,
    "has_phase0j": false,
    "has_phase0k": false,
    "has_redesign_test_in_path": false
  },
  {
    "path": "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "bytes": 1426838,
    "ext_resource_count": 39,
    "node_line_count": 1875,
    "has_phase0j": true,
    "has_phase0k": true,
    "has_redesign_test_in_path": true
  }
]

## Conclusion

{
  "old_or_smaller_scene": "scenes/missions_iso/TacoBellIso_Editable.tscn",
  "expanded_likely_scene": "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
  "confidence": "high",
  "evidence": [
    "Byte size ratio scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn vs scenes/missions_iso/TacoBellIso_Editable.tscn: 1426838/706399.000",
    "Node line counts: scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn=1875, scenes/missions_iso/TacoBellIso_Editable.tscn=856",
    "Phase0J/K substring markers present only on RedesignTest in this pair."
  ],
  "uncertainty": "If a future pass intentionally shrinks the expanded scene below Editable, re-run metrics."
}