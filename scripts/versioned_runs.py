#!/usr/bin/env python3
"""
Versioned plans — timestamp + hash every run into runs/run_NNN/.

DeepSeek: "Before the next tuning session, timestamp and hash every run into
runs/run_NNN/. Otherwise we lose the ability to answer 'did the fix help?'"

Each run gets its own directory with:
  - chunk_states.json — the dump from that run
  - fill_plan.json — the plan generated
  - metrics.json — the metrics
  - report.md — the analysis report
  - meta.json — timestamp, git hash, baseline problems, final problems, improvement %

Usage:
    from versioned_runs import RunManager
    rm = RunManager()
    run_dir = rm.start_run()
    rm.save_to_run(run_dir, "fill_plan.json", plan_data)
    rm.finalize_run(run_dir, baseline=8, final=6, actions=5)
"""
import json
import subprocess
import time
from pathlib import Path

RUNS_DIR = Path("/home/z/my-project/pz3d/runs")


class RunManager:
    """Manages versioned run directories with timestamps + git hashes."""
    
    def __init__(self):
        self.runs_dir = RUNS_DIR
        self.runs_dir.mkdir(parents=True, exist_ok=True)
    
    def get_next_run_number(self) -> int:
        """Find the next available run number (000, 001, 002, ...)."""
        existing = sorted(self.runs_dir.glob("run_*"))
        if not existing:
            return 0
        last = existing[-1].name.split("_")[1]
        return int(last) + 1
    
    def start_run(self) -> Path:
        """Create a new run directory + return its path."""
        run_num = self.get_next_run_number()
        run_dir = self.runs_dir / f"run_{run_num:03d}"
        run_dir.mkdir(parents=True, exist_ok=True)
        
        # Write meta.json with timestamp + git hash
        meta = {
            "run_number": run_num,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "unix_timestamp": int(time.time()),
            "git_hash": self._get_git_hash(),
            "git_branch": self._get_git_branch(),
        }
        (run_dir / "meta.json").write_text(json.dumps(meta, indent=2))
        return run_dir
    
    def save_to_run(self, run_dir: Path, filename: str, data):
        """Save data to a file in the run directory.
        Supports dict (JSON), str (text), or bytes."""
        path = run_dir / filename
        if isinstance(data, (dict, list)):
            path.write_text(json.dumps(data, indent=2))
        elif isinstance(data, str):
            path.write_text(data)
        elif isinstance(data, bytes):
            path.write_bytes(data)
        return path
    
    def copy_to_run(self, run_dir: Path, filename: str, source_path: Path):
        """Copy a file from source into the run directory."""
        import shutil
        dest = run_dir / filename
        shutil.copy2(source_path, dest)
        return dest
    
    def finalize_run(self, run_dir: Path, baseline: int, final: int,
                     actions: int, action_breakdown: dict = None):
        """Update meta.json with results + compute improvement."""
        meta_path = run_dir / "meta.json"
        if meta_path.exists():
            meta = json.loads(meta_path.read_text())
        else:
            meta = {}
        
        meta["baseline_problems"] = baseline
        meta["final_problems"] = final
        meta["improvement"] = baseline - final
        meta["improvement_pct"] = round((baseline - final) / baseline * 100, 1) if baseline > 0 else 0
        meta["total_actions"] = actions
        meta["action_breakdown"] = action_breakdown or {}
        meta["status"] = "improved" if final < baseline else ("no_change" if final == baseline else "worsened")
        
        meta_path.write_text(json.dumps(meta, indent=2))
        return meta
    
    def list_runs(self) -> list:
        """List all run directories with their metadata."""
        runs = []
        for run_dir in sorted(self.runs_dir.glob("run_*")):
            meta_path = run_dir / "meta.json"
            if meta_path.exists():
                meta = json.loads(meta_path.read_text())
                meta["run_dir"] = str(run_dir.relative_to(self.runs_dir))
                runs.append(meta)
        return runs
    
    def get_run(self, run_number: int) -> dict:
        """Get a specific run's metadata + contents."""
        run_dir = self.runs_dir / f"run_{run_number:03d}"
        if not run_dir.exists():
            return {}
        meta_path = run_dir / "meta.json"
        meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
        meta["run_dir"] = str(run_dir)
        meta["files"] = [f.name for f in run_dir.iterdir() if f.is_file()]
        return meta
    
    def compare_runs(self, run_a: int, run_b: int) -> dict:
        """Compare two runs — what changed between them."""
        meta_a = self.get_run(run_a)
        meta_b = self.get_run(run_b)
        return {
            "run_a": run_a,
            "run_b": run_b,
            "problems_a": meta_a.get("final_problems", "?"),
            "problems_b": meta_b.get("final_problems", "?"),
            "delta": (meta_b.get("final_problems", 0) or 0) - (meta_a.get("final_problems", 0) or 0),
            "actions_a": meta_a.get("total_actions", "?"),
            "actions_b": meta_b.get("total_actions", "?"),
            "status_a": meta_a.get("status", "?"),
            "status_b": meta_b.get("status", "?"),
            "git_hash_a": meta_a.get("git_hash", "?")[:7],
            "git_hash_b": meta_b.get("git_hash", "?")[:7],
        }
    
    @staticmethod
    def _get_git_hash() -> str:
        """Get the current git commit hash."""
        try:
            result = subprocess.run(
                ["git", "rev-parse", "HEAD"],
                capture_output=True, text=True, timeout=5,
                cwd=str(Path(__file__).parent.parent)
            )
            return result.stdout.strip() if result.returncode == 0 else "unknown"
        except Exception:
            return "unknown"
    
    @staticmethod
    def _get_git_branch() -> str:
        """Get the current git branch name."""
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True, text=True, timeout=5,
                cwd=str(Path(__file__).parent.parent)
            )
            return result.stdout.strip() if result.returncode == 0 else "unknown"
        except Exception:
            return "unknown"


# CLI: python3 scripts/versioned_runs.py [list|compare A B]
if __name__ == "__main__":
    import sys
    rm = RunManager()
    
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        runs = rm.list_runs()
        if not runs:
            print("No runs yet.")
        else:
            print(f"{'Run':>4} | {'Timestamp':<20} | {'Git':>7} | {'Baseline':>8} | {'Final':>5} | {'Impr':>5} | {'Status':<10}")
            print("-" * 80)
            for r in runs:
                print(f"{r.get('run_number', '?'):>4} | {r.get('timestamp', '?'):<20} | "
                      f"{str(r.get('git_hash', '?'))[:7]:>7} | "
                      f"{r.get('baseline_problems', '?'):>8} | "
                      f"{r.get('final_problems', '?'):>5} | "
                      f"{r.get('improvement_pct', 0):>4.1f}% | "
                      f"{r.get('status', '?'):<10}")
    
    elif sys.argv[1] == "compare" and len(sys.argv) >= 4:
        a, b = int(sys.argv[2]), int(sys.argv[3])
        diff = rm.compare_runs(a, b)
        print(json.dumps(diff, indent=2))
    
    elif sys.argv[1] == "show" and len(sys.argv) >= 3:
        run_num = int(sys.argv[2])
        run = rm.get_run(run_num)
        print(json.dumps(run, indent=2))
    
    else:
        print("Usage: python3 versioned_runs.py [list|compare A B|show N]")
        print("  list     — list all runs")
        print("  compare A B — compare run A vs run B")
        print("  show N   — show details of run N")
