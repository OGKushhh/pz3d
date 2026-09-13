#!/usr/bin/env python3
"""
AI Multi-Pass Loop — orchestrates the dump → analyze → apply → re-dump → compare cycle.

DeepSeek's Tier 1 priority: "Use len(problems) as your score — you already
detect 71 problems, that number IS your objective. Apply actions → re-dump →
re-analyze → if problem count dropped, keep; if not, revert and try a different
plan. Stopping rule: 'no improvement for 2 consecutive iterations.' That single
loop is what turns this from 'AI acts' into 'AI improves.'"

Loop:
  1. Run godot --headless → dumps chunk_states_auto.json (iteration N baseline)
  2. Run ai_fill_planner.py → analyzes + writes fill_plan.json + ai_metrics.json
  3. Run godot --headless again → applies fill_plan + re-dumps (iteration N+1)
  4. Compare metrics: did total_problems decrease?
     - Yes: keep plan, iterate
     - No: increment no_improvement counter
  5. Stop after 2 consecutive non-improving iterations

Each godot run is a fresh session — chunks load fresh, apply the current
fill_plan, dump state, exit. The multi-pass script orchestrates these runs.

Usage: python3 /home/z/my-project/pz3d/scripts/ai_multi_pass.py [max_iterations]
"""
import json
import subprocess
import sys
import shutil
from pathlib import Path

REPO = Path("/home/z/my-project/pz3d")
GODOT = "/home/z/my-project/tools/Godot_v4.7.2-stable_linux.x86_64"
GODOT_PROJECT = REPO / "godot_project"
PLANNER = REPO / "scripts" / "ai_fill_planner.py"
DUMP_PATH = GODOT_PROJECT / "chunk_states_auto.json"
PLAN_PATH = GODOT_PROJECT / "fill_plan.json"
METRICS_PATH = GODOT_PROJECT / "ai_metrics.json"
BACKUP_PATH = GODOT_PROJECT / "fill_plan.backup.json"

def run_godot_headless():
    """Run godot --headless to dump chunk states (applies current fill_plan if exists)."""
    cmd = [
        GODOT, "--headless",
        "--path", str(GODOT_PROJECT),
        "--quit-after", "300"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    return result.stdout + result.stderr

def run_planner():
    """Run the AI planner to analyze + generate fill_plan + metrics."""
    result = subprocess.run(
        ["python3", str(PLANNER)],
        capture_output=True, text=True, timeout=60
    )
    return result.stdout + result.stderr

def read_metrics():
    """Read ai_metrics.json. Returns None if not found."""
    if not METRICS_PATH.exists():
        return None
    return json.loads(METRICS_PATH.read_text())

def backup_plan():
    """Backup the current fill_plan.json so we can restore if iteration worsens."""
    if PLAN_PATH.exists():
        shutil.copy2(PLAN_PATH, BACKUP_PATH)

def restore_plan():
    """Restore the previous fill_plan.json from backup."""
    if BACKUP_PATH.exists():
        shutil.copy2(BACKUP_PATH, PLAN_PATH)
        print("  ↳ restored previous plan from backup")

def main():
    max_iterations = int(sys.argv[1]) if len(sys.argv) > 1 else 5
    print(f"=== AI MULTI-PASS LOOP (max {max_iterations} iterations) ===\n")

    # === ITERATION 0: BASELINE (no plan applied) ===
    print("[iter 0] BASELINE — running godot with no fill_plan...")
    if PLAN_PATH.exists():
        PLAN_PATH.unlink()  # ensure no plan for baseline
    run_godot_headless()
    if not DUMP_PATH.exists():
        print("ERROR: baseline dump failed")
        sys.exit(1)
    run_planner()
    baseline_metrics = read_metrics()
    if not baseline_metrics:
        print("ERROR: baseline metrics failed")
        sys.exit(1)
    baseline_problems = baseline_metrics["total_problems"]
    print(f"  baseline problems: {baseline_problems}")
    print(f"  baseline actions generated: {baseline_metrics['total_actions']}\n")

    # === ITERATION LOOP ===
    best_problems = baseline_problems
    best_plan_backup = None
    no_improvement_streak = 0

    for iteration in range(1, max_iterations + 1):
        print(f"[iter {iteration}] applying plan + re-dumping...")

        # Backup current plan before applying (so we can restore if worse)
        backup_plan()

        # Run godot — applies current fill_plan + dumps new state
        run_godot_headless()

        # Run planner — analyzes new state + generates NEW plan for next iteration
        run_planner()
        new_metrics = read_metrics()
        if not new_metrics:
            print("  ERROR: metrics failed, stopping")
            break

        current_problems = new_metrics["total_problems"]
        improvement = best_problems - current_problems
        print(f"  problems: {current_problems} (was {best_problems}, {'↓' if improvement > 0 else '↑' if improvement < 0 else '='} {abs(improvement)})")
        print(f"  actions: {new_metrics['total_actions']} "
              f"(removes: {new_metrics['action_type_counts'].get('remove', 0)}, "
              f"repositions: {new_metrics['action_type_counts'].get('reposition', 0)}, "
              f"fills: {new_metrics['action_type_counts'].get('fill', 0)})")

        if current_problems < best_problems:
            # Improved — keep this plan, update best
            best_problems = current_problems
            no_improvement_streak = 0
            print(f"  ✓ IMPROVED — keeping plan (best={best_problems})\n")
        else:
            # Not improved — restore previous + increment streak
            no_improvement_streak += 1
            print(f"  ✗ NO IMPROVEMENT (streak={no_improvement_streak}/2)")
            if no_improvement_streak >= 2:
                print("  stopping — 2 consecutive non-improving iterations\n")
                break
            print("  reverting to previous plan\n")
            restore_plan()

    # === SUMMARY ===
    print("=== MULTI-PASS COMPLETE ===")
    print(f"  Baseline problems:  {baseline_problems}")
    print(f"  Final problems:     {best_problems}")
    improvement = baseline_problems - best_problems
    pct = (improvement / baseline_problems * 100) if baseline_problems > 0 else 0
    print(f"  Improvement:         {improvement} problems ({pct:.1f}% reduction)")
    print(f"  Iterations run:     {iteration}")
    print(f"\n  Best fill_plan saved at: {PLAN_PATH}")
    print(f"  Metrics at:          {METRICS_PATH}")
    print(f"  Report at:           {REPO}/docs/ai_analysis_report.md")

if __name__ == "__main__":
    main()
