#!/usr/bin/env python3
"""Fix manifest paths for godot_project layout (no /out/ subdir)."""
import json
from pathlib import Path

MANIFEST = Path("/home/z/my-project/godot_project/data/city_manifest.json")

with open(MANIFEST) as f:
    manifest = json.load(f)

fixed = 0
for name, entry in manifest.items():
    old_path = entry["path"]
    # res://assets/buildings/out/bungalow.glb → res://assets/buildings/bungalow.glb
    new_path = old_path.replace("/out/", "/")
    if new_path != old_path:
        entry["path"] = new_path
        fixed += 1

with open(MANIFEST, 'w') as f:
    json.dump(manifest, f, indent=2)

print(f"Fixed {fixed} manifest paths (removed /out/ from path)")

# Re-verify
missing = []
for name, entry in manifest.items():
    rel_path = entry["path"].replace("res://", "")
    abs_path = Path("/home/z/my-project/godot_project") / rel_path
    if not abs_path.exists():
        missing.append((name, entry["path"]))

if missing:
    print(f"\n⚠ Still missing {len(missing)} GLBs:")
    for name, path in missing:
        print(f"    {name} → {path}")
else:
    print(f"\n✓ All {len(manifest)} manifest paths now resolve in godot_project/")
