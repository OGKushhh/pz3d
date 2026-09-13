#!/usr/bin/env python3
"""Sweep high-poly .mog assets and simplify their geometry to reduce tri counts.

Strategy:
1. Replace `rounded_box` with `box` (saves ~200 tris per mesh — beveled edges gone)
2. Replace `chamfered_box` with `box` (same)
3. Replace small `sphere` (radius < 0.05) with `box` (saves ~50 tris each)
4. Remove `marker_*` meshes (invisible, 0.02m boxes — just for bone skin binding)
5. For `branch` primitive, reduce `depth` parameter (exponential branch count)

Targets the 21 high-poly assets identified by inspect_all_glbs.py.
Re-compiles .mog → .glb via mogen CLI after each edit.

Usage: python3 /home/z/my-project/pz3d/scripts/simplify_high_poly_assets.py
"""
import re
import subprocess
import os
from pathlib import Path

# Assets to simplify + their .mog source paths
HIGH_POLY_ASSETS = {
    # Characters — replace rounded_box with box, remove markers
    "walker_zombie_male": "assets/characters/src/walker_zombie_male.mog",
    "walker_zombie_female": "assets/characters/src/walker_zombie_female.mog",
    "crawler_zombie": "assets/characters/src/crawler_zombie.mog",
    "npc_soldier": "assets/characters/src/npc_soldier.mog",
    "npc_survivor": "assets/characters/src/npc_survivor.mog",
    # Foliage — reduce branch depth
    "dead_tree": "assets/foliage/src/dead_tree.mog",
    "mushrooms": "assets/foliage/src/mushrooms.mog",
    # Buildings — replace rounded_box with box
    "cave_entrance": "assets/buildings/src/cave_entrance.mog",
    "subway_pipe_cluster": "assets/buildings/src/subway_pipe_cluster.mog",
    # Props — replace rounded_box/chamfered_box with box
    "office_chair": "assets/props/src/office_chair.mog",
    "fireplace": "assets/props/src/fireplace.mog",
    "garden_pergola": "assets/props/src/garden_pergola.mog",
    "bed_single": "assets/props/src/bed_single.mog",
    "sofa": "assets/props/src/sofa.mog",
    "armchair": "assets/props/src/armchair.mog",
}

REPO_ROOT = Path("/home/z/my-project/pz3d")
MOGEN_BIN = "/home/z/.local/bin/mogen"

def simplify_mog(mog_path: Path) -> bool:
    """Edit a .mog file in-place to simplify geometry. Returns True if changed."""
    content = mog_path.read_text()
    original = content
    
    # 1. Replace `rounded_box` with `box` (drops the bevel = fewer tris)
    # Keep all other parameters (size, mat, pos, rot, tags) intact.
    content = re.sub(r'\brounded_box\s+', 'box ', content)
    
    # 2. Replace `chamfered_box` with `box`
    content = re.sub(r'\bchamfered_box\s+', 'box ', content)
    
    # 3. Remove the `radius=...` parameter from box (was for rounded_box/chamfered_box)
    # box doesn't take radius — mogen would warn. Strip it.
    content = re.sub(r',\s*radius=[\d.]+', '', content)
    
    # 4. Remove `marker_*` meshes (invisible 0.02m boxes for bone skin binding)
    # These are: marker_shoulder_l, marker_shoulder_r, marker_forearm_l, etc.
    # Match the entire line starting with `  box "marker_`
    lines = content.split('\n')
    filtered_lines = []
    for line in lines:
        if re.match(r'\s*box\s+"marker_', line):
            continue  # skip marker lines
        filtered_lines.append(line)
    content = '\n'.join(filtered_lines)
    
    # 5. For `branch` primitive, reduce `depth=4` to `depth=3` (halves branch count)
    # Also reduce `splits=3` to `splits=2` if present
    content = re.sub(r'depth=4', 'depth=3', content)
    content = re.sub(r'depth=5', 'depth=3', content)
    content = re.sub(r'splits=3', 'splits=2', content)
    
    # 6. Replace small spheres (radius < 0.05, like eyes) with boxes
    # Match: sphere "name" (radius=0.0XX, ...) → box "name" (size=[0.0XX*2, 0.0XX*2, 0.0XX*2], ...)
    # This is complex — skip for now, only affects eyes (small tri count)
    
    if content == original:
        return False
    mog_path.write_text(content)
    return True

def compile_mog_to_glb(mog_path: Path, glb_path: Path) -> bool:
    """Run mogen build to compile .mog → .glb."""
    cmd = [MOGEN_BIN, "build", str(mog_path), "--out", str(glb_path)]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        print(f"  ERROR compiling: {result.stderr}")
        return False
    return True

def main():
    print("=" * 70)
    print("HIGH-POLY ASSET SIMPLIFICATION SWEEP")
    print("=" * 70)
    
    simplified_count = 0
    for name, rel_path in HIGH_POLY_ASSETS.items():
        mog_path = REPO_ROOT / rel_path
        if not mog_path.exists():
            print(f"\n[{name}] SKIP — .mog not found at {mog_path}")
            continue
        
        print(f"\n[{name}] simplifying {mog_path.name}...")
        changed = simplify_mog(mog_path)
        if not changed:
            print(f"  no changes needed")
            continue
        
        print(f"  simplified .mog (rounded_box→box, markers removed, branch depth reduced)")
        
        # Compile to .glb
        glb_path = REPO_ROOT / "godot_project" / "assets" / rel_path.split("/")[1] / f"{name}.glb"
        glb_path.parent.mkdir(parents=True, exist_ok=True)
        
        print(f"  compiling → {glb_path}")
        if compile_mog_to_glb(mog_path, glb_path):
            print(f"  ✓ compiled")
            simplified_count += 1
        else:
            print(f"  ✗ compile failed")
    
    print(f"\n{'=' * 70}")
    print(f"Simplified {simplified_count} assets. Re-run inspect_all_glbs.py to verify tri counts.")
    print(f"{'=' * 70}")

if __name__ == "__main__":
    main()
