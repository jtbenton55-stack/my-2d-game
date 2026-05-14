import json
from pathlib import Path

root=Path("docs/reports/d6_01_fix7_search_net_ambush_beam")
required=[
"phase0md6_01_fix7_safety_baseline.json",
"phase0md6_01_fix7_search_net_ai_audit.json",
"phase0md6_01_fix7_triangle_search_route_audit.json",
"phase0md6_01_fix7_ambush_beam_anchor_audit.json",
"phase0md6_01_fix7_search_net_handoff_fix.json",
"phase0md6_01_fix7_triangle_route_implementation.json",
"phase0md6_01_fix7_guard_performance_cleanup.json",
"phase0md6_01_fix7_ambush_beam_rebuild.json",
"phase0md6_01_fix7_f10_cleanup.json",
"phase0md6_01_fix7_heat_policy_non_regression.json",
"phase0md6_01_fix7_static_self_review.json",
"phase0md6_01_fix7_runtime_validation.json",
"phase0md6_01_fix7_final_report.json"
]
res={"missing":[],"parse_errors":[],"pass":True}
for f in required:
    p=root/f
    if not p.exists():
        res["missing"].append(f); res["pass"]=False; continue
    try:
        json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        res["parse_errors"].append({"file":f,"error":str(e)}); res["pass"]=False
(root/"phase0md6_01_fix7_static_validator_run.json").write_text(json.dumps(res,indent=2),encoding="utf-8")
print("PASS" if res["pass"] else "FAIL")
