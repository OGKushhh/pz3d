#!/usr/bin/env python3
"""Bulk-register all .glb assets under godot_project/assets/ that aren't yet in
city_manifest.json. Adds entries with category derived from the directory name
(buildings/ → building, props/ → prop, characters/ → character, components/ → component,
foliage/ → foliage, decals/ → decal). Existing entries are preserved.

Run: python3 /home/z/my-project/pz3d/scripts/register_all_glbs.py
"""
import json
import os
from pathlib import Path

ASSETS_DIR = Path("/home/z/my-project/pz3d/godot_project/assets")
MANIFEST_PATH = Path("/home/z/my-project/pz3d/godot_project/data/city_manifest.json")

# Map directory name → manifest category
DIR_TO_CATEGORY = {
    "buildings": "building",
    "props": "prop",
    "characters": "character",
    "components": "component",
    "foliage": "foliage",
    "decals": "decal",
    "vehicles": "vehicle",
    "environment": "environment",
    "roads": "road",
}


def main():
    # Load existing manifest
    with open(MANIFEST_PATH) as f:
        manifest = json.load(f)
    initial_count = len(manifest)
    print(f"Manifest has {initial_count} entries")

    # Walk assets dir, find all .glb files
    new_count = 0
    for root, dirs, files in os.walk(ASSETS_DIR):
        rel_root = Path(root).relative_to(ASSETS_DIR)
        # Skip empty root
        if str(rel_root) == ".":
            continue
        # Get the top-level category dir name
        top_dir = str(rel_root).split("/")[0]
        category = DIR_TO_CATEGORY.get(top_dir, "misc")
        # Res path
        for fname in files:
            if not fname.endswith(".glb"):
                continue
            asset_name = fname[:-4]  # strip .glb
            if asset_name in manifest:
                continue  # already registered
            # Build the res:// path
            rel_path = Path("assets") / rel_root / fname
            res_path = "res://" + str(rel_path).replace("\\", "/")
            manifest[asset_name] = {
                "path": res_path,
                "category": category,
            }
            new_count += 1
            print(f"  + {asset_name} ({category}) → {res_path}")

    # Write back
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")

    print(f"\nAdded {new_count} new entries. Manifest now has {len(manifest)} entries (was {initial_count}).")


if __name__ == "__main__":
    main()
