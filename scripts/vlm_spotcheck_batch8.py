#!/usr/bin/env python3
"""VLM spot-check 10 assets across categories."""
import subprocess, json, sys, os

# 10 assets to spot-check — 2 from each of 5 categories
SPOT_CHECKS = [
    # (category, asset_name, render_path, prompt)
    ("BUILDING",   "warehouse",     "/home/z/my-project/assets/buildings/renders/warehouse.png",
     "What building is shown? Is it clearly recognizable as a specific building type? Answer PASS or FAIL with one-line reasoning."),
    ("BUILDING",   "church_small",  "/home/z/my-project/assets/buildings/renders/church_small.png",
     "What building is shown? Is it clearly recognizable as a specific building type? Answer PASS or FAIL with one-line reasoning."),
    ("PROP-DYN",   "armchair",      "/home/z/my-project/assets/props/renders/armchair.png",
     "What piece of furniture is shown? Is it clearly recognizable? Answer PASS or FAIL with one-line reasoning."),
    ("PROP-DYN",   "ceiling_lamp",  "/home/z/my-project/assets/props/renders/ceiling_lamp.png",
     "What object is shown hanging from above? Is it clearly recognizable? Answer PASS or FAIL with one-line reasoning."),
    ("PROP-STAT",  "fireplace",     "/home/z/my-project/assets/props/renders/fireplace.png",
     "What object is shown? Is it clearly recognizable as a fireplace? Answer PASS or FAIL with one-line reasoning."),
    ("PROP-STAT",  "stove_freestanding", "/home/z/my-project/assets/props/renders/stove_freestanding.png",
     "What appliance is shown? Is it clearly recognizable as a kitchen stove? Answer PASS or FAIL with one-line reasoning."),
    ("FOLIAGE",    "palm_tree",      "/home/z/my-project/assets/foliage/renders/palm_tree.png",
     "What plant or tree is shown? Is it clearly recognizable as a palm tree? Answer PASS or FAIL with one-line reasoning."),
    ("FOLIAGE",    "mushrooms",      "/home/z/my-project/assets/foliage/renders/mushrooms.png",
     "What is shown? Is it clearly recognizable as a cluster of mushrooms? Answer PASS or FAIL with one-line reasoning."),
    ("ENV",        "traffic_light",  "/home/z/my-project/assets/environment/renders/traffic_light.png",
     "What object is shown? Is it clearly recognizable as a traffic light? Answer PASS or FAIL with one-line reasoning."),
    ("ENV",        "bench_park",     "/home/z/my-project/assets/environment/renders/bench_park.png",
     "What object is shown? Is it clearly recognizable as a park bench? Answer PASS or FAIL with one-line reasoning."),
]

results = []
for cat, name, path, prompt in SPOT_CHECKS:
    if not os.path.exists(path):
        print(f"X {cat}/{name}: missing render at {path}")
        results.append((cat, name, "FAIL", "missing render"))
        continue
    try:
        out = subprocess.run(
            ["z-ai", "vision", "-p", prompt, "-i", path],
            capture_output=True, text=True, timeout=60
        )
        text = out.stdout
        # Find the JSON content section
        start = text.find("{")
        if start >= 0:
            json_text = text[start:]
            data = json.loads(json_text)
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "(no content)")
        else:
            content = "(no JSON in output)"
        # Determine pass/fail from content
        is_pass = "PASS" in content.upper().split("FAIL")[0]
        status = "PASS" if is_pass else "FAIL"
        results.append((cat, name, status, content.strip()))
        print(f"[{status}] {cat}/{name}: {content.strip()[:200]}")
    except Exception as e:
        results.append((cat, name, "FAIL", str(e)))
        print(f"X {cat}/{name}: {e}")

print("\n=== VLM SPOT-CHECK SUMMARY ===")
passes = sum(1 for r in results if r[2] == "PASS")
fails = sum(1 for r in results if r[2] == "FAIL")
print(f"PASS: {passes}/{len(results)}, FAIL: {fails}/{len(results)}")
