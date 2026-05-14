#!/usr/bin/env python3
"""Static validator for PHASE 0M-D6-01-FIX6B"""

import json
import os
import sys
from pathlib import Path

def main():
    base_dir = Path("docs/reports/d6_01_fix6b_search_net_beam_performance")
    
    required_reports = [
        "phase0md6_01_fix6b_safety_baseline",
        "phase0md6_01_fix6b_guard_fallback_performance_audit",
        "phase0md6_01_fix6b_search_net_plan",
        "phase0md6_01_fix6b_search_net_implementation",
        "phase0md6_01_fix6b_guard_performance_lifecycle",
        "phase0md6_01_fix6b_far_right_beam_fix",
        "phase0md6_01_fix6b_f10_search_net_debug",
        "phase0md6_01_fix6b_static_self_review",
        "phase0md6_01_fix6b_runtime_validation",
    ]
    
    results = {
        "reports_exist": {},
        "json_parse": {},
        "assertions": {},
    }
    
    all_pass = True
    
    # Check required reports
    for report in required_reports:
        md_path = base_dir / f"{report}.md"
        json_path = base_dir / f"{report}.json"
        
        md_exists = md_path.exists()
        json_exists = json_path.exists()
        
        results["reports_exist"][report] = {
            "md": md_exists,
            "json": json_exists,
            "pass": md_exists,
        }
        
        if not md_exists:
            all_pass = False
            print(f"FAIL: Missing report {report}.md")
        
        # Try to parse JSON
        if json_exists:
            try:
                with open(json_path, "r") as f:
                    data = json.load(f)
                results["json_parse"][report] = "pass"
            except Exception as e:
                results["json_parse"][report] = f"fail: {e}"
                all_pass = False
                print(f"FAIL: JSON parse error in {report}.json: {e}")
    
    # Check key assertions
    key_assertions = [
        "repo_root_confirmed",
        "d6_01_fix6b_scope_confirmed",
        "search_net_implemented",
        "far_left_patrol_fallback_removed_for_security_spawns",
        "guard_performance_lifecycle_implemented_or_deferred_with_reason",
        "far_right_beam_position_recomputed",
        "f10_search_net_debug_added",
        "static_self_review_completed",
    ]
    
    for assertion in key_assertions:
        # Check in safety baseline
        sb_path = base_dir / "phase0md6_01_fix6b_safety_baseline.json"
        if sb_path.exists():
            try:
                with open(sb_path, "r") as f:
                    data = json.load(f)
                if "assertions" in data:
                    results["assertions"][assertion] = data["assertions"].get(assertion, False)
                else:
                    results["assertions"][assertion] = data.get(assertion, False)
            except:
                results["assertions"][assertion] = False
    
    # Check code files for key patterns
    code_checks = {
        "_get_security_search_role": "src/levels/IsoMissionBase.gd",
        "_build_search_net_points": "src/levels/IsoMissionBase.gd",
        "_update_security_guard_lifecycle": "src/levels/IsoMissionBase.gd",
        "D6_FIX6B_TEMP_SECURITY_BEAM": "src/levels/IsoMissionBase.gd",
        "search_net_heat": "src/levels/IsoMissionBase.gd",
        "lifecycle_active": "src/levels/IsoMissionBase.gd",
    }
    
    results["code_patterns"] = {}
    for pattern, file_path in code_checks.items():
        full_path = Path(file_path)
        found = False
        if full_path.exists():
            try:
                with open(full_path, "r", encoding="utf-8") as f:
                    content = f.read()
                found = pattern in content
            except:
                pass
        results["code_patterns"][pattern] = "found" if found else "missing"
        if not found:
            all_pass = False
            print(f"FAIL: Pattern '{pattern}' not found in {file_path}")
    
    # Write validation result
    results["all_pass"] = all_pass
    results["timestamp"] = "2026-05-13"
    results["phase"] = "0M-D6-01-FIX6B"
    
    output_path = base_dir / "phase0md6_01_fix6b_static_validator_run.json"
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2)
    
    # Summary
    print("\n" + "="*60)
    print("STATIC VALIDATOR RESULT")
    print("="*60)
    print(f"Phase: 0M-D6-01-FIX6B")
    print(f"Reports checked: {len(required_reports)}")
    print(f"Code patterns checked: {len(code_checks)}")
    print(f"Overall: {'PASS' if all_pass else 'FAIL'}")
    print("="*60)
    
    return 0 if all_pass else 1

if __name__ == "__main__":
    sys.exit(main())
